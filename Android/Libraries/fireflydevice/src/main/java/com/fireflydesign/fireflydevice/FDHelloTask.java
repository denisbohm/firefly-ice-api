//
//  FDHelloTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 10/6/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.HashMap;
import java.util.Map;

public class FDHelloTask extends FDFireflyIceTaskSteps {

    public final static String FDHelloTaskErrorDomain = "com.fireflydesign.device.FDHelloTask";

    public enum ErrorCode {
        Incomplete
    }

    public interface Delegate {
        double helloTaskDate();
        void helloTaskSuccess(FDHelloTask helloTask);
        void helloTaskError(FDHelloTask helloTask, FDError error);
    }

    public Delegate delegate;
    public FDFireflyIceVersion version;
    public FDFireflyIceVersion bootVersion;
    public FDFireflyIceHardwareId hardwareId;
    public double time;
    public FDFireflyIcePower power;
    public FDFireflyIceReset reset;

    double maxOffset;

    public FDHelloTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, Delegate delegate) {
        super(fireflyIce, channel);
		this.delegate = delegate;
		priority = 100;
		maxOffset = 120;
		time = 0;
	}

	public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version) {
		this.version = version;
	}

    public void fireflyIceHardwareId(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceHardwareId hardwareId) {
		this.hardwareId = hardwareId;
	}

    public void fireflyIceBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion bootVersion) {
		this.bootVersion = bootVersion;
	}

    public void fireflyIceTime(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, double time) {
		this.time = time;
	}

    public void fireflyIcePower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIcePower power) {
		this.power = power;
	}

    public void fireflyIceReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceReset reset) {
		this.reset = reset;
	}

    public void executorTaskStarted(FDExecutor executor) {
		super.executorTaskStarted(executor);

		fireflyIce.coder.sendGetProperties(
            channel,
			FDFireflyIceCoder.FD_CONTROL_PROPERTY_VERSION |
            FDFireflyIceCoder.FD_CONTROL_PROPERTY_HARDWARE_ID |
            FDFireflyIceCoder.FD_CONTROL_PROPERTY_RTC |
            FDFireflyIceCoder.FD_CONTROL_PROPERTY_POWER |
            FDFireflyIceCoder.FD_CONTROL_PROPERTY_RESET |
            FDFireflyIceCoder.FD_CONTROL_PROPERTY_BOOT_VERSION
		);
		next("checkVersion");
	}

    public void executorTaskCompleted(FDExecutor executor) {
        super.executorTaskCompleted(executor);
        if (delegate != null) {
            delegate.helloTaskSuccess(this);
        }
    }

    public void executorTaskFailed(FDExecutor executor, FDError error) {
        super.executorTaskFailed(executor, error);
        if (delegate != null) {
            delegate.helloTaskError(this, error);
        }
    }

    void checkVersion() {
		if ((version == null) || (hardwareId == null)) {
			String description = "Incomplete information received on initial communication with the device";
			FDFireflyDeviceLogger.info(log, "FD010501", description);
			channel.close();
			Map<String, String> userInfo = new HashMap<String, String>();
			userInfo.put(FDError.FDLocalizedDescriptionKey, description);
			userInfo.put(FDError.FDLocalizedRecoveryOptionsErrorKey, "Make sure the device stays in close range");
			FDError error = FDError.error(FDHelloTaskErrorDomain, ErrorCode.Incomplete.ordinal(), userInfo);
			fireflyIce.executor.fail(this, error);
			return;
		}

		fireflyIce.version = version;
		fireflyIce.bootVersion = bootVersion;
		fireflyIce.hardwareId = hardwareId;

		if ((fireflyIce.version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_BOOT_VERSION) != 0) {
			fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_BOOT_VERSION);
			next("checkTime");
		} else {
			checkTime();
		}
	}

	void setTime() {
		double time = (delegate != null) ? delegate.helloTaskDate() : FDTime.time();
		if (time != 0) {
			FDFireflyDeviceLogger.info(log, "FD010502", "setting the time");
			fireflyIce.coder.sendSetPropertyTime(channel, time);
		}
	}

	void checkTime() {
		String hardwareIdDescription = fireflyIce.hardwareId.description();
		String versionDescription = fireflyIce.version.description();
		String resetDescription = reset.description();
		FDFireflyDeviceLogger.info(log, "FD010503", "hello (hardware %s) (firmware %s)", hardwareIdDescription, versionDescription);

		if (time == 0) {
			FDFireflyDeviceLogger.info(log, "FD010504", "time not set for hw %s fw %s (last reset %s)", hardwareIdDescription, versionDescription, resetDescription);
			setTime();
		} else {
			double time = (delegate != null) ? delegate.helloTaskDate() : FDTime.time();
			if (time != 0) {
				double offset = time - this.time;
				if (Math.abs(offset) > maxOffset) {
					FDFireflyDeviceLogger.info(log, "FD010505", "time is off by %.3f seconds for hw %s fw %s (last reset %s)", offset, hardwareIdDescription, versionDescription, resetDescription);
					setTime();
				} else {
					FDFireflyDeviceLogger.info(log, "FD010506", "time is off by %.3f seconds for hw %s fw %s", offset, hardwareIdDescription, versionDescription);
				}
			}
		}
		done();
	}

}
