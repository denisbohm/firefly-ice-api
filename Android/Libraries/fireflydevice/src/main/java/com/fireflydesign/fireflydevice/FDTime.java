//
//  FDTime.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public class FDTime {

    public static double time() {
        return System.currentTimeMillis() / 1000.0;
    }

}