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

namespace FireflyDesign {

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

	void FDFireflyIceObservable::except(std::exception e) {
	}

	void FDFireflyIceObservable::fireflyIceStatus(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceStatus(fireflyIce, channel, status);
			} catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceDetourError(fireflyIce, channel, detour, error);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIcePing(fireflyIce, channel, data);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceVersion(fireflyIce, channel, version);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceHardwareId hardwareId) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceHardwareId(fireflyIce, channel, hardwareId);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceBootVersion(fireflyIce, channel, bootVersion);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceDebugLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, bool debugLock) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceDebugLock(fireflyIce, channel, debugLock);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceTime(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, time_type time) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceTime(fireflyIce, channel, time);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIcePower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIcePower power) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIcePower(fireflyIce, channel, power);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceSite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string site) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceSite(fireflyIce, channel, site);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceReset reset) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceReset(fireflyIce, channel, reset);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel>channel, FDFireflyIceStorage storage) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceStorage(fireflyIce, channel, storage);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceMode(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int mode) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceMode(fireflyIce, channel, mode);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceTxPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int txPower) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceTxPower(fireflyIce, channel, txPower);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceLock(fireflyIce, channel, lock);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceLogging(std::shared_ptr<FDFireflyIce>fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLogging logging) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceLogging(fireflyIce, channel, logging);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceName(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string name) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceName(fireflyIce, channel, name);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceDiagnostics(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDiagnostics diagnostics) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceDiagnostics(fireflyIce, channel, diagnostics);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceRetained(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceRetained retained) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceRetained(fireflyIce, channel, retained);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceDirectTestModeReport(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDirectTestModeReport directTestModeReport) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceDirectTestModeReport(fireflyIce, channel, directTestModeReport);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceExternalHash(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> externalHash) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceExternalHash(fireflyIce, channel, externalHash);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIcePageData(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> pageData) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIcePageData(fireflyIce, channel, pageData);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<FDFireflyIceSectorHash> sectorHashes) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceSectorHashes(fireflyIce, channel, sectorHashes);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceUpdateCommit updateCommit) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceUpdateCommit(fireflyIce, channel, updateCommit);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceSensing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceSensing sensing) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceSensing(fireflyIce, channel, sensing);
			}
			catch (std::exception e) {
				except(e);
			}
		}
	}
	void FDFireflyIceObservable::fireflyIceSync(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> syncData) {
		std::vector<std::shared_ptr<FDFireflyIceObserver>> observers(_observers);
		for (std::shared_ptr<FDFireflyIceObserver> observer : observers) {
			try {
				observer->fireflyIceSync(fireflyIce, channel, syncData);
			}
			catch (std::exception e) {
				except(e);
			}
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

	FDFireflyIce::FDFireflyIce(std::shared_ptr<FDTimerFactory> timerFactory)
	{
		observable = std::make_shared<FDFireflyIceObservable>();
		coder = std::make_unique<FDFireflyIceCoder>(observable);
		executor = std::make_unique<FDExecutor>(timerFactory);
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
		fireflyIce->observable->fireflyIceStatus(fireflyIce, channel, status);

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
		fireflyIce->observable->fireflyIceDetourError(fireflyIce, channel, detour, error);
	}

}