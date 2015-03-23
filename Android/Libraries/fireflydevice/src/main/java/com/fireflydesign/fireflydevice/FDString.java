//
//  FDString.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.text.SimpleDateFormat;
import java.util.GregorianCalendar;

public class FDString {

    public static String format(String fmt, Object ... arguments) {
        return fmt;
    }

    public static String formatDateTime(double time) {
		// "yyyy-MM-dd HH:mm:ss.SSS"
        GregorianCalendar calendar = new GregorianCalendar();
        calendar.setTimeInMillis((long) (time * 1000.0));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
        return formatter.format(calendar.getTime());
	}

}