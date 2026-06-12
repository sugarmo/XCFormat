#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: codesign.sh <binary-path>" >&2
    exit 64
fi

if [[ "${CODE_SIGNING_ALLOWED:-YES}" != "YES" ]]; then
    echo "Skipping code signing because CODE_SIGNING_ALLOWED is not YES"
    exit 0
fi

binary_path="$1"
script_dir="$(cd "$(dirname "$0")" && pwd)"
entitlements="${CODESIGN_ENTITLEMENTS:-${script_dir}/../SourceExtension/Binary.entitlements}"
identity="${EXPANDED_CODE_SIGN_IDENTITY:-${CODESIGN_IDENTITY:-${CODE_SIGN_IDENTITY:-}}}"

if [[ ! -f "${binary_path}" ]]; then
    echo "error: binary not found at ${binary_path}" >&2
    exit 66
fi

if [[ -z "${identity}" || "${identity}" == "-" ]]; then
    if [[ "${AD_HOC_CODE_SIGNING_ALLOWED:-NO}" == "YES" ]]; then
        identity="-"
    else
        echo "error: no code signing identity is available for ${binary_path}" >&2
        exit 65
    fi
fi

codesign_args=(--force --sign "${identity}" --entitlements "${entitlements}" --timestamp=none)

if [[ "${ENABLE_HARDENED_RUNTIME:-NO}" == "YES" ]]; then
    codesign_args+=(--options runtime)
fi

codesign "${codesign_args[@]}" "${binary_path}"
codesign --verify --strict --verbose=2 "${binary_path}"
echo "Signed $(basename "${binary_path}")"
