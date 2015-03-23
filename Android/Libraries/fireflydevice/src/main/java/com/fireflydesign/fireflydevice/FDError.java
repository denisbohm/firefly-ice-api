//
//  FDError.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/25/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.HashMap;
import java.util.Map;

public class FDError {

    public static final String FDLocalizedDescriptionKey = "description";
    public static final String FDLocalizedRecoveryOptionsErrorKey = "recoveryOptionsError";

    public static FDError error(String domain, int code, Map<String, String> userInfo) {
		FDError error = new FDError();
		error.domain = domain;
		error.code = code;
		error.userInfo = userInfo;
		return error;
	}

    public static FDError error(String domain, int code, String description) {
		Map<String, String> userInfo = new HashMap<String, String>();
		userInfo.put(FDLocalizedDescriptionKey, description);
		return FDError.error(domain, code, userInfo);
	}

	public String description() {
		String s = userInfo.get(FDLocalizedDescriptionKey);
		return FDString.format("%s %u %s", domain, code, s);
	}

    public String domain;
    public int code;
    public Map<String, String> userInfo;

}
