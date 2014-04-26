//
//  FDFireflyIce.h
//  FireflyDevice
//
//  Created by Denis Bohm on 7/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYICE_H
#define FDFIREFLYICE_H

#include "FDCommon.h"

#include "FDError.h"

#include <cstdint>
#include <cstdbool>
#include <functional>
#include <map>
#include <vector>

namespace FireflyDesign {

	class FDFireflyIceVersion {
	public:
		uint16_t major;
		uint16_t minor;
		uint16_t patch;
		uint32_t capabilities;
		std::vector<uint8_t> gitCommit;

		std::string description();
	};

	class FDFireflyIceHardwareId {
	public:
		uint16_t vendor;
		uint16_t product;
		uint16_t major;
		uint16_t minor;
		std::vector<uint8_t> unique;

		std::string description();
	};

	class FDFireflyIcePower {
	public:
		float batteryLevel;
		float batteryVoltage;
		bool isUSBPowered;
		bool isCharging;
		float chargeCurrent;
		float temperature;

		std::string description();
	};

	class FDFireflyIceSectorHash {
	public:
		uint16_t sector;
		std::vector<uint8_t> hash;

		std::string description();
	};

	class FDFireflyIceReset {
	public:
		typedef double time_type;

		uint32_t cause;
		time_type date;

		std::string description();
	};

	class FDFireflyIceStorage {
	public:
		uint32_t pageCount;

		std::string description();
	};

	class FDFireflyIceDirectTestModeReport {
	public:
		uint16_t packetCount;
	};

	class FDFireflyIceUpdateCommit {
	public:
		uint8_t result;
	};

	class FDFireflyIceSensing {
	public:
		float ax;
		float ay;
		float az;
		float mx;
		float my;
		float mz;
	};

#define FD_LOCK_OWNER_ENCODE(a, b, c, d) ((a << 24) | (b << 16) | (c << 8) | d)

	enum {
		fd_lock_owner_none = 0,
		fd_lock_owner_ble = FD_LOCK_OWNER_ENCODE('B', 'L', 'E', ' '),
		fd_lock_owner_usb = FD_LOCK_OWNER_ENCODE('U', 'S', 'B', ' '),
	};
	typedef uint32_t fd_lock_owner_t;

	enum {
		fd_lock_operation_none,
		fd_lock_operation_acquire,
		fd_lock_operation_release,
	};
	typedef uint8_t fd_lock_operation_t;

	enum {
		fd_lock_identifier_sync,
		fd_lock_identifier_update,
	};
	typedef uint8_t fd_lock_identifier_t;

	class FDFireflyIceLock {
	public:
		fd_lock_identifier_t identifier;
		fd_lock_operation_t operation;
		fd_lock_owner_t owner;

		std::string identifierName();
		std::string operationName();
		std::string ownerName();
		std::string description();
	};

	class FDFireflyIceLogging {
	public:
		uint32_t flags;
		uint32_t count;
		uint32_t state;

		std::string description();
	};

	class FDFireflyIceDiagnosticsBLE {
	public:
		uint32_t version;
		uint32_t systemSteps;
		uint32_t dataSteps;
		uint32_t systemCredits;
		uint32_t dataCredits;
		uint8_t txPower;
		uint8_t operatingMode;
		uint8_t idle;
		uint8_t dtm;
		uint8_t did;
		uint8_t disconnectAction;
		uint64_t pipesOpen;
		uint16_t dtmRequest;
		uint16_t dtmData;
		uint32_t bufferCount;

		std::string description();
	};

	class FDFireflyIceDiagnostics {
	public:
		uint32_t flags;
		std::vector<FDFireflyIceDiagnosticsBLE> values;

		std::string description();
	};

	class FDFireflyIceRetained {
	public:
		bool retained;
		std::vector<uint8_t> data;

		std::string description();
	};

	enum FDFireflyIceChannelStatus {
		FDFireflyIceChannelStatusClosed,
		FDFireflyIceChannelStatusOpening,
		FDFireflyIceChannelStatusOpen
	};

	class FDDetour;
	class FDFireflyIce;
	class FDFireflyIceChannel;
	class FDFireflyDeviceLog;

	class FDFireflyIceObserver {
	public:
		typedef double time_type;

		virtual void fireflyIceStatus(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status) {}
		virtual void fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error) {}
		virtual void fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data) {}
		virtual void fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version) {}
		virtual void fireflyIceHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceHardwareId hardwareId) {}
		virtual void fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion) {}
		virtual void fireflyIceDebugLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, bool debugLock) {}
		virtual void fireflyIceTime(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, time_type time) {}
		virtual void fireflyIcePower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIcePower power) {}
		virtual void fireflyIceSite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string site) {}
		virtual void fireflyIceReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceReset reset) {}
		virtual void fireflyIceStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel>channel, FDFireflyIceStorage storage) {}
		virtual void fireflyIceMode(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int mode) {}
		virtual void fireflyIceTxPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int txPower) {}
		virtual void fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock) {}
		virtual void fireflyIceLogging(std::shared_ptr<FDFireflyIce>fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLogging logging) {}
		virtual void fireflyIceName(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string name) {}
		virtual void fireflyIceDiagnostics(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDiagnostics diagnostics) {}
		virtual void fireflyIceRetained(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceRetained retained) {}
		virtual void fireflyIceDirectTestModeReport(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDirectTestModeReport directTestModeReport) {}
		virtual void fireflyIceExternalHash(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> externalHash) {}
		virtual void fireflyIcePageData(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> pageData) {}
		virtual void fireflyIceSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<FDFireflyIceSectorHash> sectorHashes) {}
		virtual void fireflyIceUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceUpdateCommit updateCommit) {}
		virtual void fireflyIceSensing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceSensing sensing) {}
		virtual void fireflyIceSync(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> syncData) {}

		virtual ~FDFireflyIceObserver() {}
	};

	class FDFireflyIceObservable : public FDFireflyIceObserver {
	public:
		void addObserver(std::shared_ptr<FDFireflyIceObserver> observer);
		void removeObserver(std::shared_ptr<FDFireflyIceObserver> observer);

	public:
		virtual void fireflyIceStatus(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceChannelStatus status);
		virtual void fireflyIceDetourError(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDDetour> detour, std::shared_ptr<FDError> error);
		virtual void fireflyIcePing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data);
		virtual void fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version);
		virtual void fireflyIceHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceHardwareId hardwareId);
		virtual void fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion);
		virtual void fireflyIceDebugLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, bool debugLock);
		virtual void fireflyIceTime(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, time_type time);
		virtual void fireflyIcePower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIcePower power);
		virtual void fireflyIceSite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string site);
		virtual void fireflyIceReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceReset reset);
		virtual void fireflyIceStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel>channel, FDFireflyIceStorage storage);
		virtual void fireflyIceMode(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int mode);
		virtual void fireflyIceTxPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, int txPower);
		virtual void fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock);
		virtual void fireflyIceLogging(std::shared_ptr<FDFireflyIce>fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLogging logging);
		virtual void fireflyIceName(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string name);
		virtual void fireflyIceDiagnostics(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDiagnostics diagnostics);
		virtual void fireflyIceRetained(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceRetained retained);
		virtual void fireflyIceDirectTestModeReport(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceDirectTestModeReport directTestModeReport);
		virtual void fireflyIceExternalHash(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> externalHash);
		virtual void fireflyIcePageData(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> pageData);
		virtual void fireflyIceSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<FDFireflyIceSectorHash> sectorHashes);
		virtual void fireflyIceUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceUpdateCommit updateCommit);
		virtual void fireflyIceSensing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceSensing sensing);
		virtual void fireflyIceSync(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> syncData);

	private:
		void except(std::exception e);
		std::vector<std::shared_ptr<FDFireflyIceObserver>> _observers;
	};

	class FDExecutor;
	class FDFireflyIceCoder;
	class FDFireflyIceRep;

	class FDFireflyIce : public FDFireflyIceObserver, public std::enable_shared_from_this<FDFireflyIce> {
	public:
		FDFireflyIce::FDFireflyIce();
		FDFireflyIce::~FDFireflyIce();

		void addChannel(std::shared_ptr<FDFireflyIceChannel> channel, std::string type);
		void removeChannel(std::string type);

		std::shared_ptr<FDFireflyDeviceLog> log;
		std::shared_ptr<FDFireflyIceCoder> coder;
		std::shared_ptr<FDExecutor> executor;
		std::shared_ptr<FDFireflyIceObservable> observable;
		std::map<std::string, std::shared_ptr<FDFireflyIceChannel>> channels;
		std::string name;

		std::shared_ptr<FDFireflyIceVersion> version;
		std::shared_ptr<FDFireflyIceHardwareId> hardwareId;
		std::shared_ptr<FDFireflyIceVersion> bootVersion;

		std::string description();

	private:
		std::shared_ptr<FDFireflyIceRep> _rep;
	};

}

#endif