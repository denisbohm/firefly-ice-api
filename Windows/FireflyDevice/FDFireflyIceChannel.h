//
//  FDFireflyIceChannel.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYICECHANNEL_H
#define FDFIREFLYICECHANNEL_H

#include "FDCommon.h"

#include "FDFireflyIce.h"

#include <cstdint>
#include <memory>
#include <vector>

namespace FireflyDesign {

	class FDDetour;
	class FDError;
	class FDFireflyDeviceLog;
	class FDFireflyIceChannel;

	class FDFireflyIceChannelDelegate {
	public:
		virtual ~FDFireflyIceChannelDelegate() {}

		virtual void fireflyIceChannelStatus(std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status) {}
		virtual void fireflyIceChannelPacket(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> packet) {}
		virtual void fireflyIceChannelDetourError(std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error) {}
	};

	class FDFireflyIceChannel {
	public:
		~FDFireflyIceChannel() {}

		virtual std::string getName() = 0;

		virtual std::shared_ptr<FDFireflyDeviceLog> getLog() = 0;
		virtual void setLog(std::shared_ptr<FDFireflyDeviceLog>) = 0;

		virtual void setDelegate(std::shared_ptr<FDFireflyIceChannelDelegate> delegate) = 0;
		virtual std::shared_ptr<FDFireflyIceChannelDelegate> getDelegate() = 0;

		virtual FDFireflyIceChannelStatus getStatus() = 0;

		virtual void fireflyIceChannelSend(std::vector<uint8_t> data) = 0;

		virtual void open() = 0;
		virtual void close() = 0;
	};

}

#endif