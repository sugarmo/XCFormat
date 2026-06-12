#!/bin/bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "usage: codesign-build.sh <binary-name>" >&2
    exit 64
fi

resources_folder="${UNLOCALIZED_RESOURCES_FOLDER_PATH:-}"
if [[ -z "${resources_folder}" ]]; then
    resources_folder="${CONTENTS_FOLDER_PATH:?}/Resources"
fi

binary_path="${TARGET_BUILD_DIR}/${resources_folder}/$1"
export CODESIGN_ENTITLEMENTS="${SRCROOT}/SourceExtension/Binary.entitlements"

"${SRCROOT}/Scripts/codesign.sh" "${binary_path}"
