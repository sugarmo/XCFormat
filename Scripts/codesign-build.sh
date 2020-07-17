#!/bin/bash

# code sign for app store
codesign --force --sign "2EE848DECC76C9BC932AF20B77F30AB9B68BDD8A" --entitlements "${SRCROOT}/SourceExtension/Binary.entitlements" "${TARGET_BUILD_DIR}/$1"
echo "Signing $1"
