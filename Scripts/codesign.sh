#!/bin/bash

# code sign for app store

codesign --force --sign 444C6C6C91A8968EA2A83BC7AAA507B86F4C1F1A --entitlements ../SourceExtension/Binary.entitlements $1