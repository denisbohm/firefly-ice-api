//
//  FDFireflyIceChannelUSB.h
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYICECHANNELUSB_H
#define FDFIREFLYICECHANNELUSB_H

#include "FDFireflyIceChannel.h"

#include <memory>

namespace fireflydesign {

	class FDUSBHIDDevice;

	class FDUSBHIDDeviceDelegate {
	public:
		virtual ~FDUSBHIDDeviceDelegate() {}

		virtual void usbHidDeviceReport(std::shared_ptr<FDUSBHIDDevice> device, std::vector<uint8_t> data) = 0;
	};

	class FDUSBHIDDevice {
	public:
		virtual ~FDUSBHIDDevice() {}

		virtual void setDelegate(std::shared_ptr<FDUSBHIDDeviceDelegate> delegate) = 0;
		virtual std::shared_ptr<FDUSBHIDDeviceDelegate> getDelegate() = 0;

		virtual void open() = 0;
		virtual void close() = 0;

		virtual void setReport(std::vector<uint8_t> data) = 0;
	};

	class FDFireflyIceChannelUSB : public FDFireflyIceChannel, public FDUSBHIDDeviceDelegate, public std::enable_shared_from_this<FDFireflyIceChannelUSB> {
	public:
		FDFireflyIceChannelUSB(std::shared_ptr<FDUSBHIDDevice> device);

		virtual std::string getName();

		virtual std::shared_ptr<FDFireflyDeviceLog> getLog();
		virtual void setLog(std::shared_ptr<FDFireflyDeviceLog>);

		virtual void setDelegate(std::shared_ptr<FDFireflyIceChannelDelegate> delegate);
		virtual std::shared_ptr<FDFireflyIceChannelDelegate> getDelegate();

		virtual FDFireflyIceChannelStatus getStatus();

		virtual void fireflyIceChannelSend(std::vector<uint8_t> data);

		virtual void open();
		virtual void close();

	public:
		virtual void usbHidDeviceReport(std::shared_ptr<FDUSBHIDDevice> device, std::vector<uint8_t> data);

	public:
		std::shared_ptr<FDFireflyDeviceLog> log;

	private:
		std::shared_ptr<FDUSBHIDDevice> _device;
		std::shared_ptr<FDFireflyIceChannelDelegate> _delegate;
		FDFireflyIceChannelStatus _status;
	public:
		std::shared_ptr<FDDetour> _detour;
	};

}

#endif
