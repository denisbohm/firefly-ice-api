//
//  FDFireflyIceCoder.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDFireflyIce.h"
#include "FDFireflyIceChannel.h"
#include "FDFireflyIceCoder.h"

namespace FireflyDesign {

#define HASH_SIZE 20

	FDFireflyIceCoder::FDFireflyIceCoder(std::shared_ptr<FDFireflyIceObservable> observable)
	{
		this->observable = observable;
	}

	void FDFireflyIceCoder::sendPing(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_PING);
		binary.putUInt16(data.size());
		binary.putData(data);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::dispatchPing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint16_t length = binary.getUInt16();
		std::vector<uint8_t> pingData = binary.getData(length);

		observable->fireflyIcePing(fireflyIce, channel, pingData);
	}

#define FD_MAP_TYPE_STRING 1

	// binary dictionary format:
	// - uint16_t number of dictionary entries
	// - for each dictionary entry:
	//   - uint8_t length of key
	//   - uint8_t type of value
	//   - uint16_t length of value
	//   - uint16_t offset of key, value bytes
	std::vector<uint8_t> FDFireflyIceCoder::dictionaryMap(std::map<std::string, std::string> dictionary)
	{
		FDBinary map;
		std::vector<uint8_t> content;
		map.putUInt16(dictionary.size());
		for (auto entry : dictionary) {
			std::string key = entry.first;
			std::string value = entry.second;
			std::vector<uint8_t> keyData(key.begin(), key.end());
			std::vector<uint8_t> valueData(value.begin(), value.end());
			map.putUInt8(uint8_t(keyData.size()));
			map.putUInt8(FD_MAP_TYPE_STRING);
			map.putUInt16(uint16_t(valueData.size()));
			std::vector<uint8_t>::size_type offset = content.size();
			map.putUInt16(uint16_t(offset));
			content.insert(content.end(), keyData.begin(), keyData.end());
			content.insert(content.end(), valueData.begin(), valueData.end());
		}
		map.putData(content);
		return map.dataValue();
	}

	void FDFireflyIceCoder::sendProvision(std::shared_ptr<FDFireflyIceChannel> channel, std::map<std::string, std::string> dictionary, uint32_t options)
	{
		std::vector<uint8_t> data = dictionaryMap(dictionary);
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_PROVISION);
		binary.putUInt32(options);
		binary.putUInt16(uint16_t(data.size()));
		binary.putData(data);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendReset(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t type)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_RESET);
		binary.putUInt8(type);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendGetProperties(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t properties)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_GET_PROPERTIES);
		binary.putUInt32(properties);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::dispatchGetPropertyVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceVersion version;
		version.major = binary.getUInt16();
		version.minor = binary.getUInt16();
		version.patch = binary.getUInt16();
		version.capabilities = binary.getUInt32();
		version.gitCommit = binary.getData(20);

		observable->fireflyIceVersion(fireflyIce, channel, version);
	}

	void FDFireflyIceCoder::dispatchGetPropertyBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceVersion version;
		version.major = binary.getUInt16();
		version.minor = binary.getUInt16();
		version.patch = binary.getUInt16();
		version.capabilities = binary.getUInt32();
		version.gitCommit = binary.getData(20);

		observable->fireflyIceBootVersion(fireflyIce, channel, version);
	}

	void FDFireflyIceCoder::dispatchGetPropertyHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceHardwareId hardwareId;
		hardwareId.vendor = binary.getUInt16();
		hardwareId.product = binary.getUInt16();
		hardwareId.major = binary.getUInt16();
		hardwareId.minor = binary.getUInt16();
		hardwareId.unique = binary.getData(8);

		observable->fireflyIceHardwareId(fireflyIce, channel, hardwareId);
	}

	void FDFireflyIceCoder::dispatchGetPropertyDebugLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		bool debugLock = binary.getUInt8() != 0;

		observable->fireflyIceDebugLock(fireflyIce, channel, debugLock);
	}

	void FDFireflyIceCoder::dispatchGetPropertyRTC(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceObservable::time_type time = binary.getTime64();

		observable->fireflyIceTime(fireflyIce, channel, time);
	}

	void FDFireflyIceCoder::dispatchGetPropertyPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIcePower power;
		power.batteryLevel = binary.getFloat32();
		power.batteryVoltage = binary.getFloat32();
		power.isUSBPowered = binary.getUInt8() != 0;
		power.isCharging = binary.getUInt8() != 0;
		power.chargeCurrent = binary.getFloat32();
		power.temperature = binary.getFloat32();

		observable->fireflyIcePower(fireflyIce, channel, power);
	}

	void FDFireflyIceCoder::dispatchGetPropertySite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint16_t length = binary.getUInt16();
		std::vector<uint8_t> data = binary.getData(length);
		std::string site(data.begin(), data.end());

		observable->fireflyIceSite(fireflyIce, channel, site);
	}

	void FDFireflyIceCoder::dispatchGetPropertyReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceReset reset;
		reset.cause = binary.getUInt32();
		reset.date = binary.getTime64();

		observable->fireflyIceReset(fireflyIce, channel, reset);
	}

	void FDFireflyIceCoder::dispatchGetPropertyStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceStorage storage;
		storage.pageCount = binary.getUInt32();

		observable->fireflyIceStorage(fireflyIce, channel, storage);
	}

	void FDFireflyIceCoder::dispatchGetPropertyMode(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint8_t mode = binary.getUInt8();

		observable->fireflyIceMode(fireflyIce, channel, mode);
	}

	void FDFireflyIceCoder::dispatchGetPropertyTxPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint8_t txPower = binary.getUInt8();

		observable->fireflyIceTxPower(fireflyIce, channel, txPower);
	}

	void FDFireflyIceCoder::dispatchGetPropertyLogging(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceLogging logging;
		logging.flags = binary.getUInt32();
		if (logging.flags & FD_CONTROL_LOGGING_STATE) {
			logging.state = binary.getUInt32();
		}
		if (logging.flags & FD_CONTROL_LOGGING_COUNT) {
			logging.count = binary.getUInt32();
		}

		observable->fireflyIceLogging(fireflyIce, channel, logging);
	}

	void FDFireflyIceCoder::dispatchGetPropertyName(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint8_t length = binary.getUInt8();
		std::vector<uint8_t> data = binary.getData(length);
		std::string name(data.begin(), data.end());

		observable->fireflyIceName(fireflyIce, channel, name);
	}

	void FDFireflyIceCoder::dispatchGetPropertyRetained(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceRetained retained;
		retained.retained = binary.getUInt8() != 0;
		uint32_t length = binary.getUInt32();
		retained.data = binary.getData(length);

		observable->fireflyIceRetained(fireflyIce, channel, retained);
	}

	void FDFireflyIceCoder::dispatchGetProperties(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint32_t properties = binary.getUInt32();
		if (properties & FD_CONTROL_PROPERTY_VERSION) {
			dispatchGetPropertyVersion(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_HARDWARE_ID) {
			dispatchGetPropertyHardwareId(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_DEBUG_LOCK) {
			dispatchGetPropertyDebugLock(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_RTC) {
			dispatchGetPropertyRTC(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_POWER) {
			dispatchGetPropertyPower(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_SITE) {
			dispatchGetPropertySite(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_RESET) {
			dispatchGetPropertyReset(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_STORAGE) {
			dispatchGetPropertyStorage(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_MODE) {
			dispatchGetPropertyMode(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_TX_POWER) {
			dispatchGetPropertyTxPower(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_BOOT_VERSION) {
			dispatchGetPropertyBootVersion(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_LOGGING) {
			dispatchGetPropertyLogging(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_NAME) {
			dispatchGetPropertyName(fireflyIce, channel, binary);
		}
		if (properties & FD_CONTROL_PROPERTY_RETAINED) {
			dispatchGetPropertyRetained(fireflyIce, channel, binary);
		}
	}

	void FDFireflyIceCoder::sendSetPropertyTime(std::shared_ptr<FDFireflyIceChannel> channel, time_type time)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_RTC);
		binary.putTime64(time);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSetPropertyMode(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t mode)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_MODE);
		binary.putUInt8(mode);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSetPropertyTxPower(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t txPower)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_TX_POWER);
		binary.putUInt8(txPower);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSetPropertyLogging(std::shared_ptr<FDFireflyIceChannel> channel, bool storage)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_LOGGING);
		binary.putUInt32(FD_CONTROL_LOGGING_STATE);
		binary.putUInt32(FD_CONTROL_LOGGING_STORAGE);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSetPropertyName(std::shared_ptr<FDFireflyIceChannel> channel, std::string name)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_NAME);
		std::vector<uint8_t> data(name.begin(), name.end());
		binary.putUInt8(data.size());
		binary.putData(data);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateGetExternalHash(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t address, uint32_t length)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_GET_EXTERNAL_HASH);
		binary.putUInt32(address);
		binary.putUInt32(length);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateReadPage(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t page)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_READ_PAGE);
		binary.putUInt32(page);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateGetSectorHashes(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint16_t> sectors)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_GET_SECTOR_HASHES);
		binary.putUInt8(sectors.size());
		for (uint16_t sector : sectors) {
			binary.putUInt16(sector);
		}
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateEraseSectors(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint16_t> sectors)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_ERASE_SECTORS);
		binary.putUInt8(sectors.size());
		for (uint16_t sector : sectors) {
			binary.putUInt16(sector);
		}
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateWritePage(std::shared_ptr<FDFireflyIceChannel> channel, uint16_t page, std::vector<uint8_t> data)
	{
		// !!! assert that data.length == page size -denis
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_WRITE_PAGE);
		binary.putUInt16(page);
		binary.putData(data);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendUpdateCommit(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t flags, uint32_t length, std::vector<uint8_t> hash, std::vector<uint8_t> cryptHash, std::vector<uint8_t> cryptIv)
	{
		// !!! assert that data lengths are correct -denis
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_UPDATE_COMMIT);
		binary.putUInt32(flags);
		binary.putUInt32(length);
		binary.putData(hash); // 20 bytes
		binary.putData(cryptHash); // 20 bytes
		binary.putData(cryptIv); // 16 bytes
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	uint16_t FDFireflyIceCoder::makeDirectTestModePacket(FDDirectTestModeCommand command, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type)
	{
		return (command << 14) | ((frequency & 0x3f) << 8) | ((length & 0x3f) << 2) | type;
	}

	void FDFireflyIceCoder::sendDirectTestModeEnter(std::shared_ptr<FDFireflyIceChannel> channel, uint16_t packet, duration_type duration)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER);
		binary.putUInt16(packet);
		binary.putTime64(duration);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendDirectTestModeExit(std::shared_ptr<FDFireflyIceChannel> channel)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendDirectTestModeReport(std::shared_ptr<FDFireflyIceChannel> channel)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT);
		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendDirectTestModeReset(std::shared_ptr<FDFireflyIceChannel> channel)
	{
		sendDirectTestModeEnter(channel, FDFireflyIceCoder::makeDirectTestModePacket(FDDirectTestModeCommandReset, 0, 0, FDDirectTestModePacketTypePRBS9), 0);
	}

	void FDFireflyIceCoder::sendDirectTestModeReceiverTest(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type, duration_type duration)
	{
		sendDirectTestModeEnter(channel, FDFireflyIceCoder::makeDirectTestModePacket(FDDirectTestModeCommandReceiverTest, frequency, length, type), duration);
	}

	void FDFireflyIceCoder::sendDirectTestModeTransmitterTest(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type, duration_type duration)
	{
		sendDirectTestModeEnter(channel, FDFireflyIceCoder::makeDirectTestModePacket(FDDirectTestModeCommandTransmitterTest, frequency, length, type), duration);
	}

	void FDFireflyIceCoder::sendDirectTestModeEnd(std::shared_ptr<FDFireflyIceChannel> channel)
	{
		sendDirectTestModeEnter(channel, FDFireflyIceCoder::makeDirectTestModePacket(FDDirectTestModeCommandTestEnd, 0, 0, FDDirectTestModePacketTypePRBS9), 0);
	}

	void FDFireflyIceCoder::dispatchUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceUpdateCommit updateCommit;
		updateCommit.result = binary.getUInt8();

		observable->fireflyIceUpdateCommit(fireflyIce, channel, updateCommit);
	}

	void FDFireflyIceCoder::dispatchRadioDirectTestModeReport(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceDirectTestModeReport report;
		report.packetCount = binary.getUInt16();

		observable->fireflyIceDirectTestModeReport(fireflyIce, channel, report);
	}

	void FDFireflyIceCoder::dispatchUpdateGetSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		uint8_t sectorCount = binary.getUInt8();
		std::vector<FDFireflyIceSectorHash> sectorHashes;
		for (int i = 0; i < sectorCount; ++i) {
			uint16_t sector = binary.getUInt16();
			std::vector<uint8_t> hash = binary.getData(HASH_SIZE);
			FDFireflyIceSectorHash sectorHash;
			sectorHash.sector = sector;
			sectorHash.hash = hash;
			sectorHashes.push_back(sectorHash);
		}

		observable->fireflyIceSectorHashes(fireflyIce, channel, sectorHashes);
	}

	void FDFireflyIceCoder::dispatchExternalHash(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		std::vector<uint8_t> externalHash = binary.getData(HASH_SIZE);

		observable->fireflyIceExternalHash(fireflyIce, channel, externalHash);
	}

	void FDFireflyIceCoder::dispatchUpdateReadPage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		std::vector<uint8_t> pageData = binary.getData(256);

		observable->fireflyIcePageData(fireflyIce, channel, pageData);
	}

	static void putColor(FDBinary& binary, uint32_t color) {
		binary.putUInt8(color >> 16);
		binary.putUInt8(color >> 8);
		binary.putUInt8(color);
	}

	void FDFireflyIceCoder::sendLEDOverride(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t usbOrange, uint8_t usbGreen, uint8_t d0, uint32_t d1, uint32_t d2, uint32_t d3, uint8_t d4, duration_type duration)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_LED_OVERRIDE);

		binary.putUInt8(usbOrange);
		binary.putUInt8(usbGreen);
		binary.putUInt8(d0);
		putColor(binary, d1);
		putColor(binary, d2);
		putColor(binary, d3);
		binary.putUInt8(d4);
		binary.putTime64(duration);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendIdentify(std::shared_ptr<FDFireflyIceChannel> channel, duration_type duration)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_IDENTIFY);
		binary.putUInt8(1);
		binary.putTime64(duration);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendLock(std::shared_ptr<FDFireflyIceChannel> channel, fd_lock_identifier_t identifier, fd_lock_operation_t operation)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_LOCK);
		binary.putUInt8(identifier);
		binary.putUInt8(operation);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSyncStart(std::shared_ptr<FDFireflyIceChannel> channel)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SYNC_START);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendSyncStart(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t offset)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_SYNC_START);
		binary.putUInt32(FD_CONTROL_SYNC_AHEAD);
		binary.putUInt32(offset);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::sendDiagnostics(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t flags)
	{
		FDBinary binary;
		binary.putUInt8(FD_CONTROL_DIAGNOSTICS);
		binary.putUInt32(flags);

		channel->fireflyIceChannelSend(binary.dataValue());
	}

	void FDFireflyIceCoder::dispatchDiagnostics(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceDiagnostics diagnostics;
		diagnostics.flags = binary.getUInt32();
		std::vector<FDFireflyIceDiagnosticsBLE> values;
		if (diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE) {
			FDFireflyIceDiagnosticsBLE value;
			uint32_t length = binary.getUInt32();
			int position = binary.getIndex;
			value.version = binary.getUInt32();
			value.systemSteps = binary.getUInt32();
			value.dataSteps = binary.getUInt32();
			value.systemCredits = binary.getUInt32();
			value.dataCredits = binary.getUInt32();
			value.txPower = binary.getUInt8();
			value.operatingMode = binary.getUInt8();
			value.idle = binary.getUInt8() != 0;
			value.dtm = binary.getUInt8() != 0;
			value.did = binary.getUInt8();
			value.disconnectAction = binary.getUInt8();
			value.pipesOpen = binary.getUInt64();
			value.dtmRequest = binary.getUInt16();
			value.dtmData = binary.getUInt16();
			value.bufferCount = binary.getUInt32();
			binary.getIndex = (uint32_t)(position + length);
			values.push_back(value);
		}
		if (diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE_TIMING) {
			uint16_t connectionInterval = binary.getUInt16();
			uint16_t slaveLatency = binary.getUInt16();
			uint16_t supervisionTimeout = binary.getUInt16();
// !!!			FDFireflyDeviceLogInfo("BLE timing: %u %u %u", connectionInterval, slaveLatency, supervisionTimeout);
		}
		diagnostics.values = values;
		observable->fireflyIceDiagnostics(fireflyIce, channel, diagnostics);
	}

	void FDFireflyIceCoder::dispatchLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceLock lock;
		lock.identifier = binary.getUInt8();
		lock.operation = binary.getUInt8();
		lock.owner = binary.getUInt32();

		observable->fireflyIceLock(fireflyIce, channel, lock);
	}

	void FDFireflyIceCoder::dispatchSyncData(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		observable->fireflyIceSync(fireflyIce, channel, binary.dataValue());
	}

	void FDFireflyIceCoder::dispatchSensing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary)
	{
		FDFireflyIceSensing sensing;
		sensing.ax = binary.getFloat32();
		sensing.ay = binary.getFloat32();
		sensing.az = binary.getFloat32();
		sensing.mx = binary.getFloat32();
		sensing.my = binary.getFloat32();
		sensing.mz = binary.getFloat32();

		observable->fireflyIceSensing(fireflyIce, channel, sensing);
	}

	void FDFireflyIceCoder::fireflyIceChannelPacket(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data)
	{
		FDBinary binary(data);
		uint8_t code = binary.getUInt8();
		switch (code) {
		case FD_CONTROL_PING:
			dispatchPing(fireflyIce, channel, binary);
			break;
		case FD_CONTROL_GET_PROPERTIES:
			dispatchGetProperties(fireflyIce, channel, binary);
			break;
		case FD_CONTROL_UPDATE_COMMIT:
			dispatchUpdateCommit(fireflyIce, channel, binary);
			break;
		case FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT:
			dispatchRadioDirectTestModeReport(fireflyIce, channel, binary);
			break;

		case FD_CONTROL_UPDATE_GET_EXTERNAL_HASH:
			dispatchExternalHash(fireflyIce, channel, binary);
			break;
		case FD_CONTROL_UPDATE_READ_PAGE:
			dispatchUpdateReadPage(fireflyIce, channel, binary);
			break;

		case FD_CONTROL_UPDATE_GET_SECTOR_HASHES:
			dispatchUpdateGetSectorHashes(fireflyIce, channel, binary);
			break;

		case FD_CONTROL_LOCK:
			dispatchLock(fireflyIce, channel, binary);
			break;

		case FD_CONTROL_SYNC_DATA:
			dispatchSyncData(fireflyIce, channel, binary);
			break;

		case FD_CONTROL_DIAGNOSTICS:
			dispatchDiagnostics(fireflyIce, channel, binary);
			break;

		case 0xff:
			dispatchSensing(fireflyIce, channel, binary);
			break;
		}
	}

}
