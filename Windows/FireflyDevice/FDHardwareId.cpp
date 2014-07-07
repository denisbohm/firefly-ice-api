//
//  FDHardwareId.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/2/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDHardwareId.h"
#include "FDString.h"

namespace FireflyDesign {

	std::string FDHardwareId::hardwareId(std::vector<uint8_t> unique, std::string prefix)
	{
		std::string hardwareId = prefix;
		for (uint8_t byte : unique) {
			hardwareId += FDString::format("%02X", byte);
		}
		return hardwareId;
	}

	std::string FDHardwareId::hardwareId(std::vector<uint8_t> unique)
	{
		std::string prefix = "FireflyIce-";
		return hardwareId(unique, prefix);
	}

}