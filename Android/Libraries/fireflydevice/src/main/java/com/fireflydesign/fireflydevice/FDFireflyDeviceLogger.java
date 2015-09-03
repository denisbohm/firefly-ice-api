//
//  FDFireflyDeviceLogger.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/21/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import android.util.Log;

public class FDFireflyDeviceLogger {

    public enum Level {
        Error, Warn, Info, Debug, Verbose
    }

    public static Level level = Level.Info;

    public static void error(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        if (level.ordinal() >= Level.Error.ordinal()) {
            add(log, key, format, arguments);
        }
    }

    public static void warn(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        if (level.ordinal() >= Level.Warn.ordinal()) {
            add(log, key, format, arguments);
        }
    }

    public static void info(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        if (level.ordinal() >= Level.Info.ordinal()) {
            add(log, key, format, arguments);
        }
    }

    public static void debug(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        if (level.ordinal() >= Level.Debug.ordinal()) {
            add(log, key, format, arguments);
        }
    }

    public static void verbose(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        if (level.ordinal() >= Level.Verbose.ordinal()) {
            add(log, key, format, arguments);
        }
    }

    static FDFireflyDeviceLog fireflyDeviceLogger;

	public static void setLog(FDFireflyDeviceLog log) {
		fireflyDeviceLogger = log;
	}

    public static FDFireflyDeviceLog getLog() {
		return fireflyDeviceLogger;
	}

	static void add(FDFireflyDeviceLog log, String key, String format, Object ... arguments) {
        Thread thread = Thread.currentThread();
        StackTraceElement[] stackTrace = thread.getStackTrace();
        StackTraceElement caller = stackTrace[4];
        String file = caller.getFileName();
        int line = caller.getLineNumber();
        String method = /* caller.getClassName() + "." + */ caller.getMethodName();

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
            String s = FDString.format("%s %s:%d %s %s %s\n", thread.getName(), file, line, method, key, message);
            Log.i("Logger", s);
		}
	}

}
