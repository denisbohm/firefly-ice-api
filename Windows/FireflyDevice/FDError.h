//
//  FDError.h
//  FireflyDevice
//
//  Created by Denis Bohm on 3/25/14.
//  Copyright (c) 2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDERROR_H
#define FDERROR_H

#include <map>
#include <memory>
#include <string>

namespace fireflydesign {

#define FDLocalizedDescriptionKey "description"
#define FDLocalizedRecoveryOptionsErrorKey "recoveryOptionsError"

	class FDError {
	public:
		static std::shared_ptr<FDError> error(std::string domain, int code, std::map<std::string, std::string> userInfo);
		static std::shared_ptr<FDError> error(std::string domain, int code, std::string description);

		std::string domain;
		int code;
		std::map<std::string, std::string> userInfo;

		std::string description();
	};

}

#endif