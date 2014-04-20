//
//  FDFirmwareUpdateTask.h
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIRMWAREUPDATETASK_H
#define FDFIRMWAREUPDATETASK_H

#include "FDFireflyIceTaskSteps.h"

#include <memory>
#include <vector>

namespace FireflyDesign {

	class FDFirmwareUpdateTask;

	class FDFirmwareUpdateTaskDelegate : FDFireflyIceObserver {
	public:
		virtual ~FDFirmwareUpdateTaskDelegate() {}

		virtual void firmwareUpdateTaskProgress(FDFirmwareUpdateTask *task, float progress) {}
		virtual void firmwareUpdateTaskComplete(FDFirmwareUpdateTask *task, bool isFirmwareUpToDate) {}
	};

	class FDIntelHex;

	class FDFirmwareUpdateTask : public FDFireflyIceTaskSteps {
	public:
		static std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> firmware);
		static std::shared_ptr<FDIntelHex> loadFirmware(std::string resource);
		static std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDIntelHex> intelHex);
		static std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string resource);
		static std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel);

		FDFirmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel);

		// firmware must start at firmware address and be a multiple of the page size (2048)
		void setFirmware(std::vector<uint8_t> unpaddedFirmware);
		std::vector<uint8_t> getFirmware();

		bool downgrade;
		bool commit;
		bool reset;
		uint16_t major;
		uint16_t minor;
		uint16_t patch;

		std::shared_ptr<FDFirmwareUpdateTaskDelegate> delegate;
		std::shared_ptr<FDFireflyDeviceLog> log;

	public: // read-only
		// sector and page size for external flash memory
		uint32_t _sectorSize;
		uint32_t _pageSize;
		uint32_t _pagesPerSector;

		std::vector<uint16_t> _usedSectors;
		std::vector<uint16_t> _invalidSectors;
		std::vector<uint16_t> _invalidPages;

		std::vector<uint16_t> _updateSectors;
		std::vector<uint16_t> _updatePages;

		std::shared_ptr<FDFireflyIceUpdateCommit> _updateCommit;

	private:
		void begin();
		void checkVersion();
		bool isOutOfDate();
		void checkOutOfDate();
		void checkLock();
		void checkVersions();
		void firstSectorHashesCheck();
		void checkSectorHashes();
		void getSectorHashes();
		void commitUpdate();
		void writeNextPage();
		void getSomeSectors();
		void verify();
		void complete();

		std::vector<uint8_t> _firmware;

		std::shared_ptr<FDFireflyIceVersion> _version;
		std::shared_ptr<FDFireflyIceVersion> _bootVersion;
		std::shared_ptr<FDFireflyIceLock> _lock;

		std::vector<uint16_t> _getSectors;
		std::vector<FDFireflyIceSectorHash> _sectorHashes;

		int _lastProgressPercent;

	public:
		virtual void executorTaskStarted(FDExecutor *executor);
		virtual void executorTaskResumed(FDExecutor *executor);

	public:
		virtual void fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version);
		virtual void fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion);
		virtual void fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock);
		virtual void fireflyIceSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<FDFireflyIceSectorHash> sectorHashes);
		virtual void fireflyIceUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceUpdateCommit updateCommit);
	};

}

#endif