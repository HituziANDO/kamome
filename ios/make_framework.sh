#!/bin/sh

######################
# Options
######################

FRAMEWORK_NAME="kamome"
BUILD_PATH="build"
CONFIGURATION="Release"
SIMULATOR_LIBRARY_PATH="${BUILD_PATH}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}.framework"
DEVICE_LIBRARY_PATH="${BUILD_PATH}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}.framework"
UNIVERSAL_LIBRARY_DIR="${BUILD_PATH}/${CONFIGURATION}-iphoneuniversal"
FRAMEWORK="${UNIVERSAL_LIBRARY_DIR}/${FRAMEWORK_NAME}.framework"
INFOPLIST="SwiftyKamome/Info.plist"
FRAMEWORK_VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${INFOPLIST})
PACKAGENAME="${FRAMEWORK_NAME}-${FRAMEWORK_VERSION_NUMBER}.zip"


######################
# Build Frameworks
######################

xcodebuild -configuration ${CONFIGURATION} -target ${FRAMEWORK_NAME} clean
xcodebuild -configuration ${CONFIGURATION} -target ${FRAMEWORK_NAME} -sdk iphonesimulator
[ $? != 0 ] && exit 1
xcodebuild -configuration ${CONFIGURATION} -target ${FRAMEWORK_NAME} -sdk iphoneos
[ $? != 0 ] && exit 1


######################
# Create directory for universal
######################

rm -rf "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${UNIVERSAL_LIBRARY_DIR}"

mkdir "${FRAMEWORK}"


######################
# Copy files Framework
######################

cp -r "${DEVICE_LIBRARY_PATH}/." "${FRAMEWORK}"


######################
# Make an universal binary
######################

lipo "${SIMULATOR_LIBRARY_PATH}/${FRAMEWORK_NAME}" "${DEVICE_LIBRARY_PATH}/${FRAMEWORK_NAME}" -create -output "${FRAMEWORK}/${FRAMEWORK_NAME}" | echo

# For Swift framework, Swiftmodule needs to be copied in the universal framework
if [ -d "${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f ${SIMULATOR_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi

if [ -d "${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/" ]; then
cp -f ${DEVICE_LIBRARY_PATH}/Modules/${FRAMEWORK_NAME}.swiftmodule/* "${FRAMEWORK}/Modules/${FRAMEWORK_NAME}.swiftmodule/" | echo
fi

######################
# On Release, copy the result to release directory
######################
OUTPUT_DIR="Framework/"

rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

cp -r "${FRAMEWORK}" "$OUTPUT_DIR"

