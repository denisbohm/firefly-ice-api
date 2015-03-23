//
//  FDTime.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.GregorianCalendar;

public class FDTime {

    public static double time() {
        return (new GregorianCalendar()).getTimeInMillis() / 1000.0;
    }

}