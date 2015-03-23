//
//  FDHardwareId.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/2/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public class FDHardwareId {

	public String hardwareId(byte[] unique, String prefix) {
		String hardwareId = prefix;
		for (byte b : unique) {
			hardwareId += FDString.format("%02X", b);
		}
		return hardwareId;
	}

	public String hardwareId(byte[] unique) {
		String prefix = "FireflyIce-";
		return hardwareId(unique, prefix);
	}

}