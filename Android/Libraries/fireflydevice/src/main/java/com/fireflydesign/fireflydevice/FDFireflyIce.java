//
//  FDFireflyIce.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.HashMap;
import java.util.Map;

public class FDFireflyIce implements FDFireflyIceChannel.Delegate {

    public FDFireflyDeviceLog log;
    public FDFireflyIceCoder coder;
    public FDExecutor executor;
    public FDFireflyIceObservable observable;
    public Map<String, FDFireflyIceChannel> channels;
    public String name;

    public FDFireflyIceVersion version;
    public FDFireflyIceHardwareId hardwareId;
    public FDFireflyIceVersion bootVersion;

    public FDFireflyIce() {
        channels = new HashMap<String, FDFireflyIceChannel>();
        observable = FDFireflyIceObservableInvocationHandler.newFireflyIceObservable();
        coder = new FDFireflyIceCoder(observable);
        executor = new FDExecutor();
        name = "anonymous";
    }

	public String description() {
		return name;
	}

	public void addChannel(FDFireflyIceChannel channel, String type) {
		channels.put(type, channel);
		channel.setDelegate(this);
	}

	public void removeChannel(String type)  {
		channels.remove(type);
	}

	public void fireflyIceChannelStatus(FDFireflyIceChannel channel, FDFireflyIceChannel.Status status) {
		executor.setRun(status == FDFireflyIceChannel.Status.Open);
	}

	public void fireflyIceChannelPacket(FDFireflyIceChannel channel, byte[] data) {
		try {
			coder.fireflyIceChannelPacket(this, channel, data);
		} catch (Exception e) {
//			FDFireflyDeviceLogWarn("unexpected exception %s", e.what().c_str());
		}
	}

	public void fireflyIceChannelDetourError(FDFireflyIceChannel channel, FDDetour detour, FDError error) {
		observable.fireflyIceDetourError(this, channel, detour, error);
	}

}