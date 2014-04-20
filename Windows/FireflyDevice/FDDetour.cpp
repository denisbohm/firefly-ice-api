//
//  FDDetour.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDDetour.h"
#include "FDError.h"
#include "FDFireflyDeviceLogger.h"
#include "FDString.h"

#include <map>

namespace FireflyDesign {

	FDDetour::FDDetour() {
		clear();
	}

	void FDDetour::clear() {
		state = FDDetourStateClear;
		sequenceNumber = 0;
		length = 0;
		buffer.clear();
		error.reset();
	}

	void FDDetour::detourError(std::string reason) {
		std::map<std::string, std::string> userInfo = {
			{ FDLocalizedDescriptionKey, "Out of sequence data when communicating with the device" },
			{ FDLocalizedRecoveryOptionsErrorKey, "Make sure the device stays in close range" },
			{ "com.fireflydesign.device.detail", FDString::format("detour error %s: state %u, length %u, sequence %u, data %u", reason.c_str(), state, length, sequenceNumber, buffer.size()) }
		};
		error = FDError::error(FDDetourErrorDomain, FDDetourErrorCodeOutOfSequence, userInfo);
		state = FDDetourStateError;
	}

	void FDDetour::detourContinue(std::vector<uint8_t> data) {
		unsigned total = buffer.size() + data.size();
		if (total > length) {
			// ignore any extra data at the end of the transfer
			data = std::vector<uint8_t>(data.begin(), data.begin() + (length - buffer.size()));
		}
		buffer.insert(buffer.end(), data.begin(), data.end());
		if (buffer.size() >= length) {
			state = FDDetourStateSuccess;
		} else {
			++sequenceNumber;
		}
	}

	void FDDetour::detourStart(std::vector<uint8_t> data) {
		if (data.size() < 2) {
			detourError("data.length < 2");
			return;
		}
		FDBinary binary(data);
		state = FDDetourStateIntermediate;
		length = binary.getUInt16();
		sequenceNumber = 0;
		buffer.clear();
		detourContinue(binary.getRemainingData());
	}

	void FDDetour::detourEvent(std::vector<uint8_t> data) {
		if (data.size() < 1) {
			detourError("data.length < 1");
			return;
		}
		FDBinary binary(data);
		uint8_t eventSequenceNumber = binary.getUInt8();
		if (eventSequenceNumber == 0) {
			if (sequenceNumber != 0) {
				detourError("unexpected start");
			} else {
				detourStart(binary.getRemainingData());
			}
		}
		else
		if (eventSequenceNumber != sequenceNumber) {
			detourError(FDString::format("out of sequence found %u but expected %u", eventSequenceNumber, sequenceNumber));
		} else {
			detourContinue(binary.getRemainingData());
		}
	}

}
