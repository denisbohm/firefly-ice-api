//
//  FDDetour.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDDETOUR_H
#define FDDETOUR_H

#include <memory>
#include <vector>

namespace fireflydesign {

	class FDError;

	enum FDDetourState {
		FDDetourStateClear,
		FDDetourStateIntermediate,
		FDDetourStateSuccess,
		FDDetourStateError
	};

#define FDDetourErrorDomain "com.fireflydesign.device.FDDetour"

	enum {
		FDDetourErrorCodeOutOfSequence
	};

	class FDDetour {
	public:
		FDDetour();

		FDDetourState state;
		std::vector<uint8_t> buffer;
		std::shared_ptr<FDError> error;

		void clear();
		void detourEvent(std::vector<uint8_t> data);

	private:
		void detourError(std::string reason);
		void detourContinue(std::vector<uint8_t> data);
		void detourStart(std::vector<uint8_t> data);

		uint8_t sequenceNumber;
		unsigned length;
	};

}

#endif
