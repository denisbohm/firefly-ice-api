#!/bin/bash

if [ -z "$1" ]
then
    filename=`echo *.xcodeproj`
    name="${filename%.*}"
else
    name=$1
fi

framework=`echo ${name} | tr ' ' '_'`
log=build/build.log

echo "building iOS framework ${name}..."

mkdir -p build

xcodebuild -configuration Release clean build -scheme "${name}" -sdk iphoneos SYMROOT=build >>"${log}" 2>&1
exit_code=$?
if [ $exit_code != 0 ]
then
    echo "FAILED: build iphoneos framework ${name}"
fi

xcodebuild -configuration Release clean build -scheme "${name}" -sdk iphonesimulator SYMROOT=build >>"${log}" 2>&1
exit_code=$?
if [ $exit_code != 0 ]
then
    echo "FAILED: build iphonesimulator framework ${name}"
fi

cp -RL "build/Release-iphoneos" "build/Release-universal"
if [ -f "build/Release-iphonesimulator/${framework}.framework/Modules/${framework}.swiftmodule" ]; then
    echo "exists"
    cp -RL "build/Release-iphonesimulator/${framework}.framework/Modules/${framework}.swiftmodule"/* \
           "build/Release-universal/${framework}.framework/Modules/${framework}.swiftmodule/"
fi
lipo -create "build/Release-iphoneos/${framework}.framework/${framework}" \
             "build/Release-iphonesimulator/${framework}.framework/${framework}" \
     -output "build/Release-universal/${framework}.framework/${framework}"
