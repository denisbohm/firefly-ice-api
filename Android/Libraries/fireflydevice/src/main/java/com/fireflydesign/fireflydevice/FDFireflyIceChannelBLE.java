//
//  FDFireflyIceChannelBLE.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.List;

public class FDFireflyIceChannelBLE implements FDFireflyIceChannel {

    FDFireflyDeviceLog log;
    FDDetour detour;
    FDFireflyIceChannel.Delegate delegate;
    FDFireflyIceChannel.Status status;


    public FDFireflyIceChannelBLE() {
		this.detour = new FDDetour();
	}

	public String getName() {
		return "BLE";
	}

	public FDFireflyDeviceLog getLog() {
		return log;
	}

	public void setLog(FDFireflyDeviceLog log) {
		this.log = log;
	}

	public void setDelegate(FDFireflyIceChannel.Delegate delegate) {
		this.delegate = delegate;
	}

	public FDFireflyIceChannel.Delegate getDelegate() {
		return delegate;
	}

	public FDFireflyIceChannel.Status getStatus() {
		return status;
	}

	public void open() {
		status = FDFireflyIceChannel.Status.Opening;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}

		status = FDFireflyIceChannel.Status.Open;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}
	}

	public void close() {
		detour.clear();
		status = FDFireflyIceChannel.Status.Closed;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}
	}

	public void fireflyIceChannelSend(byte[] data) {
		FDDetourSource source = new FDDetourSource(20, FDBinary.toList(data));
		List<Byte> subdata;
		while ((subdata = source.next()).size() > 0) {
            FDFireflyDeviceLogger.debug(log, "FDFireflyIceChannelBLE:fireflyIceChannelSend:subdata %@", subdata);
			// !!! set characteristic value...
		}
	}

	public void characteristicValueChange(byte[] data) {
		FDFireflyDeviceLogger.debug(log, "FDFireflyIceChannelBLE:characteristicValueChange %@", data);
		detour.detourEvent(FDBinary.toList(data));
		if (detour.state == FDDetour.State.Success) {
			if (delegate != null) {
				delegate.fireflyIceChannelPacket(this, FDBinary.toByteArray(detour.buffer));
			}
			detour.clear();
		} else
		if (detour.state == FDDetour.State.Error) {
			if (delegate != null) {
				delegate.fireflyIceChannelDetourError(this, detour, detour.error);
			}
			detour.clear();
		}
	}

}
