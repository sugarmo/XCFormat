#!/bin/bash

# code sign for app store
codesign --force --sign "6BBBF54EBDD6BE0CF88F0BBB54C82A727CAE2441" --entitlements "${SRCROOT}/SourceExtension/Binary.entitlements" "${TARGET_BUILD_DIR}/$1"
echo "Signing $1"
