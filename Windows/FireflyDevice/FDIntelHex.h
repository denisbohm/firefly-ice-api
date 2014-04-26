//
//  FDIntelHex.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDINTELHEX_H
#define FDINTELHEX_H

#include "FDCommon.h"

#include <map>
#include <memory>
#include <vector>

namespace FireflyDesign {

	class FDIntelHex {
	public:
		static std::shared_ptr<FDIntelHex> intelHex(std::string hex, uint32_t address, uint32_t length);
		static std::vector<uint8_t> parse(std::string hex, uint32_t address, uint32_t length);

		std::vector<uint8_t> data;
		std::map<std::string, std::string> properties;

	private:
		void read(std::string content, uint32_t address, uint32_t length);
	};

}

#endif