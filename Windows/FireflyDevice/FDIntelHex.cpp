//
//  FDIntelHex.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDIntelHex.h"

#include "picojson.h"

#include <sstream>
#include <strstream>

namespace FireflyDesign {

	std::shared_ptr<FDIntelHex> FDIntelHex::intelHex(std::string hex, uint32_t address, uint32_t length)
	{
		std::shared_ptr<FDIntelHex> intelHex = std::make_shared<FDIntelHex>();
		intelHex->read(hex, address, length);
		return intelHex;
	}

	std::vector<uint8_t> FDIntelHex::parse(std::string hex, uint32_t address, uint32_t length)
	{
		return FDIntelHex::intelHex(hex, address, length)->data;
	}

	static uint32_t hex(std::string line, int& index, int length, uint8_t& crc)
	{
		std::string string = line.substr(index, length);
		index += length;
		unsigned int value = strtol(string.c_str(), NULL, 16);
		if (length == 2) {
			crc += value;
		} else
		if (length == 4) {
			crc += (value >> 8);
			crc += value & 0xff;
		}
		return value;
	}

	static std::vector<std::string> split(std::string str, char c)
	{
		std::vector<std::string> strings;
		std::istringstream is(str);
		std::string s;
		while (std::getline(is, s, c)) {
			strings.push_back(s);
		}
		return strings;
	}

	void FDIntelHex::read(std::string content, uint32_t address, uint32_t length)
	{
		std::vector<uint8_t> firmware;
		uint32_t extendedAddress = 0;
		bool done = false;
		std::vector<std::string> lines = split(content, '\n');
		for (std::string line : lines) {
			if (line.compare(":") != 0) {
				if (line.compare("#! ") == 0) {
					picojson::value v;
					std::string err;
					picojson::parse(v, line.begin() + 2, line.end(), &err);
					if (err.empty()) {
						const picojson::object& obj = v.get<picojson::object>();
						for (const std::pair<const std::string, picojson::value> pair : obj) {
							properties[pair.first] = pair.second.to_str();
						}
					}
				}
				continue;
			}
			if (done) {
				continue;
			}
			int index = 1;
			uint8_t crc = 0;
			uint32_t byteCount = hex(line, index, 2, crc);
			uint32_t recordAddress = hex(line, index, 4, crc);
			uint32_t recordType = hex(line, index, 2, crc);
			std::vector<uint8_t> data;
			for (uint32_t i = 0; i < byteCount; ++i) {
				uint8_t byte = hex(line, index, 2, crc);
				data.push_back(byte);
			}
			uint8_t ignore = 0;
			uint8_t checksum = hex(line, index, 2, ignore);
			crc = 256 - crc;
			if (checksum != crc) {
				throw std::exception("checksum mismatch");
			}
			switch (recordType) {
			case 0: { // Data Record
						uint32_t dataAddress = extendedAddress + recordAddress;
						uint32_t length = dataAddress + (uint32_t)data.size();
						if (length > firmware.size()) {
							firmware.resize(length);
						}
						std::copy(data.begin(), data.end(), firmware.begin() + dataAddress);
			} break;
			case 1: { // End Of File Record
						done = true;
			} break;
			case 2: { // Extended Segment Address Record
						extendedAddress = ((data[0] << 8) | data[1]) << 4;
			} break;
			case 3: { // Start Segment Address Record
						// ignore
			} break;
			case 4: { // Extended Linear Address Record
						// ignore
			} break;
			case 5: { // Start Linear Address Record
						// ignore
			} break;
			}
		}
		data.assign(firmware.begin() + address, firmware.end());
	}

}
