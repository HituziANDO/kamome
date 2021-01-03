#!/bin/sh

# ==============================
# Set env
# ==============================
PROJECT_NAME=KamomeSDK
CONFIGURATION=Release
INFOPLIST="${PROJECT_NAME}/Resources/Info.plist"
FRAMEWORK_NAME=$(/usr/libexec/PlistBuddy -c "Print CFBundleName" ${INFOPLIST})
BUILD_TARGET_NAME=$FRAMEWORK_NAME
FRAMEWORK_BUILD_CONFIGURATION="${CONFIGURATION}"
FRAMEWORK_VERSION_NUMBER=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" ${INFOPLIST})
FRAMEWORK_VERSION=A
FRAMEWORK_BUILD_PATH="Framework"
FRAMEWORK_DIR="${FRAMEWORK_BUILD_PATH}/${FRAMEWORK_NAME}.framework"
PACKAGENAME="${FRAMEWORK_NAME}-${FRAMEWORK_VERSION_NUMBER}.zip"

# ==============================
# Build
# ==============================
xcodebuild -configuration ${FRAMEWORK_BUILD_CONFIGURATION} -target ${BUILD_TARGET_NAME} clean
xcodebuild -configuration ${FRAMEWORK_BUILD_CONFIGURATION} -target ${BUILD_TARGET_NAME} -sdk iphonesimulator
[ $? != 0 ] && exit 1
xcodebuild -configuration ${FRAMEWORK_BUILD_CONFIGURATION} -target ${BUILD_TARGET_NAME} -sdk iphoneos
[ $? != 0 ] && exit 1

# ==============================
# Make directories
# ==============================
[ -d "${FRAMEWORK_BUILD_PATH}" ] && rm -rf "${FRAMEWORK_BUILD_PATH}"
mkdir -p ${FRAMEWORK_DIR}
mkdir -p ${FRAMEWORK_DIR}/Headers
mkdir -p ${FRAMEWORK_DIR}/Resources

#mkdir -p ${FRAMEWORK_DIR}/Versions
#mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}
#mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}/Resources
#mkdir -p ${FRAMEWORK_DIR}/Versions/${FRAMEWORK_VERSION}/Headers
#ln -s ${FRAMEWORK_VERSION} ${FRAMEWORK_DIR}/Versions/Current
#ln -s Versions/Current/Headers ${FRAMEWORK_DIR}/Headers
#ln -s Versions/Current/Resources ${FRAMEWORK_DIR}/Resources
#ln -s Versions/Current/${FRAMEWORK_NAME} ${FRAMEWORK_DIR}/${FRAMEWORK_NAME}

# ==============================
# Make framework
# ==============================
lipo -create \
build/${FRAMEWORK_BUILD_CONFIGURATION}-iphoneos/lib${FRAMEWORK_NAME}.a \
build/${FRAMEWORK_BUILD_CONFIGURATION}-iphonesimulator/lib${FRAMEWORK_NAME}.a \
-o "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
#-o "${FRAMEWORK_DIR}/Versions/Current/${FRAMEWORK_NAME}"

cp -Rf "${PROJECT_NAME}/Headers/" ${FRAMEWORK_DIR}/Headers/
cp "${PROJECT_NAME}/Resources/" ${FRAMEWORK_DIR}/Resources/
cp ${INFOPLIST} ${FRAMEWORK_DIR}/Resources/
cp -Rf "${PROJECT_NAME}/Modules/" ${FRAMEWORK_DIR}/Modules/
cd ${FRAMEWORK_BUILD_PATH}
chmod -fR 755 "${FRAMEWORK_NAME}.framework"
zip -ry ${PACKAGENAME} $(basename $FRAMEWORK_DIR)
cd ${SRCROOT}

