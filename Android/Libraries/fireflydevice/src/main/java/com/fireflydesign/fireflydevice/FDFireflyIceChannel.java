//
//  FDFireflyIceChannel.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

public interface FDFireflyIceChannel {

    interface Delegate {
        void fireflyIceChannelStatus(FDFireflyIceChannel channel, FDFireflyIceChannel.Status status);
        void fireflyIceChannelPacket(FDFireflyIceChannel channel, byte[] packet);
        void fireflyIceChannelDetourError(FDFireflyIceChannel channel, FDDetour detour, FDError error);
    }

    enum Status {
        Closed,
        Opening,
        Open
    };

    String getName();

    FDFireflyDeviceLog getLog();
    void setLog(FDFireflyDeviceLog log);

    void setDelegate(FDFireflyIceChannel.Delegate delegate);
    FDFireflyIceChannel.Delegate getDelegate();

    FDFireflyIceChannel.Status getStatus();

    void fireflyIceChannelSend(byte[] data);

    void open();
    void close();

}