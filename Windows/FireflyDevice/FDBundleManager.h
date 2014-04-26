//
//  FDBundleManager.h
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDBUNDLEMANAGER_H
#define FDBUNDLEMANAGER_H

#include "FDCommon.h"

#include "FDBundle.h"

#include <memory>
#include <vector>

namespace FireflyDesign {

	class FDBundleManager {
	public:
		static void addLibraryBundle(std::shared_ptr<FDBundleInfo> bundle);

		static std::vector<std::shared_ptr<FDBundleInfo>> allLibraryBundles();
	};

}

#endif