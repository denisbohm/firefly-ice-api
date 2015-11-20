//
//  FDString.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/27/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.nio.ByteBuffer;
import java.text.SimpleDateFormat;
import java.util.GregorianCalendar;

public class FDString {

    public static String format(String fmt, Object ... arguments) {
        if (arguments.length == 0) {
            return fmt;
        }
        try {
            return String.format(fmt, arguments);
        } catch (Exception e) {
            return fmt;
        }
    }

    public static String formatDateTime(double time) {
		// "yyyy-MM-dd HH:mm:ss.SSS"
        GregorianCalendar calendar = new GregorianCalendar();
        calendar.setTimeInMillis((long) (time * 1000.0));
        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
        return formatter.format(calendar.getTime());
	}

    static int parseInt(String string) {
        if (string.startsWith("0x") || string.startsWith("0X")) {
            return Integer.parseInt(string.substring(2), 16);
        }
        return Integer.parseInt(string);
    }

    // For example: 5f8e87b7ecf9558d8704e3af7177388098387368
    static byte[] parseBytes(String string) {
        int byteCount = string.length() / 2;
        ByteBuffer buffer = ByteBuffer.allocate(byteCount);
        for (int i = 0; i < string.length(); i += 2) {
            String substring = string.substring(i, i + 2);
            byte b = (byte)Integer.parseInt(substring, 16);
            buffer.put(b);
        }
        return buffer.array();
    }

}