//
//  FDFireflyDeviceLogger.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public class FDFireflyDeviceLogger {

    public static void error(FDFireflyDeviceLog log, String format, Object ... arguments) {
        add(log, format, arguments);
    }

    public static void warn(FDFireflyDeviceLog log, String format, Object ... arguments) {
        add(log, format, arguments);
    }

    public static void info(FDFireflyDeviceLog log, String format, Object ... arguments) {
        add(log, format, arguments);
    }

    public static void debug(FDFireflyDeviceLog log, String format, Object ... arguments) {
        add(log, format, arguments);
    }

    public static void verbose(FDFireflyDeviceLog log, String format, Object ... arguments) {
        add(log, format, arguments);
    }

    static FDFireflyDeviceLog fireflyDeviceLogger;

	public static void setLog(FDFireflyDeviceLog log) {
		fireflyDeviceLogger = log;
	}

    public static FDFireflyDeviceLog getLog() {
		return fireflyDeviceLogger;
	}

	static void add(FDFireflyDeviceLog log, String format, Object ... arguments) {
        StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
        StackTraceElement caller = stackTrace[2];
        String file = caller.getFileName();
        int line = caller.getLineNumber();
        String method = caller.getClassName() + "." + caller.getMethodName();

		String message = FDString.format(format, arguments);

		int index = file.lastIndexOf('\\');
		if (index >= 0) {
			file = file.substring(index + 1);
		}

		if (log == null) {
			log = fireflyDeviceLogger;
		}
		if (log != null) {
			log.log(file, line, method, message);
		} else {
			String s = FDString.format("%s:%lu %s %s\n", file, line, method, message);
			System.out.println(s);
		}
	}

}
