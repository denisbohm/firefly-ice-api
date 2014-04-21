//
//  FDResource.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDRESOURCE_H
#define FDRESOURCE_H

#include <string>

namespace FireflyDesign {

	class FDResource {
	public:
		static std::string stringWithContentsOfResource(std::string resource);
	};

}

#endif