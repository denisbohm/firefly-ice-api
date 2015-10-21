//
//  FDIntelHex.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/18/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

public class FDIntelHex {

    public byte[] data;
    public Map<String, String> properties;

    public static FDIntelHex intelHex(String hex, int address, int length) {
		FDIntelHex intelHex = new FDIntelHex();
		intelHex.read(hex, address, length);
		return intelHex;
	}

	public static byte[] parse(String hex, int address, int length) {
		return intelHex(hex, address, length).data;
	}

    int index;
    int crc;

	int hex(String line, int length) {
		String string = line.substring(index, index + length);
		index += length;
		int value = Integer.parseInt(string, 16);
		if (length == 2) {
			crc += value;
		} else
		if (length == 4) {
			crc += (value >> 8);
			crc += value & 0xff;
		}
		return value;
	}

	int getHexProperty(String key, int fallback) {
		String object = properties.get(key);
		if (object != null) {
			return FDString.parseInt(object);
		}
		return fallback;
	}

    final static int TypeDataRecord                   = 0;
    final static int TypeEndOfFileRecord              = 1;
    final static int TypeExtendedSegmentAddressRecord = 2;
    final static int TypeStartSegmentAddressRecord    = 3;
    final static int TypeExtendedLinearAddressRecord  = 4;
    final static int TypeStartLinearAddressRecord     = 5;

    public void read(String content, int address, int length) {
        properties = new HashMap<String, String>();
		String[] lines = content.split("\\r?\\n");
		for (String line : lines) {
			if (!line.startsWith(":")) {
				if (line.startsWith("#! ")) {
					try {
						JSONObject object = (JSONObject) new JSONTokener(line.substring(2)).nextValue();
						for (Iterator<String> i = object.keys(); i.hasNext(); ) {
							String key = i.next();
							Object value = object.get(key);
							properties.put(key, value.toString());
						}
					} catch (JSONException e) {
						throw new RuntimeException(e);
					}
				}
				continue;
			}
		}

		address = getHexProperty("address", address);
		length = getHexProperty("length", length);

		ArrayList<Byte> firmware = new ArrayList<Byte>();
		int extendedAddress = 0;
		boolean done = false;
		for (String line : lines) {
            if (!line.startsWith(":")) {
                continue;
            }
			if (done) {
				continue;
			}
			index = 1;
			crc = 0;
			int byteCount = hex(line, 2);
			int recordAddress = hex(line, 4);
			int recordType = hex(line, 2);
			List<Byte> data = new ArrayList<Byte>();
			for (int i = 0; i < byteCount; ++i) {
				byte b = (byte)hex(line, 2);
				data.add(b);
			}
            byte finalCrc = (byte)(256 - crc);
			byte checksum = (byte)hex(line, 2);
			if (checksum != finalCrc) {
				throw new RuntimeException("checksum mismatch");
			}
			switch (recordType) {
			    case TypeDataRecord: {
                    int targetAddress = extendedAddress + recordAddress;
                    if (targetAddress >= address) {
                        int dataAddress = targetAddress - address;
                        int dataLength = dataAddress + (int) data.size();
                        while (dataLength > firmware.size()) {
                            firmware.add(Byte.MAX_VALUE);
                        }
                        for (int i = 0; i < data.size(); ++i) {
                            firmware.set(dataAddress + i, data.get(i));
                        }
                    }
			    } break;
			    case TypeEndOfFileRecord: {
					done = true;
			    } break;
			    case TypeExtendedSegmentAddressRecord: {
					extendedAddress = ((data.get(0) << 8) | data.get(1)) << 4;
			    } break;
			    case TypeStartSegmentAddressRecord: {
					// ignore
			    } break;
			    case TypeExtendedLinearAddressRecord: {
                    extendedAddress = (data.get(0) << 24) | (data.get(1) << 16);
			    } break;
			    case TypeStartLinearAddressRecord: {
					// ignore
			    } break;
			}
		}
		data = FDBinary.toByteArray(firmware);
	}

}
