//
//  FDFireflyIce.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDExecutor.h"
#include "FDFireflyIce.h"
#include "FDFireflyIceChannel.h"
#include "FDFireflyIceCoder.h"
#include "FDFireflyDeviceLogger.h"
#include "FDString.h"

#include <algorithm>

namespace fireflydesign {

	std::string FDFireflyIceVersion::description()
	{
		std::string s = FDString::format("version %u.%u.%u, capabilities 0x%08x, git commit ", major, minor, patch, capabilities);
		for (uint8_t b : gitCommit) {
			s += FDString::format("%02x", b);
		}
		return s;
	}

	std::string FDFireflyIceHardwareId::description()
	{
		std::string s = FDString::format("vendor 0x%04x, product 0x%04x, version %u.%u unique ", vendor, product, major, minor);
		for (uint8_t b : unique) {
			s += FDString::format("%02x", b);
		}
		return s;
	}

	std::string FDFireflyIcePower::description()
	{
		return FDString::format("battery level %0.2f, battery voltage %0.2f V, USB power %@, charging %@, charge current %0.1f mA, temperature %0.1f C", batteryLevel, batteryVoltage, isUSBPowered ? "YES" : "NO", isCharging ? "YES" : "NO", chargeCurrent * 1000.0, temperature);
	}

	std::string FDFireflyIceSectorHash::description()
	{
		std::string s = FDString::format("sector %u hash 0x", sector);
		for (uint8_t b : hash) {
			s += FDString::format("%02x", b);
		}
		return s;
	}

	std::string FDFireflyIceReset::description()
	{
		if (cause & 1) {
			return "Power On Reset";
		}
		if (cause & 2) {
			return "Brown Out Detector Unregulated Domain Reset";
		}
		if (cause & 4) {
			return "Brown Out Detector Regulated Domain Reset";
		}
		if (cause & 8) {
			return "External Pin Reset";
		}
		if (cause & 16) {
			return "Watchdog Reset";
		}
		if (cause & 32) {
			return "LOCKUP Reset";
		}
		if (cause & 64) {
			return "System Request Reset";
		}
		if (cause == 0) {
			return "No Reset";
		}
		return FDString::format("0x%08x Reset", cause);
	}

	std::string FDFireflyIceStorage::description()
	{
		return FDString::format("page count %u", pageCount);
	}

	std::string FDFireflyIceLock::identifierName()
	{
		switch (identifier) {
		case fd_lock_identifier_sync:
			return "sync";
		case fd_lock_identifier_update:
			return "update";
		default:
			break;
		}
		return "invalid";
	}

	std::string FDFireflyIceLock::operationName()
	{
		switch (operation) {
		case fd_lock_operation_none:
			return "none";
		case fd_lock_operation_acquire:
			return "acquire";
		case fd_lock_operation_release:
			return "release";
		default:
			break;
		}
		return "invalid";
	}

	std::string FDFireflyIceLock::ownerName()
	{
		if (owner == 0) {
			return "none";
		}

		std::string name;
		uint8_t bytes[] = { (owner >> 24) & 0xff, (owner >> 16) & 0xff, (owner >> 8) & 0xff, owner & 0xff };
		for (int i = 0; i < sizeof(bytes); ++i) {
			uint8_t byte = bytes[i];
			if (isalnum(byte)) {
				name += FDString::format("%c", byte);
			} else
			if (!isspace(byte)) {
				name = "";
			}
		}
		if (name.empty()) {
			return FDString::format("anon-0x%08x", owner);
		}
		return name;
	}

	std::string FDFireflyIceLock::description()
	{
		return FDString::format("lock identifier %@ operation %@ owner %", identifierName(), operationName(), ownerName());
	}

	std::string FDFireflyIceLogging::description()
	{
		std::string string("logging");
		if (flags & FD_CONTROL_LOGGING_STATE) {
			string += FDString::format(" storage=%", state & FD_CONTROL_LOGGING_STORAGE ? "YES" : "NO");
		}
		if (flags & FD_CONTROL_LOGGING_COUNT) {
			string += FDString::format(" count=%u", count);
		}
		return string;
	}

#define FD_BLUETOOTH_DID_SETUP        0x01
#define FD_BLUETOOTH_DID_ADVERTISE    0x02
#define FD_BLUETOOTH_DID_CONNECT      0x04
#define FD_BLUETOOTH_DID_OPEN_PIPES   0x08
#define FD_BLUETOOTH_DID_RECEIVE_DATA 0x10

	std::string FDFireflyIceDiagnosticsBLE::description()
	{
		std::string string("BLE(");
		string += FDString::format(" version=%u", version);
		string += FDString::format(" systemSteps=%u", systemSteps);
		string += FDString::format(" dataSteps=%u", dataSteps);
		string += FDString::format(" systemCredits=%u", systemCredits);
		string += FDString::format(" dataCredits=%u", dataCredits);
		string += FDString::format(" txPower=%u", txPower);
		string += FDString::format(" operatingMode=%u", operatingMode);
		string += FDString::format(" idle=%", idle ? "YES" : "NO");
		string += FDString::format(" dtm=%", dtm ? "YES" : "NO");
		string += FDString::format(" did=%02x", did);
		string += FDString::format(" disconnectAction=%u", disconnectAction);
		string += FDString::format(" pipesOpen=%016llx", pipesOpen);
		string += FDString::format(" dtmRequest=%u", dtmRequest);
		string += FDString::format(" dtmData=%u", dtmData);
		string += FDString::format(" bufferCount=%u", bufferCount);
		string += ")";
		return string;
	}

	std::string FDFireflyIceDiagnostics::description()
	{
		std::string string("diagnostics");
		for (auto value : values) {
			string += FDString::format(" %", value.description());
		}
		return string;
	}

	std::string FDFireflyIceRetained::description()
	{
		return FDString::format("retained %@", retained ? "YES" : "NO");
	}

	void FDFireflyIceObservable::addObserver(std::shared_ptr<FDFireflyIceObserver> observer)
	{
		_observers.push_back(observer);
	}

	void FDFireflyIceObservable::removeObserver(std::shared_ptr<FDFireflyIceObserver> observer)
	{
		std::vector<std::shared_ptr<FDFireflyIceObserver>>::iterator result = std::find(_observers.begin(), _observers.end(), observer);
		if (result != _observers.end())
		{
			_observers.erase(result);
		}
	}

	class FDFireflyIceRep : public FDFireflyIceChannelDelegate {
	public:
		FDFireflyIceRep(std::shared_ptr<FDFireflyIce> fireflyIce) {
			this->fireflyIce = fireflyIce;
		}
		virtual void fireflyIceChannelStatus(std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status);
		virtual void fireflyIceChannelPacket(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data);
		virtual void fireflyIceChannelDetourError(std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error);
	
		std::shared_ptr<FDFireflyIce> fireflyIce;
	};

	FDFireflyIce::FDFireflyIce()
	{
		coder = std::make_unique<FDFireflyIceCoder>();
		executor = std::make_unique<FDExecutor>();
		name = "anonymous";
	}

	FDFireflyIce::~FDFireflyIce()
	{
	}
	
	std::string FDFireflyIce::description()
	{
		return name;
	}

	void FDFireflyIce::addChannel(std::shared_ptr<FDFireflyIceChannel> channel, std::string type)
	{
		if (!_rep) {
			_rep = std::make_unique<FDFireflyIceRep>(shared_from_this());
		}
		channels[type] = channel;
		channel->setDelegate(_rep);
	}

	void FDFireflyIce::removeChannel(std::string type) 
	{
		channels.erase(type);
	}

	void FDFireflyIceRep::fireflyIceChannelStatus(std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status)
	{
		fireflyIce->observable.fireflyIceStatus(fireflyIce, channel, status);

		fireflyIce->executor->setRun(status == FDFireflyIceChannelStatusOpen);
	}

	void FDFireflyIceRep::fireflyIceChannelPacket(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data)
	{
		try {
			fireflyIce->coder->fireflyIceChannelPacket(fireflyIce, channel, data);
		} catch (std::exception e) {
//			FDFireflyDeviceLogWarn("unexpected exception %s", e.what().c_str());
		}
	}

	void FDFireflyIceRep::fireflyIceChannelDetourError(std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error)
	{
		fireflyIce->observable.fireflyIceDetourError(fireflyIce, channel, detour, error);
	}

}