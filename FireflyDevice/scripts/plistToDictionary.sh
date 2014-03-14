#!/bin/sh
#
#  plistToDictionary.sh
#  FireflyDevice
#
#  Created by Denis Bohm on 2/14/14.
#  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
#

if [ -z "$PROJECT_NAME" ]
then
    PROJECT_NAME=`ls -d *.xcodeproj | sed -e 's/\(.*\)\.xcodeproj/\1/'`
fi

PREFIX=`grep CLASSPREFIX ${PROJECT_NAME}.xcodeproj/project.pbxproj | sed -e 's/.* = \(.*\);/\1/'`
TARGET=${PROJECT_NAME}/${PREFIX}Bundle.m
PLIST=${PROJECT_NAME}/${PROJECT_NAME}-Info.plist
KEYS="CFBundleShortVersionString CFBundleVersion NSHumanReadableCopyright"
NOW=`date`

echo "//
//  ${PREFIX}Bundle.m
//  ${PROJECT_NAME}
//
//  Created by $0
//

#import \"${PREFIX}Bundle.h\"
#import <FireflyDevice/FDBundleManager.h>

@implementation ${PREFIX}Bundle

+ (void)load
{
    [FDBundleManager addLibraryBundle:[[${PREFIX}Bundle alloc] init]];
}

- (NSDictionary *)infoDictionary
{
    return @{
        @\"CFBundleName\": @\"${PROJECT_NAME}\"," > ${TARGET}

for KEY in ${KEYS}
do
  VALUE=`/usr/libexec/PlistBuddy -c "Print ${KEY}" ${PLIST}`
  echo "        @\"${KEY}\": @\"${VALUE}\"," >> ${TARGET}
done

echo "    };
}

@end" >> ${TARGET}
