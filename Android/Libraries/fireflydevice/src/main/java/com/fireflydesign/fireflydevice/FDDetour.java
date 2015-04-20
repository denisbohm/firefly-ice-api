//
//  FDDetour.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class FDDetour {

    public enum State {
        Clear,
        Intermediate,
        Success,
        Error
    }

    public final static String FDDetourErrorDomain = "com.fireflydesign.device.FDDetour";

    public enum FDDetourError {
        CodeOutOfSequence
    }

    public State state;
    public List<Byte> buffer;
    public FDError error;

    byte sequenceNumber;
    int length;

    public FDDetour() {
        buffer = new ArrayList<>();
		clear();
	}

	public void clear() {
		state = State.Clear;
		sequenceNumber = 0;
		length = 0;
		buffer.clear();
		error = null;
	}

	void detourError(String reason) {
		Map<String, String> userInfo = new HashMap<String, String>();
        userInfo.put(FDError.FDLocalizedDescriptionKey, "Out of sequence data when communicating with the device");
        userInfo.put(FDError.FDLocalizedRecoveryOptionsErrorKey, "Make sure the device stays in close range");
        userInfo.put("com.fireflydesign.device.detail", FDString.format("detour error %s: state %d, length %d, sequence %d, data %d", reason, state, length, sequenceNumber, buffer.size()));
		error = FDError.error(FDDetourErrorDomain, FDDetourError.CodeOutOfSequence.ordinal(), userInfo);
		state = State.Error;
	}

	void detourContinue(List<Byte> data) {
		int total = buffer.size() + data.size();
		if (total > length) {
			// ignore any extra data at the end of the transfer
			data = data.subList(0, length - buffer.size());
		}
		buffer.addAll(data);
		if (buffer.size() >= length) {
			state = State.Success;
		} else {
			++sequenceNumber;
		}
	}

	void detourStart(List<Byte> data) {
		if (data.size() < 2) {
			detourError("data.length < 2");
			return;
		}
		FDBinary binary = new FDBinary(data);
		state = State.Intermediate;
		length = binary.getUInt16();
		sequenceNumber = 0;
		buffer.clear();
		detourContinue(binary.getRemainingData());
	}

	public void detourEvent(List<Byte> data) {
		if (data.size() < 1) {
			detourError("data.length < 1");
			return;
		}
		FDBinary binary = new FDBinary(data);
		byte eventSequenceNumber = binary.getUInt8();
		if (eventSequenceNumber == 0) {
			if (sequenceNumber != 0) {
				detourError("unexpected start");
			} else {
				detourStart(binary.getRemainingData());
			}
		}
		else
		if (eventSequenceNumber != sequenceNumber) {
			detourError(FDString.format("out of sequence found %d but expected %d", eventSequenceNumber, sequenceNumber));
		} else {
			detourContinue(binary.getRemainingData());
		}
	}

}
