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

	public void read(String content, int address, int length) {
        properties = new HashMap<String, String>();
		ArrayList<Byte> firmware = new ArrayList<Byte>();
		int extendedAddress = 0;
		boolean done = false;
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
			    case 0: { // Data Record
                    int dataAddress = extendedAddress + recordAddress;
                    int firmwareLength = dataAddress + (int)data.size();
                    while (firmwareLength > firmware.size()) {
                        firmware.add(Byte.MAX_VALUE);
                    }
                    for (int i = 0; i < data.size(); ++i) {
                        firmware.set(dataAddress + i, data.get(i));
                    }
			    } break;
			    case 1: { // End Of File Record
					done = true;
			    } break;
			    case 2: { // Extended Segment Address Record
					extendedAddress = ((data.get(0) << 8) | data.get(1)) << 4;
			    } break;
			    case 3: { // Start Segment Address Record
					// ignore
			    } break;
			    case 4: { // Extended Linear Address Record
					// ignore
			    } break;
			    case 5: { // Start Linear Address Record
					// ignore
			    } break;
			}
		}
		data = FDBinary.toByteArray(firmware.subList(address, firmware.size()));
	}

}
