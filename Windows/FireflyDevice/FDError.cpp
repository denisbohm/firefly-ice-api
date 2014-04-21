//
//  FDError.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 3/25/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDError.h"
#include "FDString.h"

#include <memory>

namespace FireflyDesign {

	std::shared_ptr<FDError> FDError::error(std::string domain, int code, std::map<std::string, std::string> userInfo) {
		std::shared_ptr<FDError> error = std::make_shared<FDError>();
		error->domain = domain;
		error->code = code;
		error->userInfo = userInfo;
		return error;
	}

	std::shared_ptr<FDError> FDError::error(std::string domain, int code, std::string description) {
		std::map<std::string, std::string> userInfo;
		userInfo[FDLocalizedDescriptionKey] = description;
		return FDError::error(domain, code, userInfo);
	}

	std::string FDError::description() {
		std::string s = userInfo[FDLocalizedDescriptionKey];
		return FDString::format("%s %u %s", domain.c_str(), code, s.c_str());
	}

}
