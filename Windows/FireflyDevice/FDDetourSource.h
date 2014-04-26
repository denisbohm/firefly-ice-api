//
//  FDDetourSource.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDDETOURSOURCE_H
#define FDDETOURSOURCE_H

#include "FDCommon.h"

#include <memory>
#include <vector>

namespace FireflyDesign {

	class FDDetourSource {
	public:
		typedef unsigned size_type;

		FDDetourSource(size_type size, std::vector<uint8_t> data);

		std::vector<uint8_t> next();

	private:
		size_type size;
		std::vector<uint8_t> data;
		size_type index;
		uint8_t sequenceNumber;
	};

}

#endif