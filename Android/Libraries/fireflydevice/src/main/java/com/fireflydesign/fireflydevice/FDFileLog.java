//
//  FDFileLog.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 12/23/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.PrintStream;

import java.util.Date;
import java.util.Scanner;

public class FDFileLog {

    public int logLimit;

    String logDirectory;
    String logFileName;
    String logFileNameOld;
    PrintStream logFile;

    public FDFileLog(String logDirectory) {
		logLimit = 100000;
		this.logDirectory = logDirectory;
		logFileName = logDirectory + "/log.txt";
		logFileNameOld = logDirectory + "/log-1.txt";
	}

	public String getContent() {
		StringBuffer buffer = new StringBuffer();
		getContent(buffer);
		return buffer.toString();
	}

	public synchronized void getContent(StringBuffer buffer) {
		close();

		appendFile(buffer, logFileNameOld);
		appendFile(buffer, logFileName);
	}

	static void appendFile(StringBuffer buffer, String fileName) {
        try {
            buffer.append(new Scanner(new File(fileName)).useDelimiter("\\Z").next());
        } catch (FileNotFoundException e) {
            System.out.println("can't open file: " + fileName);
        }
	}

	void close() {
		logFile.close();
        logFile = null;
	}

	synchronized void log(String message) {
		if (logFile == null) {
            try {
                logFile = new PrintStream(new FileOutputStream(logFileName, true));
			} catch (FileNotFoundException e) {
                System.out.println("can't open log file: " + logFileName);
            }
		}
		if (logFile != null) {
			String date = FDString.formatDateTime(new Date().getTime());
            logFile.println(date + " " + message);
			logFile.flush();
			long length = new File(logFileName).length();
			if (length > logLimit) {
				close();
				new File(logFileNameOld).delete();
				new File(logFileName).renameTo(new File(logFileNameOld));
			}
		}
	}

	String lastPathComponent(String path) {
		int index = path.lastIndexOf('/');
		if (index >= 0) {
			return path.substring(index + 1);
		}
		return path;
	}

	public void log(String file, int line, String cls, String method, String message) {
		String fullMessage = lastPathComponent(file) + ":" + Integer.toString(line) + " " + cls + "." + method + " " + message;

		System.out.println(fullMessage);
		log(fullMessage);
	}

}
