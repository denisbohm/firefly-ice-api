//
//  FDFireflyIceChannelUSB.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDDetour.h"
#include "FDDetourSource.h"
#include "FDFireflyIceChannelUSB.h"
#include "FDFireflyDeviceLogger.h"

namespace fireflydesign {

	FDFireflyIceChannelUSB::FDFireflyIceChannelUSB(std::shared_ptr<FDUSBHIDDevice> device)
	{
		_device = device;
		_detour = std::make_shared<FDDetour>();
	}

	std::string FDFireflyIceChannelUSB::getName()
	{
		return "USB";
	}

	std::shared_ptr<FDFireflyDeviceLog> FDFireflyIceChannelUSB::getLog()
	{
		return log;
	}

	void FDFireflyIceChannelUSB::setLog(std::shared_ptr<FDFireflyDeviceLog> log)
	{
		this->log = log;
	}

	void FDFireflyIceChannelUSB::setDelegate(std::shared_ptr<FDFireflyIceChannelDelegate> delegate)
	{
		_delegate = delegate;
	}

	std::shared_ptr<FDFireflyIceChannelDelegate> FDFireflyIceChannelUSB::getDelegate()
	{
		return _delegate;
	}

	FDFireflyIceChannelStatus FDFireflyIceChannelUSB::getStatus()
	{
		return _status;
	}

	void FDFireflyIceChannelUSB::open()
	{
		_device->setDelegate(shared_from_this());
		_device->open();
		_status = FDFireflyIceChannelStatusOpening;
		if (_delegate) {
			_delegate->fireflyIceChannelStatus(shared_from_this(), _status);
		}
		_status = FDFireflyIceChannelStatusOpen;
		if (_delegate) {
			_delegate->fireflyIceChannelStatus(shared_from_this(), _status);
		}
	}

	void FDFireflyIceChannelUSB::close()
	{
		_device->setDelegate(nullptr);
		_device->close();
		_detour->clear();
		_status = FDFireflyIceChannelStatusClosed;
		if (_delegate) {
			_delegate->fireflyIceChannelStatus(shared_from_this(), _status);
		}
	}

	void FDFireflyIceChannelUSB::fireflyIceChannelSend(std::vector<uint8_t> data)
	{
		FDDetourSource source(64, data);
		std::vector<uint8_t> subdata;
		while ((subdata = source.next()).size() > 0) {
			_device->setReport(subdata);
		}
	}

	void FDFireflyIceChannelUSB::usbHidDeviceReport(std::shared_ptr<FDUSBHIDDevice> device, std::vector<uint8_t> data)
	{
		//    FDFireflyDeviceLogDebug(@"usbHidDevice:inputReport: %@", data);
		_detour->detourEvent(data);
		if (_detour->state == FDDetourStateSuccess) {
			if (_delegate) {
				_delegate->fireflyIceChannelPacket(shared_from_this(), _detour->buffer);
			}
			_detour->clear();
		} else
		if (_detour->state == FDDetourStateError) {
			if (_delegate) {
				_delegate->fireflyIceChannelDetourError(shared_from_this(), _detour, _detour->error);
			}
			_detour->clear();
		}
	}

}
