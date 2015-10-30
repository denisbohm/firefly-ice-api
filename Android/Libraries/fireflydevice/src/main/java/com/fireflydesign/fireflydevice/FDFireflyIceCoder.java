//
//  FDFireflyIceCoder.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 7/19/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.io.UnsupportedEncodingException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.SimpleTimeZone;
import java.util.TimeZone;

public class FDFireflyIceCoder {

    public static final byte FD_CONTROL_PING = 1;

    public static final byte FD_CONTROL_GET_PROPERTIES = 2;
    public static final byte FD_CONTROL_SET_PROPERTIES = 3;

    public static final byte FD_CONTROL_PROVISION = 4;
    public static final byte FD_CONTROL_RESET = 5;

    public static final byte FD_CONTROL_UPDATE_GET_SECTOR_HASHES = 6;
    public static final byte FD_CONTROL_UPDATE_ERASE_SECTORS = 7;
    public static final byte FD_CONTROL_UPDATE_WRITE_PAGE = 8;
    public static final byte FD_CONTROL_UPDATE_COMMIT = 9;

    public static final byte FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER = 10;
    public static final byte FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT = 11;
    public static final byte FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT = 12;

    public static final byte FD_CONTROL_DISCONNECT = 13;

    public static final byte FD_CONTROL_LED_OVERRIDE = 14;

    public static final byte FD_CONTROL_SYNC_START = 15;
    public static final byte FD_CONTROL_SYNC_DATA = 16;
    public static final byte FD_CONTROL_SYNC_ACK = 17;

    public static final byte FD_CONTROL_UPDATE_GET_EXTERNAL_HASH = 18;
    public static final byte FD_CONTROL_UPDATE_READ_PAGE = 19;

    public static final byte FD_CONTROL_LOCK = 20;

    public static final byte FD_CONTROL_IDENTIFY = 21;

    public static final byte FD_CONTROL_DIAGNOSTICS = 22;

    public static final byte FD_CONTROL_UPDATE_AREA_GET_VERSION = 24;
    public static final byte FD_CONTROL_UPDATE_AREA_GET_EXTERNAL_HASH = 25;
    public static final byte FD_CONTROL_UPDATE_AREA_GET_SECTOR_HASHES = 26;
    public static final byte FD_CONTROL_UPDATE_AREA_ERASE_SECTORS = 27;
    public static final byte FD_CONTROL_UPDATE_AREA_WRITE_PAGE = 28;
    public static final byte FD_CONTROL_UPDATE_AREA_READ_PAGE = 29;
    public static final byte FD_CONTROL_UPDATE_AREA_COMMIT = 30;

    public static final byte FD_CONTROL_RTC = 31;

    public static final byte FD_CONTROL_HARDWARE = 32;

    public static final int FD_CONTROL_DIAGNOSTICS_BLE        = 0x00000001;
    public static final int FD_CONTROL_DIAGNOSTICS_BLE_TIMING = 0x00000002;

    public static final int FD_CONTROL_SYNC_AHEAD = 0x00000001;

    public static final int FD_CONTROL_LOGGING_STATE = 0x00000001;
    public static final int FD_CONTROL_LOGGING_COUNT = 0x00000002;

    public static final int FD_CONTROL_LOGGING_STORAGE = 0x00000001;

    public static final int FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_REVISION = 0x00000001;
    public static final int FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_METADATA = 0x00000002;

    public static final int FD_CONTROL_RTC_FLAG_GET_TIME       = 0x00000001;
    public static final int FD_CONTROL_RTC_FLAG_SET_TIME       = 0x00000002;
    public static final int FD_CONTROL_RTC_FLAG_GET_UTC_OFFSET = 0x00000004;
    public static final int FD_CONTROL_RTC_FLAG_SET_UTC_OFFSET = 0x00000008;

    public static final int FD_CONTROL_HARDWARE_FLAG_GET_UNIQUE = 0x00000001;
    public static final int FD_CONTROL_HARDWARE_FLAG_GET_USB    = 0x00000002;
    public static final int FD_CONTROL_HARDWARE_FLAG_GET_BLE    = 0x00000004;

    public static final int FD_CONTROL_CAPABILITY_LOCK         = 0x00000001;
    public static final int FD_CONTROL_CAPABILITY_BOOT_VERSION = 0x00000002;
    public static final int FD_CONTROL_CAPABILITY_SYNC_FLAGS   = 0x00000004;
    public static final int FD_CONTROL_CAPABILITY_SYNC_AHEAD   = 0x00000004;
    public static final int FD_CONTROL_CAPABILITY_IDENTIFY     = 0x00000008;
    public static final int FD_CONTROL_CAPABILITY_LOGGING      = 0x00000010;
    public static final int FD_CONTROL_CAPABILITY_DIAGNOSTICS  = 0x00000010;
    public static final int FD_CONTROL_CAPABILITY_NAME         = 0x00000020;
    public static final int FD_CONTROL_CAPABILITY_RETAINED     = 0x00000040;

	// property bits for get/set property commands
    public static final int FD_CONTROL_PROPERTY_VERSION          = 0x00000001;
    public static final int FD_CONTROL_PROPERTY_HARDWARE_ID      = 0x00000002;
    public static final int FD_CONTROL_PROPERTY_DEBUG_LOCK       = 0x00000004;
    public static final int FD_CONTROL_PROPERTY_RTC              = 0x00000008;
    public static final int FD_CONTROL_PROPERTY_POWER            = 0x00000010;
    public static final int FD_CONTROL_PROPERTY_SITE             = 0x00000020;
    public static final int FD_CONTROL_PROPERTY_RESET            = 0x00000040;
    public static final int FD_CONTROL_PROPERTY_STORAGE          = 0x00000080;
    public static final int FD_CONTROL_PROPERTY_MODE             = 0x00000100;
    public static final int FD_CONTROL_PROPERTY_TX_POWER         = 0x00000200;
    public static final int FD_CONTROL_PROPERTY_BOOT_VERSION     = 0x00000400;
    public static final int FD_CONTROL_PROPERTY_LOGGING          = 0x00000800;
    public static final int FD_CONTROL_PROPERTY_NAME             = 0x00001000;
    public static final int FD_CONTROL_PROPERTY_RETAINED         = 0x00002000;
	public static final int FD_CONTROL_PROPERTY_ADC_VDD          = 0x00004000;
	public static final int FD_CONTROL_PROPERTY_REGULATOR        = 0x00008000;
	public static final int FD_CONTROL_PROPERTY_SENSING_COUNT    = 0x00010000;
	public static final int FD_CONTROL_PROPERTY_INDICATE         = 0x00020000;
	public static final int FD_CONTROL_PROPERTY_RECOGNITION      = 0x00040000;
	public static final int FD_CONTROL_PROPERTY_HARDWARE_VERSION = 0x00080000;

    public static final int FD_CONTROL_PROVISION_OPTION_DEBUG_LOCK = 0x00000001;
    public static final int FD_CONTROL_PROVISION_OPTION_RESET      = 0x00000002;

    public static final byte FD_CONTROL_RESET_SYSTEM_REQUEST = 1;
    public static final byte FD_CONTROL_RESET_WATCHDOG = 2;
    public static final byte FD_CONTROL_RESET_HARD_FAULT = 3;

    public static final int FD_CONTROL_MODE_STORAGE = 1;

	public static final int FD_HAL_SYSTEM_AREA_BOOTLOADER = 0;
	public static final int FD_HAL_SYSTEM_AREA_APPLICATION = 1;
	public static final int FD_HAL_SYSTEM_AREA_OPERATING_SYSTEM = 2;

    public static final int FD_UPDATE_METADATA_FLAG_ENCRYPTED = 0x00000001;

    public static final int FD_UPDATE_COMMIT_SUCCESS = 0;
    public static final int FD_UPDATE_COMMIT_FAIL_HASH_MISMATCH = 1;
    public static final int FD_UPDATE_COMMIT_FAIL_CRYPT_HASH_MISMATCH = 2;
    public static final int FD_UPDATE_COMMIT_FAIL_UNSUPPORTED = 3;

    public enum FDDirectTestModeCommand {
        Reset,
        ReceiverTest,
        TransmitterTest,
        TestEnd
    }

    public enum FDDirectTestModePacketType {
        PRBS9,
        F0,
        AA,
        VendorSpecific
    }

	public interface Command {

		void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary);

	}

	public Map<Number, Command> commandByCode;
    public FDObservable observable;

    public static final int HASH_SIZE = 20;
    public static final int COMMIT_SIZE = 20;
    public static final int CRYPT_IV_SIZE = 16;

	public FDFireflyIceCoder(FDObservable observable) {
		this.observable = observable;

		commandByCode = new HashMap<Number, Command>();
		setCommand(FDFireflyIceCoder.FD_CONTROL_PING, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchPing(fireflyIce, channel, binary);
			}
		});
        setCommand(FDFireflyIceCoder.FD_CONTROL_GET_PROPERTIES, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchGetProperties(fireflyIce, channel, binary);
            }
        });
        setCommand(FDFireflyIceCoder.FD_CONTROL_RTC, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchRTC(fireflyIce, channel, binary);
            }
        });
        setCommand(FDFireflyIceCoder.FD_CONTROL_HARDWARE, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchHardware(fireflyIce, channel, binary);
            }
        });
        setCommand(FDFireflyIceCoder.FD_CONTROL_UPDATE_AREA_GET_VERSION, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchUpdateGetVersion(fireflyIce, channel, binary);
            }
        });
        setCommand(FDFireflyIceCoder.FD_CONTROL_UPDATE_COMMIT, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchUpdateCommit(fireflyIce, channel, binary);
            }
        });
		setCommand(FDFireflyIceCoder.FD_CONTROL_UPDATE_GET_EXTERNAL_HASH, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchExternalHash(fireflyIce, channel, binary);
			}
		});
		setCommand(FDFireflyIceCoder.FD_CONTROL_UPDATE_READ_PAGE, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchUpdateReadPage(fireflyIce, channel, binary);
			}
		});
		setCommand(FDFireflyIceCoder.FD_CONTROL_UPDATE_GET_SECTOR_HASHES, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchUpdateGetSectorHashes(fireflyIce, channel, binary);
			}
		});
		setCommand(FDFireflyIceCoder.FD_CONTROL_LOCK, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchLock(fireflyIce, channel, binary);
			}
		});
		setCommand(FDFireflyIceCoder.FD_CONTROL_SYNC_DATA, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchSyncData(fireflyIce, channel, binary);
			}
		});
		setCommand(FDFireflyIceCoder.FD_CONTROL_DIAGNOSTICS, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchDiagnostics(fireflyIce, channel, binary);
			}
		});
        setCommand(FDFireflyIceCoder.FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT, new Command() {
            public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
                dispatchRadioDirectTestModeReport(fireflyIce, channel, binary);
            }
        });
		setCommand((byte) 0xff, new Command() {
			public void execute(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
				dispatchSensing(fireflyIce, channel, binary);
			}
		});
	}

	public void setCommand(byte code, Command command) {
		commandByCode.put(new Byte(code), command);
	}

    public Command getCommand(byte code) {
        return commandByCode.get(new Byte(code));
    }

	public void sendPing(FDFireflyIceChannel channel, byte[] data) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FDFireflyIceCoder.FD_CONTROL_PING);
		binary.putUInt16((short) data.length);
		binary.putData(FDBinary.toList(data));
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

	void dispatchPing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		int length = binary.getUInt16();
		byte[] pingData = FDBinary.toByteArray(binary.getData(length));

		observable.as(FDFireflyIceObserver.class).fireflyIcePing(fireflyIce, channel, pingData);
	}

    static final byte FD_MAP_TYPE_STRING = 1;

	// binary dictionary format:
	// - uint16_t number of dictionary entries
	// - for each dictionary entry:
	//   - uint8_t length of key
	//   - uint8_t type of value
	//   - uint16_t length of value
	//   - uint16_t offset of key, value bytes
	byte[] dictionaryMap(Map<String, String> dictionary) {
		FDBinary map = new FDBinary();
		List<Byte> content = new ArrayList<Byte>();
		map.putUInt16((short)dictionary.size());
        for (Map.Entry<String, String> entry : dictionary.entrySet()) {
			String key = entry.getKey();
			String value = entry.getValue();
			byte[] keyData = FDBinary.toByteArray(key);
			byte[] valueData = FDBinary.toByteArray(value);
			map.putUInt8((byte)keyData.length);
			map.putUInt8(FD_MAP_TYPE_STRING);
			map.putUInt16((short)valueData.length);
			int offset = content.size();
			map.putUInt16((short)offset);
			content.addAll(FDBinary.toList(keyData));
			content.addAll(FDBinary.toList(valueData));
		}
		map.putData(content);
		return FDBinary.toByteArray(map.dataValue());
	}

	public void sendProvision(FDFireflyIceChannel channel, Map<String, String> dictionary, int options) {
		byte[] data = dictionaryMap(dictionary);
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_PROVISION);
		binary.putUInt32(options);
		binary.putUInt16((short)data.length);
		binary.putData(data);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

	public void sendReset(FDFireflyIceChannel channel, byte type) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_RESET);
		binary.putUInt8(type);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

	public void sendGetProperties(FDFireflyIceChannel channel, int properties) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_GET_PROPERTIES);
		binary.putUInt32(properties);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendDisconnect(FDFireflyIceChannel channel) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_DISCONNECT);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

	void dispatchGetPropertyVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceVersion version = new FDFireflyIceVersion();
		version.major = binary.getUInt16();
		version.minor = binary.getUInt16();
		version.patch = binary.getUInt16();
		version.capabilities = binary.getUInt32();
		version.gitCommit = FDBinary.toByteArray(binary.getData(20));

		observable.as(FDFireflyIceObserver.class).fireflyIceVersion(fireflyIce, channel, version);
	}

	void dispatchGetPropertyBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceVersion version = new FDFireflyIceVersion();
		version.major = binary.getUInt16();
		version.minor = binary.getUInt16();
		version.patch = binary.getUInt16();
		version.capabilities = binary.getUInt32();
		version.gitCommit = FDBinary.toByteArray(binary.getData(20));

		observable.as(FDFireflyIceObserver.class).fireflyIceBootVersion(fireflyIce, channel, version);
	}

	void dispatchGetPropertyHardwareId(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceHardwareId hardwareId = new FDFireflyIceHardwareId();
		hardwareId.vendor = binary.getUInt16();
		hardwareId.product = binary.getUInt16();
		hardwareId.major = binary.getUInt16();
		hardwareId.minor = binary.getUInt16();
		hardwareId.unique = FDBinary.toByteArray(binary.getData(8));

		observable.as(FDFireflyIceObserver.class).fireflyIceHardwareId(fireflyIce, channel, hardwareId);
	}

	void dispatchGetPropertyDebugLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		boolean debugLock = binary.getUInt8() != 0;

		observable.as(FDFireflyIceObserver.class).fireflyIceDebugLock(fireflyIce, channel, debugLock);
	}

	void dispatchGetPropertyRTC(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		double time = binary.getTime64();

		observable.as(FDFireflyIceObserver.class).fireflyIceTime(fireflyIce, channel, time);
	}

	void dispatchGetPropertyPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIcePower power = new FDFireflyIcePower();
		power.batteryLevel = binary.getFloat32();
		power.batteryVoltage = binary.getFloat32();
		power.isUSBPowered = binary.getUInt8() != 0;
		power.isCharging = binary.getUInt8() != 0;
		power.chargeCurrent = binary.getFloat32();
		power.temperature = binary.getFloat32();

		observable.as(FDFireflyIceObserver.class).fireflyIcePower(fireflyIce, channel, power);
	}

	void dispatchGetPropertySite(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		String site = binary.getString16();

		observable.as(FDFireflyIceObserver.class).fireflyIceSite(fireflyIce, channel, site);
	}

	void dispatchGetPropertyReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceReset reset = new FDFireflyIceReset();
		reset.cause = binary.getUInt32();
		reset.date = binary.getTime64();

		observable.as(FDFireflyIceObserver.class).fireflyIceReset(fireflyIce, channel, reset);
	}

	void dispatchGetPropertyStorage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceStorage storage = new FDFireflyIceStorage();
		storage.pageCount = binary.getUInt32();

		observable.as(FDFireflyIceObserver.class).fireflyIceStorage(fireflyIce, channel, storage);
	}

	void dispatchGetPropertyMode(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		byte mode = binary.getUInt8();

		observable.as(FDFireflyIceObserver.class).fireflyIceMode(fireflyIce, channel, mode);
	}

	void dispatchGetPropertyTxPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		byte txPower = binary.getUInt8();

		observable.as(FDFireflyIceObserver.class).fireflyIceTxPower(fireflyIce, channel, txPower);
	}

    void dispatchGetPropertyRegulator(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        Byte regulator = new Byte(binary.getUInt8());

        observable.as(FDFireflyIceObserver.class).fireflyIceRegulator(fireflyIce, channel, regulator);
    }

    void dispatchGetPropertySensingCount(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        Integer sensingCount = new Integer(binary.getUInt32());

        observable.as(FDFireflyIceObserver.class).fireflyIceSensingCount(fireflyIce, channel, sensingCount);
    }

    void dispatchGetPropertyIndicate(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        Boolean indicate = new Boolean(binary.getUInt8() != 0);

        observable.as(FDFireflyIceObserver.class).fireflyIceIndicate(fireflyIce, channel, indicate);
    }

    void dispatchGetPropertyRecognition(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        Boolean recognition = new Boolean(binary.getUInt8() != 0);

        observable.as(FDFireflyIceObserver.class).fireflyIceRecognition(fireflyIce, channel, recognition);
    }

    void dispatchGetPropertyHardwareVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        FDFireflyIceHardwareVersion version = new FDFireflyIceHardwareVersion();
        version.major = binary.getUInt16();
        version.minor = binary.getUInt16();

        observable.as(FDFireflyIceObserver.class).fireflyIceHardwareVersion(fireflyIce, channel, version);
    }

    void dispatchGetPropertyLogging(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceLogging logging = new FDFireflyIceLogging();
		logging.flags = binary.getUInt32();
		if ((logging.flags & FD_CONTROL_LOGGING_STATE) != 0) {
			logging.state = binary.getUInt32();
		}
		if ((logging.flags & FD_CONTROL_LOGGING_COUNT) != 0) {
			logging.count = binary.getUInt32();
		}

		observable.as(FDFireflyIceObserver.class).fireflyIceLogging(fireflyIce, channel, logging);
	}

	void dispatchGetPropertyName(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		String name = binary.getString8();

		observable.as(FDFireflyIceObserver.class).fireflyIceName(fireflyIce, channel, name);
	}

	void dispatchGetPropertyRetained(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceRetained retained = new FDFireflyIceRetained();
		retained.retained = binary.getUInt8() != 0;
		int length = binary.getUInt32();
		retained.data = FDBinary.toByteArray(binary.getData(length));

		observable.as(FDFireflyIceObserver.class).fireflyIceRetained(fireflyIce, channel, retained);
	}

	void dispatchGetProperties(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary)
	{
		int properties = binary.getUInt32();
		if ((properties & FD_CONTROL_PROPERTY_VERSION) != 0) {
			dispatchGetPropertyVersion(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_HARDWARE_ID) != 0) {
			dispatchGetPropertyHardwareId(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_DEBUG_LOCK) != 0) {
			dispatchGetPropertyDebugLock(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_RTC) != 0) {
			dispatchGetPropertyRTC(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_POWER) != 0) {
			dispatchGetPropertyPower(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_SITE) != 0) {
			dispatchGetPropertySite(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_RESET) != 0) {
			dispatchGetPropertyReset(fireflyIce, channel, binary);
        }
        if ((properties & FD_CONTROL_PROPERTY_STORAGE) != 0) {
			dispatchGetPropertyStorage(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_MODE) != 0) {
			dispatchGetPropertyMode(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_TX_POWER) != 0) {
			dispatchGetPropertyTxPower(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_BOOT_VERSION) != 0) {
			dispatchGetPropertyBootVersion(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_LOGGING) != 0) {
			dispatchGetPropertyLogging(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_NAME) != 0) {
			dispatchGetPropertyName(fireflyIce, channel, binary);
		}
		if ((properties & FD_CONTROL_PROPERTY_RETAINED) != 0) {
			dispatchGetPropertyRetained(fireflyIce, channel, binary);
		}
        if ((properties & FD_CONTROL_PROPERTY_REGULATOR) != 0) {
            dispatchGetPropertyRegulator(fireflyIce, channel, binary);
        }
        if ((properties & FD_CONTROL_PROPERTY_SENSING_COUNT) != 0) {
            dispatchGetPropertySensingCount(fireflyIce, channel, binary);
        }
        if ((properties & FD_CONTROL_PROPERTY_INDICATE) != 0) {
            dispatchGetPropertyIndicate(fireflyIce, channel, binary);
        }
        if ((properties & FD_CONTROL_PROPERTY_RECOGNITION) != 0) {
            dispatchGetPropertyRecognition(fireflyIce, channel, binary);
        }
        if ((properties & FD_CONTROL_PROPERTY_HARDWARE_VERSION) != 0) {
            dispatchGetPropertyHardwareVersion(fireflyIce, channel, binary);
        }
	}

	public void sendSetPropertyTime(FDFireflyIceChannel channel, double time) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_RTC);
		binary.putTime64(time);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyMode(FDFireflyIceChannel channel, byte mode) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_MODE);
		binary.putUInt8(mode);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyTxPower(FDFireflyIceChannel channel, byte txPower) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_TX_POWER);
		binary.putUInt8(txPower);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyLogging(FDFireflyIceChannel channel, boolean storage) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_LOGGING);
		binary.putUInt32(FD_CONTROL_LOGGING_STATE);
		binary.putUInt32(FD_CONTROL_LOGGING_STORAGE);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyName(FDFireflyIceChannel channel, String name) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
        binary.putUInt32(FD_CONTROL_PROPERTY_NAME);
        binary.putString8(name);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyIndicate(FDFireflyIceChannel channel, boolean indicate) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
		binary.putUInt32(FD_CONTROL_PROPERTY_INDICATE);
		binary.putUInt8(indicate ? (byte)1 : (byte)0);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSetPropertyRegulator(FDFireflyIceChannel channel, byte regulator) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
        binary.putUInt32(FD_CONTROL_PROPERTY_REGULATOR);
        binary.putUInt8(regulator);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    public void sendSetPropertySensingCount(FDFireflyIceChannel channel, int count) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
        binary.putUInt32(FD_CONTROL_PROPERTY_SENSING_COUNT);
        binary.putUInt32(count);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    public void sendSetPropertyRecognition(FDFireflyIceChannel channel, boolean recognition) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_SET_PROPERTIES);
        binary.putUInt32(FD_CONTROL_PROPERTY_RECOGNITION);
        binary.putUInt8((byte)(recognition ? 1 : 0));
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    public void sendSetRTC(FDFireflyIceChannel channel, Date date, TimeZone timeZone) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_RTC);
        binary.putUInt32(FD_CONTROL_RTC_FLAG_SET_TIME | FD_CONTROL_RTC_FLAG_SET_UTC_OFFSET);
        double time = date.getTime() / 1000.0;
        binary.putTime64(time);
        int utc_offset = timeZone.getOffset(date.getTime()) / 1000;
        binary.putUInt32(utc_offset);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    public void sendGetRTC(FDFireflyIceChannel channel) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_RTC);
        binary.putUInt32(FD_CONTROL_RTC_FLAG_GET_TIME | FD_CONTROL_RTC_FLAG_GET_UTC_OFFSET);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    public void dispatchRTC(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        int flags = binary.getUInt32();
        Map<String, Object> map = new HashMap<String, Object>();
        if ((flags & FD_CONTROL_RTC_FLAG_GET_TIME) != 0) {
            double time = binary.getTime64();
            map.put("date", new Date((long)(time * 1000L)));
        }
        if ((flags & FD_CONTROL_RTC_FLAG_GET_UTC_OFFSET) != 0) {
            int utcOffset = binary.getUInt32();
            map.put("timeZone", new SimpleTimeZone(utcOffset, "+" + utcOffset));
        }

        observable.as(FDFireflyIceObserver.class).fireflyIceRTC(fireflyIce, channel, map);
    }

    public void sendGetHardware(FDFireflyIceChannel channel, int flags) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_HARDWARE);
        binary.putUInt32(flags);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    void dispatchHardware(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        int flags = binary.getUInt32();
        Map<String, Object> map = new HashMap<String, Object>();
        if ((flags & FD_CONTROL_HARDWARE_FLAG_GET_UNIQUE) != 0) {
            int length = binary.getUInt8() & 0xff;
            List<Byte> unique = binary.getData(length);
            map.put("unique", unique);
        }
        if ((flags & FD_CONTROL_HARDWARE_FLAG_GET_USB) != 0) {
            short vendor = binary.getUInt16();
            short product = binary.getUInt16();
            map.put("USB vendor id", new Short(vendor));
            map.put("USB product id", new Short(product));
        }
        if ((flags & FD_CONTROL_HARDWARE_FLAG_GET_BLE) != 0) {
            int length = binary.getUInt8() & 0xff;
            List<Byte> primaryServiceUUID = binary.getData(length);
            map.put("BLE primaryServiceUUID", primaryServiceUUID);
        }

        observable.as(FDFireflyIceObserver.class).fireflyIceHardware(fireflyIce, channel, map);
    }

    public void sendUpdateGetVersion(FDFireflyIceChannel channel, byte area) {
        FDBinary binary = new FDBinary();
        binary.putUInt8(FD_CONTROL_UPDATE_AREA_GET_VERSION);
        binary.putUInt8(area);
        channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
    }

    void dispatchUpdateGetVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
        FDFireflyIceUpdateVersion version = new FDFireflyIceUpdateVersion();
        int flags = binary.getUInt32();
        if ((flags & FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_REVISION) != 0) {
            FDFireflyIceVersion revision = new FDFireflyIceVersion();
            revision.major = binary.getUInt16();
            revision.minor = binary.getUInt16();
            revision.patch = binary.getUInt16();
            revision.capabilities = binary.getUInt32();
            revision.gitCommit = FDBinary.toByteArray(binary.getData(COMMIT_SIZE));
            version.revision = revision;
        }
        if ((flags & FD_CONTROL_UPDATE_AREA_GET_VERSION_FLAG_METADATA) != 0) {
            FDFireflyIceUpdateMetadata metadata = new FDFireflyIceUpdateMetadata();
            metadata.binary = new FDFireflyIceUpdateBinary();
            metadata.binary.flags = binary.getUInt32();
            metadata.binary.length = binary.getUInt32();
            metadata.binary.clearHash = FDBinary.toByteArray(binary.getData(HASH_SIZE));
            metadata.binary.cryptHash = FDBinary.toByteArray(binary.getData(HASH_SIZE));
            metadata.binary.cryptIV = FDBinary.toByteArray(binary.getData(CRYPT_IV_SIZE));
            metadata.revision = new FDFireflyIceVersion();
            metadata.revision.major = binary.getUInt16();
            metadata.revision.minor = binary.getUInt16();
            metadata.revision.patch = binary.getUInt16();
            metadata.revision.capabilities = binary.getUInt32();
            metadata.revision.gitCommit = FDBinary.toByteArray(binary.getData(COMMIT_SIZE));
            version.metadata = metadata;
        }

        observable.as(FDFireflyIceObserver.class).fireflyIceUpdateVersion(fireflyIce, channel, version);
    }

    public void sendUpdateGetExternalHash(FDFireflyIceChannel channel, byte area, int address, int length) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_GET_EXTERNAL_HASH);
        binary.putUInt8(area);
		binary.putUInt32(address);
		binary.putUInt32(length);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendUpdateReadPage(FDFireflyIceChannel channel, byte area, int page) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_READ_PAGE);
        binary.putUInt8(area);
		binary.putUInt32(page);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendUpdateGetSectorHashes(FDFireflyIceChannel channel, byte area, List<Short> sectors) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_GET_SECTOR_HASHES);
        binary.putUInt8(area);
		binary.putUInt8((byte)sectors.size());
		for (Short sector : sectors) {
			binary.putUInt16(sector);
		}
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendUpdateEraseSectors(FDFireflyIceChannel channel, byte area, List<Short> sectors) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_ERASE_SECTORS);
        binary.putUInt8(area);
		binary.putUInt8((byte)sectors.size());
		for (Short sector : sectors) {
			binary.putUInt16(sector);
		}
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendUpdateWritePage(FDFireflyIceChannel channel, byte area, short page, byte[] data) {
		// !!! assert that data.length == page size -denis
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_WRITE_PAGE);
        binary.putUInt8(area);
		binary.putUInt16(page);
		binary.putData(data);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendUpdateCommit(FDFireflyIceChannel channel, byte area, int flags, int length, byte[] hash, byte[] cryptHash, byte[] cryptIv, short major, short minor, short patch, int capabilities, byte[] commit) {
		// !!! assert that data lengths are correct -denis
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_UPDATE_AREA_COMMIT);
        binary.putUInt8(area);
		binary.putUInt32(flags);
		binary.putUInt32(length);
		binary.putData(hash); // 20 bytes
		binary.putData(cryptHash); // 20 bytes
		binary.putData(cryptIv); // 16 bytes
        binary.putUInt16(major);
        binary.putUInt16(minor);
        binary.putUInt16(patch);
        binary.putUInt32(capabilities);
        binary.putData(commit); // 20 bytes
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public static short makeDirectTestModePacket(FDDirectTestModeCommand command, int frequency, int length, FDDirectTestModePacketType type) {
		return (short)((command.ordinal() << 14) | ((frequency & 0x3f) << 8) | ((length & 0x3f) << 2) | type.ordinal());
	}

    public void sendDirectTestModeEnter(FDFireflyIceChannel channel, short packet, double duration) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_ENTER);
		binary.putUInt16(packet);
		binary.putTime64(duration);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendDirectTestModeExit(FDFireflyIceChannel channel) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_EXIT);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendDirectTestModeReport(FDFireflyIceChannel channel) {
        FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_RADIO_DIRECT_TEST_MODE_REPORT);
		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendDirectTestModeReset(FDFireflyIceChannel channel) {
		sendDirectTestModeEnter(channel, makeDirectTestModePacket(FDDirectTestModeCommand.Reset, 0, 0, FDDirectTestModePacketType.PRBS9), 0);
	}

    public void sendDirectTestModeReceiverTest(FDFireflyIceChannel channel, byte frequency, byte length, FDDirectTestModePacketType type, double duration) {
		sendDirectTestModeEnter(channel, makeDirectTestModePacket(FDDirectTestModeCommand.ReceiverTest, frequency, length, type), duration);
	}

    public void sendDirectTestModeTransmitterTest(FDFireflyIceChannel channel, byte frequency, byte length, FDDirectTestModePacketType type, double duration) {
		sendDirectTestModeEnter(channel, makeDirectTestModePacket(FDDirectTestModeCommand.TransmitterTest, frequency, length, type), duration);
	}

    public void sendDirectTestModeEnd(FDFireflyIceChannel channel) {
		sendDirectTestModeEnter(channel, makeDirectTestModePacket(FDDirectTestModeCommand.TestEnd, 0, 0, FDDirectTestModePacketType.PRBS9), 0);
	}

	void dispatchUpdateCommit(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceUpdateCommit updateCommit = new FDFireflyIceUpdateCommit();
		updateCommit.result = binary.getUInt8();

		observable.as(FDFireflyIceObserver.class).fireflyIceUpdateCommit(fireflyIce, channel, updateCommit);
	}

	void dispatchRadioDirectTestModeReport(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceDirectTestModeReport report = new FDFireflyIceDirectTestModeReport();
		report.packetCount = binary.getUInt16();

		observable.as(FDFireflyIceObserver.class).fireflyIceDirectTestModeReport(fireflyIce, channel, report);
	}

	void dispatchUpdateGetSectorHashes(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		int sectorCount = binary.getUInt8();
		List<FDFireflyIceSectorHash> sectorHashes = new ArrayList<FDFireflyIceSectorHash>();
		for (int i = 0; i < sectorCount; ++i) {
			short sector = binary.getUInt16();
			byte[] hash = binary.getDataArray(HASH_SIZE);
			FDFireflyIceSectorHash sectorHash = new FDFireflyIceSectorHash();
			sectorHash.sector = sector;
			sectorHash.hash = hash;
			sectorHashes.add(sectorHash);
		}

		observable.as(FDFireflyIceObserver.class).fireflyIceSectorHashes(fireflyIce, channel, sectorHashes.toArray(new FDFireflyIceSectorHash[0]));
	}

	void dispatchExternalHash(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		byte[] externalHash = binary.getDataArray(HASH_SIZE);

		observable.as(FDFireflyIceObserver.class).fireflyIceExternalHash(fireflyIce, channel, externalHash);
	}

	void dispatchUpdateReadPage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		byte[] pageData = binary.getDataArray(256);

		observable.as(FDFireflyIceObserver.class).fireflyIcePageData(fireflyIce, channel, pageData);
	}

	static void putColor(FDBinary binary, int color) {
		binary.putUInt8((byte)(color >> 16));
		binary.putUInt8((byte)(color >> 8));
		binary.putUInt8((byte)color);
	}

    public void sendLEDOverride(FDFireflyIceChannel channel, byte usbOrange, byte usbGreen, byte d0, byte d1, byte d2, byte d3, byte d4, double duration) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_LED_OVERRIDE);

		binary.putUInt8(usbOrange);
		binary.putUInt8(usbGreen);
		binary.putUInt8(d0);
		putColor(binary, d1);
		putColor(binary, d2);
		putColor(binary, d3);
		binary.putUInt8(d4);
		binary.putTime64(duration);

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendIdentify(FDFireflyIceChannel channel, double duration) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_IDENTIFY);
		binary.putUInt8((byte)1);
		binary.putTime64(duration);

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendLock(FDFireflyIceChannel channel, FDFireflyIceLock.Identifier identifier, FDFireflyIceLock.Operation operation) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_LOCK);
		binary.putUInt8((byte)identifier.ordinal());
		binary.putUInt8((byte)operation.ordinal());

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSyncStart(FDFireflyIceChannel channel) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SYNC_START);

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendSyncStart(FDFireflyIceChannel channel, int offset) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_SYNC_START);
		binary.putUInt32(FD_CONTROL_SYNC_AHEAD);
		binary.putUInt32(offset);

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

    public void sendDiagnostics(FDFireflyIceChannel channel, int flags) {
		FDBinary binary = new FDBinary();
		binary.putUInt8(FD_CONTROL_DIAGNOSTICS);
		binary.putUInt32(flags);

		channel.fireflyIceChannelSend(FDBinary.toByteArray(binary.dataValue()));
	}

	void dispatchDiagnostics(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceDiagnostics diagnostics = new FDFireflyIceDiagnostics();
		diagnostics.flags = binary.getUInt32();
		List<FDFireflyIceDiagnosticsBLE> values = new ArrayList<FDFireflyIceDiagnosticsBLE>();
		if ((diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE) != 0) {
			FDFireflyIceDiagnosticsBLE value = new FDFireflyIceDiagnosticsBLE();
			int length = binary.getUInt32();
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
			binary.getIndex = position + length;
			values.add(value);
		}
		if ((diagnostics.flags & FD_CONTROL_DIAGNOSTICS_BLE_TIMING) != 0) {
			short connectionInterval = binary.getUInt16();
            short slaveLatency = binary.getUInt16();
            short supervisionTimeout = binary.getUInt16();
// !!!			FDFireflyDeviceLogInfo("BLE timing: %d %d %d", connectionInterval, slaveLatency, supervisionTimeout);
		}
		diagnostics.values = values.toArray(new FDFireflyIceDiagnosticsBLE[0]);
		observable.as(FDFireflyIceObserver.class).fireflyIceDiagnostics(fireflyIce, channel, diagnostics);
	}

	void dispatchLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceLock lock = new FDFireflyIceLock();
		lock.identifier = FDFireflyIceLock.Identifier.values()[binary.getUInt8()];
		lock.operation = FDFireflyIceLock.Operation.values()[binary.getUInt8()];
		lock.owner = new FDFireflyIceLock.Owner(binary.getUInt32());

		observable.as(FDFireflyIceObserver.class).fireflyIceLock(fireflyIce, channel, lock);
	}

	void dispatchSyncData(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		observable.as(FDFireflyIceObserver.class).fireflyIceSync(fireflyIce, channel, binary.getRemainingDataArray());
	}

	void dispatchSensing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDBinary binary) {
		FDFireflyIceSensing sensing = new FDFireflyIceSensing();
		sensing.ax = binary.getFloat32();
		sensing.ay = binary.getFloat32();
		sensing.az = binary.getFloat32();
		sensing.mx = binary.getFloat32();
		sensing.my = binary.getFloat32();
		sensing.mz = binary.getFloat32();

		observable.as(FDFireflyIceObserver.class).fireflyIceSensing(fireflyIce, channel, sensing);
	}

	public void fireflyIceChannelPacket(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {
		FDBinary binary = new FDBinary(data);
		byte code = binary.getUInt8();
		Command command = commandByCode.get(new Byte(code));
		if (command != null) {
			command.execute(fireflyIce, channel, binary);
		}
	}

}
