//
//  FDFireflyIceCoder.h
//  FireflyDevice
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDFIREFLYICECODER_H
#define FDFIREFLYICECODER_H

#include "FDCommon.h"

#include "FDFireflyIce.h"

#include <map>
#include <memory>
#include <vector>

namespace FireflyDesign {

#define FD_CONTROL_PING 1

#define FD_CONTROL_GET_PROPERTIES 2
#define FD_CONTROL_SET_PROPERTIES 3

#define FD_CONTROL_PROVISION 4
#define FD_CONTROL_RESET 5

#define FD_CONTROL_UPDATE_GET_SECTOR_HASHES 6
#define FD_CONTROL_UPDATE_ERASE_SECTORS 7
#define FD_CONTROL_UPDATE_WRITE_PAGE 8
#define FD_CONTROL_UPDATE_COMMIT 9

#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER 10
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT 11
#define FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT 12

#define FD_CONTROL_DISCONNECT 13

#define FD_CONTROL_LED_OVERRIDE 14

#define FD_CONTROL_SYNC_START 15
#define FD_CONTROL_SYNC_DATA 16
#define FD_CONTROL_SYNC_ACK 17

#define FD_CONTROL_UPDATE_GET_EXTERNAL_HASH 18
#define FD_CONTROL_UPDATE_READ_PAGE 19

#define FD_CONTROL_LOCK 20

#define FD_CONTROL_IDENTIFY 21

#define FD_CONTROL_DIAGNOSTICS 22

#define FD_CONTROL_DIAGNOSTICS_BLE        0x00000001
#define FD_CONTROL_DIAGNOSTICS_BLE_TIMING 0x00000002

#define FD_CONTROL_SYNC_AHEAD 0x00000001

#define FD_CONTROL_LOGGING_STATE 0x00000001
#define FD_CONTROL_LOGGING_COUNT 0x00000002

#define FD_CONTROL_LOGGING_STORAGE 0x00000001

#define FD_CONTROL_CAPABILITY_LOCK         0x00000001
#define FD_CONTROL_CAPABILITY_BOOT_VERSION 0x00000002
#define FD_CONTROL_CAPABILITY_SYNC_FLAGS   0x00000004
#define FD_CONTROL_CAPABILITY_SYNC_AHEAD   0x00000004
#define FD_CONTROL_CAPABILITY_IDENTIFY     0x00000008
#define FD_CONTROL_CAPABILITY_LOGGING      0x00000010
#define FD_CONTROL_CAPABILITY_DIAGNOSTICS  0x00000010
#define FD_CONTROL_CAPABILITY_NAME         0x00000020
#define FD_CONTROL_CAPABILITY_RETAINED     0x00000040

	// property bits for get/set property commands
#define FD_CONTROL_PROPERTY_VERSION      0x00000001
#define FD_CONTROL_PROPERTY_HARDWARE_ID  0x00000002
#define FD_CONTROL_PROPERTY_DEBUG_LOCK   0x00000004
#define FD_CONTROL_PROPERTY_RTC          0x00000008
#define FD_CONTROL_PROPERTY_POWER        0x00000010
#define FD_CONTROL_PROPERTY_SITE         0x00000020
#define FD_CONTROL_PROPERTY_RESET        0x00000040
#define FD_CONTROL_PROPERTY_STORAGE      0x00000080
#define FD_CONTROL_PROPERTY_MODE         0x00000100
#define FD_CONTROL_PROPERTY_TX_POWER     0x00000200
#define FD_CONTROL_PROPERTY_BOOT_VERSION 0x00000400
#define FD_CONTROL_PROPERTY_LOGGING      0x00000800
#define FD_CONTROL_PROPERTY_NAME         0x00001000
#define FD_CONTROL_PROPERTY_RETAINED     0x00002000

#define FD_CONTROL_PROVISION_OPTION_DEBUG_LOCK 0x00000001
#define FD_CONTROL_PROVISION_OPTION_RESET 0x00000002

#define FD_CONTROL_RESET_SYSTEM_REQUEST 1
#define FD_CONTROL_RESET_WATCHDOG 2
#define FD_CONTROL_RESET_HARD_FAULT 3

#define FD_CONTROL_MODE_STORAGE 1

#define FD_UPDATE_METADATA_FLAG_ENCRYPTED 0x00000001

#define FD_UPDATE_COMMIT_SUCCESS 0
#define FD_UPDATE_COMMIT_FAIL_HASH_MISMATCH 1
#define FD_UPDATE_COMMIT_FAIL_CRYPT_HASH_MISMATCH 2
#define FD_UPDATE_COMMIT_FAIL_UNSUPPORTED 3

	enum FDDirectTestModeCommand {
		FDDirectTestModeCommandReset = 0x0,
		FDDirectTestModeCommandReceiverTest = 0x1,
		FDDirectTestModeCommandTransmitterTest = 0x2,
		FDDirectTestModeCommandTestEnd = 0x3
	} ;

	enum FDDirectTestModePacketType {
		FDDirectTestModePacketTypePRBS9 = 0x0,
		FDDirectTestModePacketTypeF0 = 0x1,
		FDDirectTestModePacketTypeAA = 0x2,
		FDDirectTestModePacketTypeVendorSpecific = 0x3
	};

	class FDBinary;
	class FDFireflyIce;
	class FDFireflyIceChannel;
	class FDFireflyIceObservable;

	class FDFireflyIceCoder {
	public:
		typedef double time_type;
		typedef double duration_type;

		FDFireflyIceCoder(std::shared_ptr<FDFireflyIceObservable> observable);

		FDFireflyIceObservable* getObservable();

		void fireflyIceChannelPacket(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data);

		void sendPing(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint8_t> data);

	    void sendGetProperties(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t properties);
	    void sendSetPropertyTime(std::shared_ptr<FDFireflyIceChannel> channel, time_type time);
	    void sendSetPropertyMode(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t mode);
	    void sendSetPropertyTxPower(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t level);
	    void sendSetPropertyLogging(std::shared_ptr<FDFireflyIceChannel> channel, bool storage);
	    void sendSetPropertyName(std::shared_ptr<FDFireflyIceChannel> channel, std::string name);

		void sendProvision(std::shared_ptr<FDFireflyIceChannel> channel, std::map<std::string, std::string> dictionary, uint32_t options);
	    void sendReset(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t type);

	    void sendUpdateGetExternalHash(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t address, uint32_t length);
	    void sendUpdateReadPage(std::shared_ptr<FDFireflyIceChannel> channel,  uint32_t page);
		void sendUpdateGetSectorHashes(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint16_t> sectors);
		void sendUpdateEraseSectors(std::shared_ptr<FDFireflyIceChannel> channel, std::vector<uint16_t> sectors);
	    void sendUpdateWritePage(std::shared_ptr<FDFireflyIceChannel> channel, uint16_t page, std::vector<uint8_t> data);
	    void sendUpdateCommit(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t flags, uint32_t length, std::vector<uint8_t> hash, std::vector<uint8_t> cryptHash, std::vector<uint8_t> cryptIv);

		static uint16_t makeDirectTestModePacket(FDDirectTestModeCommand command, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type);
		void sendDirectTestModeEnter(std::shared_ptr<FDFireflyIceChannel> channel, uint16_t packet, duration_type duration);
		void sendDirectTestModeExit(std::shared_ptr<FDFireflyIceChannel> channel);
		void sendDirectTestModeReport(std::shared_ptr<FDFireflyIceChannel> channel);

		void sendDirectTestModeReset(std::shared_ptr<FDFireflyIceChannel> channel);
	    void sendDirectTestModeReceiverTest(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type, duration_type duration);
	    void sendDirectTestModeTransmitterTest(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t frequency, uint8_t length, FDDirectTestModePacketType type, duration_type duration);
		void sendDirectTestModeEnd(std::shared_ptr<FDFireflyIceChannel> channel);

	    void sendLEDOverride(std::shared_ptr<FDFireflyIceChannel> channel, uint8_t usbOrange, uint8_t usbGreen, uint8_t d0, uint32_t d1, uint32_t d2, uint32_t d3, uint8_t d4, duration_type duration);

	    void sendIdentify(std::shared_ptr<FDFireflyIceChannel> channel, duration_type duration);

	    void sendLock(std::shared_ptr<FDFireflyIceChannel> channel, fd_lock_identifier_t identifier, fd_lock_operation_t operation);

	    void sendSyncStart(std::shared_ptr<FDFireflyIceChannel> channel);
	    void sendSyncStart(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t offset);

	    void sendDiagnostics(std::shared_ptr<FDFireflyIceChannel> channel, uint32_t flags);

	private:
		std::shared_ptr<FDFireflyIceObservable> observable;

		std::vector<uint8_t> FDFireflyIceCoder::dictionaryMap(std::map<std::string, std::string> dictionary);
			
		void dispatchPing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyBootVersion(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyHardwareId(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyDebugLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyRTC(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertySite(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyReset(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyStorage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyMode(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyTxPower(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyLogging(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyName(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetPropertyRetained(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchGetProperties(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchUpdateCommit(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchRadioDirectTestModeReport(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchUpdateGetSectorHashes(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchExternalHash(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchUpdateReadPage(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchDiagnostics(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchLock(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchSyncData(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
		void dispatchSensing(std::shared_ptr<FDFireflyIce> fireflyIce, std::shared_ptr<FDFireflyIceChannel> channel, FDBinary& binary);
	};

}

#endif