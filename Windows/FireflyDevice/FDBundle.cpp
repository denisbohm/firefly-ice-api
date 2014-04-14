//
//  FDBundle.cpp
//  FireflyDevice
//
//  Created by scripts/plistToDictionary.sh
//

#include "FDBundle.h"
#include "FDBundleManager.h"

namespace fireflydesign {

	FDBundle::FDBundle() {
		infoDictionary["CFBundleName"] = "FireflyDevice";
		infoDictionary["CFBundleShortVersionString"] = "1.0.13";
		infoDictionary["CFBundleVersion"] = "13";
		infoDictionary["NSHumanReadableCopyright"] = "Copyright © 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.";
    }

	class FDBundleInit {
	public:
		FDBundleInit() {
			bundle = std::make_shared<FDBundle>();
			FDBundleManager::addLibraryBundle(bundle);
		}

		std::shared_ptr<FDBundle> bundle;
	};

	static FDBundleInit init;

}