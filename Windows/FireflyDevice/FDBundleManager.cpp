//
//  FDBundleManager.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 2/14/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBundleManager.h"

namespace FireflyDesign {

	static std::vector<std::shared_ptr<FDBundleInfo>> libraryBundles;

	void FDBundleManager::addLibraryBundle(std::shared_ptr<FDBundleInfo> bundle)
	{
		libraryBundles.push_back(bundle);
	}

	std::vector<std::shared_ptr<FDBundleInfo>> allLibraryBundles()
	{
		return libraryBundles;
	}

}