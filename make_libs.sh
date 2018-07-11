#!/bin/sh

LIBS_DIR=libs

if [ -e $LIBS_DIR ]; then
    rm -rf $LIBS_DIR
fi

mkdir $LIBS_DIR

# Make JavaScript

cd ./js

if [ -e ./src/kamome.min.js ]; then
    rm ./src/kamome.min.js
fi

gulp build
cp ./src/kamome.min.js ../$LIBS_DIR/
cd ../

# Make Android

cd ./android
./gradlew makeJar
cp ./kamome/release/*.jar ../$LIBS_DIR/
cd ../

# Make iOS

cd ./ios/KamomeSDK
./make_framework.sh
cp -rf ./Framework/*.framework ../../$LIBS_DIR/
cd ../../

