#!/bin/bash

set -euo pipefail

if [[ -z "${SRCROOT:-}" || -z "${TARGET_TEMP_DIR:-}" || -z "${TARGET_BUILD_DIR:-}" ]]; then
    echo "error: this script must run from an Xcode build phase" >&2
    exit 64
fi

resources_folder="${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}"
if [[ -z "${resources_folder}" ]]; then
    resources_folder="${CONTENTS_FOLDER_PATH:?}/Resources"
fi

resources_path="${TARGET_BUILD_DIR}/${resources_folder}"
mkdir -p "${resources_path}"

# Keep the submodule Xcode projects out of the parent project; build the CLI
# tools through their source-level build systems and copy the final binaries.
case "${CONFIGURATION:-Debug}" in
    Release)
        swift_configuration="release"
        cmake_configuration="Release"
        ;;
    *)
        swift_configuration="debug"
        cmake_configuration="Debug"
        ;;
esac

build_archs=()
if [[ "${ONLY_ACTIVE_ARCH:-NO}" == "YES" ]]; then
    active_arch="${CURRENT_ARCH:-}"
    if [[ "${active_arch}" != "arm64" && "${active_arch}" != "x86_64" ]]; then
        active_arch="${NATIVE_ARCH_ACTUAL:-$(uname -m)}"
    fi
    build_archs=("${active_arch}")
else
    for arch in ${ARCHS:-}; do
        case "${arch}" in
            arm64|x86_64)
                build_archs+=("${arch}")
                ;;
        esac
    done

    if [[ ${#build_archs[@]} -eq 0 ]]; then
        build_archs=("$(uname -m)")
    fi
fi

deployment_target="${MACOSX_DEPLOYMENT_TARGET:-10.15}"

copy_executable() {
    local source_path="$1"
    local destination_path="$2"

    if [[ ! -f "${source_path}" ]]; then
        echo "error: executable not found at ${source_path}" >&2
        exit 66
    fi

    install -m 755 "${source_path}" "${destination_path}"
    echo "Copied $(basename "${destination_path}")"
}

build_swiftformat() {
    local package_path="${SRCROOT}/Externals/SwiftFormat"
    local output_path="${resources_path}/swiftformat"
    local built_binaries=()

    for arch in "${build_archs[@]}"; do
        local scratch_path="${TARGET_TEMP_DIR}/SwiftFormat-${arch}.build"
        local triple="${arch}-apple-macosx${deployment_target}"
        local swift_build_args=(
            build
            --package-path "${package_path}"
            --scratch-path "${scratch_path}"
            --configuration "${swift_configuration}"
            --product swiftformat
            --triple "${triple}"
        )

        swift "${swift_build_args[@]}"

        local bin_path
        bin_path="$(swift "${swift_build_args[@]}" --show-bin-path)"
        built_binaries+=("${bin_path}/swiftformat")
    done

    if [[ ${#built_binaries[@]} -eq 1 ]]; then
        copy_executable "${built_binaries[0]}" "${output_path}"
    else
        lipo -create "${built_binaries[@]}" -output "${output_path}"
        chmod 755 "${output_path}"
        echo "Copied swiftformat"
    fi
}

find_uncrustify_binary() {
    local build_path="$1"
    local candidate
    local candidates=(
        "${build_path}/${cmake_configuration}/uncrustify"
        "${build_path}/uncrustify"
        "${build_path}/src/uncrustify"
        "${build_path}/bin/uncrustify"
    )

    for candidate in "${candidates[@]}"; do
        if [[ -f "${candidate}" ]]; then
            echo "${candidate}"
            return 0
        fi
    done

    find "${build_path}" -type f -name uncrustify -perm -111 -print -quit
}

build_uncrustify() {
    local source_path="${SRCROOT}/Externals/uncrustify"
    local build_path="${TARGET_TEMP_DIR}/uncrustify.build"
    local output_path="${resources_path}/uncrustify"
    local cmake_archs
    cmake_archs="$(IFS=';'; echo "${build_archs[*]}")"

    local cmake_args=(
        -S "${source_path}"
        -B "${build_path}"
        "-DCMAKE_BUILD_TYPE=${cmake_configuration}"
        "-DCMAKE_OSX_ARCHITECTURES=${cmake_archs}"
    )

    if [[ -n "${MACOSX_DEPLOYMENT_TARGET:-}" ]]; then
        cmake_args+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")
    fi

    cmake "${cmake_args[@]}"
    cmake --build "${build_path}" --config "${cmake_configuration}" --target uncrustify

    local binary_path
    binary_path="$(find_uncrustify_binary "${build_path}")"
    copy_executable "${binary_path}" "${output_path}"
}

build_swiftformat
build_uncrustify
