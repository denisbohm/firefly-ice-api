//
//  FDIEEE754.h
//  FireflyDevice
//
//  Created by Denis Bohm on 12/8/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDIEEE754_H
#define FDIEEE754_H

#include <cstdint>

namespace FireflyDesign {

	class FDIEEE754 {
	public:

		static uint16_t floatToUint16(float value);
		static float uint16ToFloat(uint16_t value);
	};

}

#endif