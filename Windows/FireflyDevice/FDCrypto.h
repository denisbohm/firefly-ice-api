//
//  FDCrypto.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/15/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDCRYPTO_H
#define FDCRYPTO_H

#include <cstdint>
#include <vector>

namespace fireflydesign {

	class FDCrypto {
	public:
		static std::vector<uint8_t> sha1(std::vector<uint8_t> data);

		// AES-128 hash (result is last 20 bytes of encoding the data)
		static std::vector<uint8_t> hash(std::vector<uint8_t> key, std::vector<uint8_t> iv, std::vector<uint8_t> data);
		static std::vector<uint8_t> hash(std::vector<uint8_t> data);
	};

}

#endif