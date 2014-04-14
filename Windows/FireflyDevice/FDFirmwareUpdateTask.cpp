//
//  FDFirmwareUpdateTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDCrypto.h"
#include "FDFireflyDeviceLogger.h"
#include "FDFireflyIce.h"
#include "FDFireflyIceCoder.h"
#include "FDFireflyIceChannel.h"
#include "FDFirmwareUpdateTask.h"
#include "FDIntelHex.h"

#include <algorithm>
#include <exception>
#include <fstream>

namespace fireflydesign {

	std::shared_ptr<FDFirmwareUpdateTask> FDFirmwareUpdateTask::firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> firmware)
	{
		std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask = std::make_shared<FDFirmwareUpdateTask>();
		firmwareUpdateTask->fireflyIce = fireflyIce;
		firmwareUpdateTask->channel = channel;
		firmwareUpdateTask->setFirmware(firmware);
		return firmwareUpdateTask;
	}

	std::shared_ptr<FDIntelHex> FDFirmwareUpdateTask::loadFirmware(std::string resource)
	{
		std::string path = resource + std::string(".hex");
		std::ifstream in(path);
		if (in.good()) {
			throw std::exception("firmware update file not found");
		}
		std::string content((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		return FDIntelHex::intelHex(content, 0x08000, 0x40000 - 0x08000);
	}

	std::shared_ptr<FDFirmwareUpdateTask> FDFirmwareUpdateTask::firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::shared_ptr<FDIntelHex> intelHex)
	{
		std::shared_ptr<FDFirmwareUpdateTask> firmwareUpdateTask = std::make_shared<FDFirmwareUpdateTask>();
		firmwareUpdateTask->fireflyIce = fireflyIce;
		firmwareUpdateTask->channel = channel;
		firmwareUpdateTask->setFirmware(intelHex->data);
		firmwareUpdateTask->major = stoi(intelHex->properties["major"]);
		firmwareUpdateTask->minor = stoi(intelHex->properties["minor"]);
		firmwareUpdateTask->patch = stoi(intelHex->properties["patch"]);

		return firmwareUpdateTask;
	}

	std::shared_ptr<FDFirmwareUpdateTask> FDFirmwareUpdateTask::firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::string resource)
	{
		std::shared_ptr<FDIntelHex> intelHex = FDFirmwareUpdateTask::loadFirmware(resource);
		return FDFirmwareUpdateTask::firmwareUpdateTask(fireflyIce, channel, intelHex);
	}

	std::shared_ptr<FDFirmwareUpdateTask> FDFirmwareUpdateTask::firmwareUpdateTask(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel)
	{
		return FDFirmwareUpdateTask::firmwareUpdateTask(fireflyIce, channel, "FireflyIce");
	}

	FDFirmwareUpdateTask::FDFirmwareUpdateTask()
	{
		priority = -100;
		_pageSize = 256;
		_sectorSize = 4096;
		_pagesPerSector = _sectorSize / _pageSize;
		commit = true;
		reset = true;
	}

	std::vector<uint8_t> FDFirmwareUpdateTask::getFirmware()
	{
		return _firmware;
	}

	void FDFirmwareUpdateTask::setFirmware(std::vector<uint8_t> unpaddedFirmware)
	{
		// pad to sector multiple of sector size
		_firmware = unpaddedFirmware;
		int length = _firmware.size();
		length = ((length + _sectorSize - 1) / _sectorSize) * _sectorSize;
		_firmware.resize(length);
	}

	void FDFirmwareUpdateTask::executorTaskStarted(FDExecutor *executor)
	{
		FDFireflyIceTaskSteps::executorTaskStarted(executor);

		begin();
	}

	void FDFirmwareUpdateTask::executorTaskResumed(FDExecutor *executor)
	{
		FDFireflyIceTaskSteps::executorTaskResumed(executor);

		begin();
	}

	void FDFirmwareUpdateTask::fireflyIceVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion version)
	{
		_version = std::make_shared<FDFireflyIceVersion>(version);
	}

	void FDFirmwareUpdateTask::fireflyIceBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceVersion bootVersion)
	{
		_bootVersion = std::make_shared<FDFireflyIceVersion>(bootVersion);
	}

	void FDFirmwareUpdateTask::begin()
	{
		_updateSectors.clear();
		_updatePages.clear();

		fireflyIce->coder->sendGetProperties(channel, FD_CONTROL_PROPERTY_VERSION);
		next(std::bind(&FDFirmwareUpdateTask::checkVersion, this));
	}

	bool FDFirmwareUpdateTask::isOutOfDate()
	{
		if (downgrade) {
			return (_version->major != major) || (_version->minor != minor) || (_version->patch != patch);
		}

		if (_version->major < major) {
			return true;
		}
		if (_version->major > major) {
			return false;
		}
		if (_version->minor < minor) {
			return true;
		}
		if (_version->minor > minor) {
			return false;
		}
		if (_version->patch < patch) {
			return true;
		}
		if (_version->patch > patch) {
			return false;
		}
		return false;
	}

	void FDFirmwareUpdateTask::checkOutOfDate()
	{
		if (isOutOfDate()) {
			FDFireflyDeviceLogInfo("firmware %s is out of date with latest %u.%u.%u (boot loader is %s)", _version->description(), major, minor, patch, _bootVersion->description());
			next(std::bind(&FDFirmwareUpdateTask::getSectorHashes, this));
		}
		else {
			FDFireflyDeviceLogInfo("firmware %s is up to date with latest %u.%u.%u (boot loader is %s)", _version->description(), major, minor, patch, _bootVersion->description());
			complete();
		}
	}

	void FDFirmwareUpdateTask::fireflyIceLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceLock lock)
	{
		_lock = std::make_shared<FDFireflyIceLock>(lock);
	}

	void FDFirmwareUpdateTask::checkLock()
	{
		if ((_lock->identifier == fd_lock_identifier_update) && (channel->getName().compare(_lock->ownerName()) == 0)) {
			FDFireflyDeviceLogDebug("acquired update lock");
			checkOutOfDate();
		}
		else {
			FDFireflyDeviceLogDebug("update could not acquire lock");
			complete();
		}
	}

	void FDFirmwareUpdateTask::checkVersion()
	{
		if (_version->capabilities & FD_CONTROL_CAPABILITY_BOOT_VERSION) {
			fireflyIce->coder->sendGetProperties(channel, FD_CONTROL_PROPERTY_BOOT_VERSION);
			next(std::bind(&FDFirmwareUpdateTask::checkVersions, this));
		}
		else {
			checkVersions();
		}
	}

	void FDFirmwareUpdateTask::checkVersions()
	{
		if (_version->capabilities & FD_CONTROL_CAPABILITY_LOCK) {
			fireflyIce->coder->sendLock(channel, fd_lock_identifier_update, fd_lock_operation_acquire);
			next(std::bind(&FDFirmwareUpdateTask::checkLock, this));
		}
		else {
			checkOutOfDate();
		}
	}

	void FDFirmwareUpdateTask::firstSectorHashesCheck()
	{
		checkSectorHashes();
		_invalidSectors = _updateSectors;
		_invalidPages = _updatePages;

		if (_updateSectors.size() == 0) {
			commitUpdate();
		}
		else {
			fireflyIce->coder->sendUpdateEraseSectors(channel, _updateSectors);
			next(std::bind(&FDFirmwareUpdateTask::writeNextPage, this));
		}
	}

	void FDFirmwareUpdateTask::getSomeSectors()
	{
		if (_getSectors.size() > 0) {
			int n = std::min((int)_getSectors.size(), 10);
			std::vector<uint16_t> sectors(_getSectors.begin(), _getSectors.begin() + n);
			_getSectors.erase(_getSectors.begin(), _getSectors.begin() + n);
			fireflyIce->coder->sendUpdateGetSectorHashes(channel, sectors);
		}
		else {
			if (_updatePages.size() == 0) {
				next(std::bind(&FDFirmwareUpdateTask::firstSectorHashesCheck, this));
			}
			else {
				next(std::bind(&FDFirmwareUpdateTask::verify, this));
			}
		}
	}

	void FDFirmwareUpdateTask::getSectorHashes()
	{
		_sectorHashes.clear();

		uint16_t sectorCount = (uint16_t)(_firmware.size() / _sectorSize);
		_getSectors.clear();
		for (uint16_t i = 0; i < sectorCount; ++i) {
			_getSectors.push_back(i);
		}
		_usedSectors = _getSectors;

		getSomeSectors();
	}

	void FDFirmwareUpdateTask::fireflyIceSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<FDFireflyIceSectorHash> sectorHashes)
	{
		_sectorHashes.insert(_sectorHashes.end(), sectorHashes.begin(), sectorHashes.end());

		getSomeSectors();
	}

	void FDFirmwareUpdateTask::checkSectorHashes()
	{
		_updateSectors.clear();
		_updatePages.clear();

		std::vector<uint16_t> updateSectors;
		std::vector<uint16_t> updatePages;
		uint16_t sectorCount = (uint16_t)(_firmware.size() / _sectorSize);
		for (uint16_t i = 0; i < sectorCount; ++i) {
			uint16_t sector = i;
			FDFireflyIceSectorHash sectorHash = _sectorHashes[i];
			if (sectorHash.sector != sector) {
				throw std::exception("unexpected sector");
			}
			std::vector<uint8_t>::iterator begin = _firmware.begin() + i * _sectorSize;
			std::vector<uint8_t> subdata(begin, begin + _sectorSize);
			std::vector<uint8_t> hash = FDCrypto::sha1(subdata);
			if (hash != sectorHash.hash) {
				updateSectors.push_back(sectorHash.sector);
				uint16_t page = sector * _pagesPerSector;
				for (uint16_t i = 0; i < _pagesPerSector; ++i) {
					updatePages.push_back(page + i);
				}
			}
		}

		_updateSectors = updateSectors;
		_updatePages = updatePages;

		if (updateSectors.size() == 0) {
			return;
		}

		//	FDFireflyDeviceLogInfo("updating pages %@", _updatePages);
		FDFireflyDeviceLogInfo("updating %d pages", _updatePages.size());
	}

	void FDFirmwareUpdateTask::writeNextPage()
	{
		float progress = (_invalidPages.size() - _updatePages.size()) / (float)_invalidPages.size();
		if (delegate) {
			delegate->firmwareUpdateTaskProgress(this, progress);
		}
		int progressPercent = (int)(progress * 100);
		if (_lastProgressPercent != progressPercent) {
			_lastProgressPercent = progressPercent;
			FDFireflyDeviceLogInfo("firmware update progress %d%%", progressPercent);
		}

		if (_updatePages.size() == 0) {
			// noting left to write, check the hashes to confirm
			getSectorHashes();
		}
		else {
			uint16_t page = _updatePages[0];
			_updatePages.erase(_updatePages.begin());
			std::vector<uint8_t>::iterator location = _firmware.begin() + page * _pageSize;
			std::vector<uint8_t> data(location, location + _pageSize);
			fireflyIce->coder->sendUpdateWritePage(channel, page, data);
			next(std::bind(&FDFirmwareUpdateTask::writeNextPage, this));
		}
	}

	void FDFirmwareUpdateTask::verify()
	{
		checkSectorHashes();
		if (_updateSectors.size() == 0) {
			commitUpdate();
		} else {
			complete();
		}
	}

	void FDFirmwareUpdateTask::commitUpdate()
	{
		if (!commit) {
			complete();
			return;
		}

		FDFireflyDeviceLogInfo("sending update commit");
		uint32_t flags = 0;
		uint32_t length = (uint32_t)_firmware.size();
		std::vector<uint8_t> hash = FDCrypto::sha1(_firmware);
		std::vector<uint8_t> cryptHash = hash;
		std::vector<uint8_t> cryptIv;
		cryptIv.resize(16);
		fireflyIce->coder->sendUpdateCommit(channel, flags, length, hash, cryptHash, cryptIv);
	}

	void FDFirmwareUpdateTask::fireflyIceUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDFireflyIceUpdateCommit updateCommit)
	{
		_updateCommit = std::make_shared<FDFireflyIceUpdateCommit>(updateCommit);
		complete();
	}

	void FDFirmwareUpdateTask::complete()
	{
		if (_version->capabilities & FD_CONTROL_CAPABILITY_LOCK) {
			FDFireflyDeviceLogDebug("released update lock");
			fireflyIce->coder->sendLock(channel, fd_lock_identifier_update, fd_lock_operation_release);
		}

		bool isFirmwareUpToDate = (_updatePages.size() == 0);
		FDFireflyDeviceLogInfo("isFirmwareUpToDate = %s, commit %s result = %u", isFirmwareUpToDate ? "YES" : "NO", _updateCommit ? "YES" : "NO", _updateCommit->result);
		if (delegate) {
			delegate->firmwareUpdateTaskComplete(this, isFirmwareUpToDate);
		}
		if (reset && isOutOfDate() && isFirmwareUpToDate && _updateCommit && (_updateCommit->result == FD_UPDATE_COMMIT_SUCCESS)) {
			FDFireflyDeviceLogInfo("new firmware has been transferred and comitted - restarting device");
			fireflyIce->coder->sendReset(channel, FD_CONTROL_RESET_SYSTEM_REQUEST);
		}
		done();
	}

}
