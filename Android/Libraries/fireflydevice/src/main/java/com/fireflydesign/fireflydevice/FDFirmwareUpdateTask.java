//
//  FDFirmwareUpdateTask.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/14/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

public class FDFirmwareUpdateTask extends FDFireflyIceTaskSteps {

    public interface Delegate {
        void firmwareUpdateTaskProgress(FDFirmwareUpdateTask task, float progress);
        void firmwareUpdateTaskComplete(FDFirmwareUpdateTask task, boolean isFirmwareUpToDate);
    }

    public boolean downgrade;
    public boolean commit;
    public boolean reset;
    public short major;
    public short minor;
    public short patch;
    
    public Delegate delegate;
    public FDFireflyDeviceLog log;

    // read-only
    // sector and page size for external flash memory
    public int _sectorSize;
    public int _pageSize;
    public int _pagesPerSector;
    
    public List<Short> _usedSectors;
    public List<Short> _invalidSectors;
    public List<Short> _invalidPages;
    
    public List<Short> _updateSectors;
    public List<Short> _updatePages;
    
    public FDFireflyIceUpdateCommit _updateCommit;

    byte[] _firmware;

    FDFireflyIceVersion _version;
    FDFireflyIceVersion _bootVersion;
    FDFireflyIceLock _lock;

    List<Short> _getSectors;
    List<FDFireflyIceSectorHash> _sectorHashes;

    int _lastProgressPercent;

    public static FDFirmwareUpdateTask firmwareUpdateTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] firmware) {
		FDFirmwareUpdateTask firmwareUpdateTask = new FDFirmwareUpdateTask(fireflyIce, channel);
		firmwareUpdateTask.setFirmware(firmware);
		return firmwareUpdateTask;
	}

	public static FDIntelHex loadFirmware(String resource) {
        String content = new Scanner(FDFirmwareUpdateTask.class.getResourceAsStream(resource + ".hex"), "UTF-8").useDelimiter("\\A").next();
		return FDIntelHex.intelHex(content, 0x08000, 0x40000 - 0x08000);
	}

    public static FDFirmwareUpdateTask firmwareUpdateTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDIntelHex intelHex) {
		FDFirmwareUpdateTask firmwareUpdateTask = new FDFirmwareUpdateTask(fireflyIce, channel);
		firmwareUpdateTask.setFirmware(intelHex.data);
		firmwareUpdateTask.major = Short.parseShort(intelHex.properties.get("major"));
		firmwareUpdateTask.minor = Short.parseShort(intelHex.properties.get("minor"));
		firmwareUpdateTask.patch = Short.parseShort(intelHex.properties.get("patch"));
		return firmwareUpdateTask;
	}

    public static FDFirmwareUpdateTask firmwareUpdateTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String resource) {
		FDIntelHex intelHex = loadFirmware(resource);
		return firmwareUpdateTask(fireflyIce, channel, intelHex);
	}

	public static FDFirmwareUpdateTask firmwareUpdateTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel) {
		return firmwareUpdateTask(fireflyIce, channel, "FireflyIce");
	}

	public FDFirmwareUpdateTask(FDFireflyIce fireflyIce, FDFireflyIceChannel channel) {
		super(fireflyIce, channel);

		priority = -100;

		downgrade = false;
		commit = true;
		reset = true;

		major = 0;
		minor = 0;
		patch = 0;

		_pageSize = 256;
		_sectorSize = 4096;
		_pagesPerSector = _sectorSize / _pageSize;

		_lastProgressPercent = 0;
	}

	public byte[] getFirmware() {
		return _firmware;
	}

	public void setFirmware(byte[] unpaddedFirmware) {
		// pad to sector multiple of sector size
		_firmware = unpaddedFirmware;
		int length = _firmware.length;
		length = ((length + _sectorSize - 1) / _sectorSize) * _sectorSize;
        _firmware = Arrays.copyOf(_firmware, length);
	}

	public void executorTaskStarted(FDExecutor executor) {
		super.executorTaskStarted(executor);

		begin();
	}

	public void executorTaskResumed(FDExecutor executor) {
		super.executorTaskResumed(executor);

		begin();
	}

	public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version)
	{
		_version = version;
	}

	public void fireflyIceBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion bootVersion) {
		_bootVersion = bootVersion;
	}

	void begin() {
		_updateSectors.clear();
		_updatePages.clear();

		fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_VERSION);
		next("checkVersion");
	}

	boolean isOutOfDate() {
		if (downgrade) {
			return (_version.major != major) || (_version.minor != minor) || (_version.patch != patch);
		}

		if (_version.major < major) {
			return true;
		}
		if (_version.major > major) {
			return false;
		}
		if (_version.minor < minor) {
			return true;
		}
		if (_version.minor > minor) {
			return false;
		}
		if (_version.patch < patch) {
			return true;
		}
		if (_version.patch > patch) {
			return false;
		}
		return false;
	}

	void checkOutOfDate() {
		String versionDescription = _version.description();
		String bootVersionDescription = "0";
		if (_bootVersion != null) {
			bootVersionDescription = _bootVersion.description();
		}
		if (isOutOfDate()) {
			FDFireflyDeviceLogger.info(log, "firmware %s is out of date with latest %d.%d.%d (boot loader is %s)", versionDescription, major, minor, patch, bootVersionDescription);
			next("getSectorHashes");
		}
		else {
			FDFireflyDeviceLogger.info(log, "firmware %s is up to date with latest %d.%d.%d (boot loader is %s)", versionDescription, major, minor, patch, bootVersionDescription);
			complete();
		}
	}

	public void fireflyIceLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLock lock) {
		_lock = lock;
	}

	void checkLock() {
		if ((_lock.identifier == FDFireflyIceLock.Identifier.Update) && channel.getName().equals(_lock.ownerName())) {
			FDFireflyDeviceLogger.debug(log, "acquired update lock");
			checkOutOfDate();
		} else {
			FDFireflyDeviceLogger.debug(log, "update could not acquire lock");
			complete();
		}
	}

	void checkVersion() {
		if (_version == null) {
			throw new RuntimeException("version not found");
		}
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_BOOT_VERSION) != 0) {
			fireflyIce.coder.sendGetProperties(channel, FDFireflyIceCoder.FD_CONTROL_PROPERTY_BOOT_VERSION);
			next("checkVersions");
		} else {
			checkVersions();
		}
	}

	void checkVersions() {
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
			fireflyIce.coder.sendLock(channel, FDFireflyIceLock.Identifier.Update, FDFireflyIceLock.Operation.Acquire);
			next("checkLock");
		} else {
			checkOutOfDate();
		}
	}

	void firstSectorHashesCheck() {
		checkSectorHashes();
		_invalidSectors = _updateSectors;
		_invalidPages = _updatePages;

		if (_updateSectors.size() == 0) {
			commitUpdate();
		} else {
			fireflyIce.coder.sendUpdateEraseSectors(channel, _updateSectors);
			next("writeNextPage");
		}
	}

	void getSomeSectors() {
		if (_getSectors.size() > 0) {
			int n = Math.min((int) _getSectors.size(), 10);
            List<Short> sectors = new ArrayList<Short>();
            for (int i = 0; i < n; ++i) {
                sectors.add(_getSectors.get(0));
                _getSectors.remove(0);
            }
			fireflyIce.coder.sendUpdateGetSectorHashes(channel, sectors);
		} else {
			if (_updatePages.size() == 0) {
				next("firstSectorHashesCheck");
			} else {
				next("verify");
			}
		}
	}

	void getSectorHashes() {
		_sectorHashes.clear();

		int sectorCount = _firmware.length / _sectorSize;
		_getSectors.clear();
		for (int i = 0; i < sectorCount; ++i) {
			_getSectors.add((short) i);
		}
		_usedSectors = _getSectors;

		getSomeSectors();
	}

	public void fireflyIceSectorHashes(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSectorHash[] sectorHashes) {
        for (FDFireflyIceSectorHash sectorHashe : sectorHashes) {
            _sectorHashes.add(sectorHashe);
        }

		getSomeSectors();
	}

	void checkSectorHashes() {
		_updateSectors.clear();
		_updatePages.clear();

		List<Short> updateSectors = new ArrayList<Short>();
        List<Short> updatePages = new ArrayList<Short>();
		int sectorCount = _firmware.length / _sectorSize;
		for (int i = 0; i < sectorCount; ++i) {
			short sector = (short)i;
			FDFireflyIceSectorHash sectorHash = _sectorHashes.get(i);
			if (sectorHash.sector != sector) {
				throw new RuntimeException("unexpected sector");
			}
			int begin = i * _sectorSize;
			byte[] subdata = Arrays.copyOfRange(_firmware, begin, begin + _sectorSize);
			byte[] hash = FDCrypto.sha1(subdata);
			if (hash != sectorHash.hash) {
				updateSectors.add(sectorHash.sector);
				int page = sector * _pagesPerSector;
				for (int j = 0; j < _pagesPerSector; ++j) {
					updatePages.add((short)(page + j));
				}
			}
		}

		_updateSectors = updateSectors;
		_updatePages = updatePages;

		if (updateSectors.size() == 0) {
			return;
		}

		//	FDFireflyDeviceLogInfo("updating pages %s", _updatePages);
		FDFireflyDeviceLogger.info(log, "updating %d pages", _updatePages.size());
	}

	void writeNextPage() {
		float progress = (_invalidPages.size() - _updatePages.size()) / (float)_invalidPages.size();
		if (delegate != null) {
			delegate.firmwareUpdateTaskProgress(this, progress);
		}
		int progressPercent = (int)(progress * 100);
		if (_lastProgressPercent != progressPercent) {
			_lastProgressPercent = progressPercent;
			FDFireflyDeviceLogger.info(log, "firmware update progress %d%%", progressPercent);
		}

		if (_updatePages.size() == 0) {
			// noting left to write, check the hashes to confirm
			getSectorHashes();
		} else {
			short page = _updatePages.get(0);
			_updatePages.remove(0);
			int location = page * _pageSize;
            byte[] data = Arrays.copyOfRange(_firmware, location, location + _pageSize);
			fireflyIce.coder.sendUpdateWritePage(channel, page, data);
			next("writeNextPage");
		}
	}

	void verify() {
		checkSectorHashes();
		if (_updateSectors.size() == 0) {
			commitUpdate();
		} else {
			complete();
		}
	}

	void commitUpdate() {
		if (!commit) {
			complete();
			return;
		}

		FDFireflyDeviceLogger.info(log, "sending update commit");
		int flags = 0;
		int length = _firmware.length;
		byte[] hash = FDCrypto.sha1(_firmware);
		byte[] cryptHash = hash;
		byte[] cryptIv = new byte[16];
		fireflyIce.coder.sendUpdateCommit(channel, flags, length, hash, cryptHash, cryptIv);
	}

	public void fireflyIceUpdateCommit(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceUpdateCommit updateCommit) {
		_updateCommit = updateCommit;
		complete();
	}

	void complete() {
		if ((_version.capabilities & FDFireflyIceCoder.FD_CONTROL_CAPABILITY_LOCK) != 0) {
			FDFireflyDeviceLogger.debug(log, "released update lock");
			fireflyIce.coder.sendLock(channel, FDFireflyIceLock.Identifier.Update, FDFireflyIceLock.Operation.Release);
		}

		boolean isFirmwareUpToDate = (_updatePages.size() == 0);
		int result = 0;
		if (_updateCommit != null) {
			result = _updateCommit.result;
		}
		FDFireflyDeviceLogger.info(log, "isFirmwareUpToDate = %s, commit %s result = %d", isFirmwareUpToDate ? "YES" : "NO", _updateCommit != null ? "YES" : "NO", result);
		if (delegate != null) {
			delegate.firmwareUpdateTaskComplete(this, isFirmwareUpToDate);
		}
		if (reset && isOutOfDate() && isFirmwareUpToDate && (_updateCommit != null) && (_updateCommit.result == FDFireflyIceCoder.FD_UPDATE_COMMIT_SUCCESS)) {
			FDFireflyDeviceLogger.info(log, "new firmware has been transferred and comitted - restarting device");
			fireflyIce.coder.sendReset(channel, FDFireflyIceCoder.FD_CONTROL_RESET_SYSTEM_REQUEST);
		}
		done();
	}

}
