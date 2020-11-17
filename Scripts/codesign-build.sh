#!/bin/bash

# code sign for app store
codesign --force --sign "591548EB20102F64693DFAC199D6B599389D5D3B" --entitlements "${SRCROOT}/SourceExtension/Binary.entitlements" "${TARGET_BUILD_DIR}/$1"
echo "Signing $1"
