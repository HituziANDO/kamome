#!/bin/sh

OUTPUT_DIR=output
LIBS_DIR=$OUTPUT_DIR/kamome

if [ -e $OUTPUT_DIR ]; then
    rm -rf $OUTPUT_DIR
fi

mkdir -p $LIBS_DIR
mkdir $LIBS_DIR/js
mkdir $LIBS_DIR/android
mkdir $LIBS_DIR/ios

# Make JavaScript

cd ./js/kamome

npm run build
cp -r ./dist/* ../../$LIBS_DIR/js/
cd ../../

# Make Android

cd ./android

if [ -e ./kamome/release ]; then
    rm -rf ./kamome/release
fi

./gradlew makeJar
cp ./kamome/release/*.jar ../$LIBS_DIR/android
cd ../

# Make iOS

cd ./ios
./make_framework.sh
cp -rf ./Output/Release-xcframework/*.xcframework ../$LIBS_DIR/ios
cd ../
