#!/bin/bash

if [ -z "$1" ]
then
    filename=`echo *.xcodeproj`
    name="${filename%.*}"
else
    name=$1
fi

configuration=Debug
framework=`echo ${name} | tr ' ' '_'`
log=derived/build.log

echo "building iOS framework ${name}..."

rm -rf derived
mkdir -p derived

xcodebuild -configuration "${configuration}" clean build -scheme "${name}" -sdk iphoneos -derivedDataPath derived >>"${log}" 2>&1
exit_code=$?
if [ $exit_code != 0 ]
then
    echo "FAILED: build iphoneos framework ${name}"
fi

xcodebuild -configuration "${configuration}" clean build -scheme "${name}" -sdk iphonesimulator -derivedDataPath derived >>"${log}" 2>&1
exit_code=$?
if [ $exit_code != 0 ]
then
    echo "FAILED: build iphonesimulator framework ${name}"
fi

cp -RL "derived/Build/Products/${configuration}-iphoneos" "derived/Build/Products/${configuration}-universal"
xcodebuild -project "${name}.xcodeproj" -list | sed -n '/Schemes/,/^$/p' | grep -v "Schemes:" > derived/schemes.txt
schemes=`sed '$ d' derived/schemes.txt`
while read name; do
echo "generating universal for ${name}"
framework=`echo ${name} | tr ' ' '_'`

if [ -d "derived/Build/Products/${configuration}-iphonesimulator/${framework}.framework/Modules/${framework}.swiftmodule" ]; then
    cp -RL "derived/Build/Products/${configuration}-iphonesimulator/${framework}.framework/Modules/${framework}.swiftmodule"/* \
           "derived/Build/Products/${configuration}-universal/${framework}.framework/Modules/${framework}.swiftmodule/"
fi
lipo -create "derived/Build/Products/${configuration}-iphoneos/${framework}.framework/${framework}" \
             "derived/Build/Products/${configuration}-iphonesimulator/${framework}.framework/${framework}" \
     -output "derived/Build/Products/${configuration}-universal/${framework}.framework/${framework}"

done <<< "${schemes}"
