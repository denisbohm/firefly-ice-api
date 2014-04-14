//
//  FDDetourSource.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDDetourSource.h"

namespace fireflydesign {

	FDDetourSource::FDDetourSource(size_type size, std::vector<uint8_t> bytes)
	{
			this->size = size;
			size_type length = bytes.size();
			data.insert(data.end(), uint8_t(length));
			data.insert(data.end(), uint8_t(length >> 8));
			data.insert(data.end(), bytes.begin(), bytes.end());
	}

	std::vector<uint8_t> FDDetourSource::next()
	{
		if (index >= data.size()) {
			return std::vector<uint8_t>();
		}

		size_type n = data.size() - index;
		if (n > (size - 1)) {
			n = size - 1;
		}
		std::vector<uint8_t> subdata;
		subdata.insert(subdata.end(), sequenceNumber);
		subdata.insert(subdata.end(), data.begin() + index, data.begin() + index + n);
		index += n;
		++sequenceNumber;
		return subdata;
	}

}
