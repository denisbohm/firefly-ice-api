//
//  FDHardwareId.h
//  FireflyDevice
//
//  Created by Denis Bohm on 3/2/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDHARDWAREID_H
#define FDHARDWAREID_H

#include "FDCommon.h"

#include <cstdint>
#include <vector>

namespace FireflyDesign {

	class FDHardwareId {
	public:
		static std::string hardwareId(std::vector<uint8_t> unique, std::string prefix);
		static std::string hardwareId(std::vector<uint8_t> unique);
	};

}

#endif