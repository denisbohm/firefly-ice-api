//
//  FDBinary.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class FDBinary {

    List<Byte> buffer;
    int getIndex;

    public static byte[] toByteArray(List<Byte> list) {
        byte[] array = new byte[list.size()];
        for (int i = 0; i < list.size(); ++i) {
            array[i] = list.get(i);
        }
        return array;
    }

    public static List<Byte> toList(byte[] array) {
        List<Byte> list = new ArrayList<Byte>(array.length);
        for (int i = 0; i < array.length; ++i) {
            list.add(array[i]);
        }
        return list;
    }

    public static byte[] toByteArray(String string) {
        try {
            return string.getBytes("UTF8");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

    public static String toHexString(byte[] array) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < array.length; ++i) {
            if (i > 0) {
                builder.append(", ");
            }
            builder.append(String.format("%02x", array[i]));
        }
        return builder.toString();
    }

    public static String toString(byte[] bytes) {
        try {
            return new String(bytes, "UTF-8");
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        }
    }

    public static byte unpackUInt8(List<Byte> buffer) {
		return buffer.get(0);
	}

    public static short unpackUInt16(List<Byte> buffer) {
		return (short)(((buffer.get(1) & 0xff) << 8) | (buffer.get(0) & 0xff));
	}

    public static int unpackUInt24(List<Byte> buffer) {
        return ((buffer.get(2) & 0xff) << 16) | ((buffer.get(1) & 0xff) << 8) | (buffer.get(0) & 0xff);
    }

    public static int unpackUInt32(List<Byte> buffer) {
        return ((buffer.get(3) & 0xff) << 24) | ((buffer.get(2) & 0xff) << 16) | ((buffer.get(1) & 0xff) << 8) | (buffer.get(0) & 0xff);
    }

    public static long unpackUInt64(List<Byte> buffer) {
		long lo = unpackUInt32(buffer);
		long hi = unpackUInt32(buffer.subList(4, 8));
		return (hi << 32) | lo;
	}

    public static float unpackFloat16(List<Byte> buffer) {
		short bits = unpackUInt16(buffer);
		return FDIEEE754.uint16ToFloat(bits);
	}

    public static float unpackFloat32(List<Byte> buffer) {
		int bits = unpackUInt32(buffer);
		return FDIEEE754.uint32ToFloat(bits);
	}

    public static double unpackTime64(List<Byte> buffer) {
		int seconds = unpackUInt32(buffer);
		int microseconds = unpackUInt32(buffer.subList(4, 8));
		return seconds + microseconds * 1e-6;
	}

    public static void packUInt8(List<Byte> buffer, byte value) {
		buffer.set(0, value);
	}

    public static void packUInt16(List<Byte> buffer, short value) {
		buffer.set(0, (byte)(value));
		buffer.set(1, (byte)(value >> 8));
	}

    public static void packUInt24(List<Byte> buffer, int value) {
        buffer.set(0, (byte)(value));
        buffer.set(1, (byte)(value >> 8));
        buffer.set(2, (byte)(value >> 16));
    }

    public static void packUInt32(List<Byte> buffer, int value) {
        buffer.set(0, (byte)(value));
        buffer.set(1, (byte)(value >> 8));
        buffer.set(2, (byte)(value >> 16));
        buffer.set(3, (byte)(value >> 24));
    }

    public static void packUInt64(List<Byte> buffer, long value) {
	    packUInt32(buffer, (int) value);
	    packUInt32(buffer.subList(4, 8), (int) (value >> 32));
	}

    public static void packFloat16(List<Byte> buffer, float value) {
		short bits = FDIEEE754.floatToUint16(value);
	    packUInt16(buffer, bits);
	}

    public static void packFloat32(List<Byte> buffer, float value) {
        int bits = FDIEEE754.floatToUint32(value);
	    packUInt32(buffer, bits);
	}

    public static void packTime64(List<Byte> buffer, double value) {
		int seconds = (int)value;
		int microseconds = (int)((value - seconds) * 1e6);
	    packUInt32(buffer, seconds);
	    packUInt32(buffer.subList(4, 8), microseconds);
	}

    public FDBinary() {
		buffer = new ArrayList<Byte>();
		getIndex = 0;
	}

    public FDBinary(List<Byte> data) {
        buffer = data;
        getIndex = 0;
    }

    public FDBinary(byte[] data) {
        buffer = FDBinary.toList(data);
        getIndex = 0;
    }

    public int length() {
		return buffer.size();
	}

    public List<Byte> dataValue() {
		return buffer;
	}

    public int getRemainingLength() {
		return buffer.size() - getIndex;
	}

    public List<Byte> getRemainingData() {
        return buffer.subList(getIndex, buffer.size());
    }

    public byte[] getRemainingDataArray() {
        return FDBinary.toByteArray(getRemainingData());
    }

    public void checkGet(int amount) {
		if ((buffer.size() - getIndex) < amount) {
			throw new RuntimeException("index out of bounds");
		}
	}

    public List<Byte> getData(int length) {
		checkGet(length);
		List<Byte> data = buffer.subList(getIndex, getIndex + length);
		getIndex += length;
		return data;
	}

    public byte[] getDataArray(int length) {
        return FDBinary.toByteArray(getData(length));
    }

    public String getString8() {
        int length = getUInt8() & 0xff;
        return FDBinary.toString(getDataArray(length));
    }

    public String getString16() {
        int length = getUInt16() & 0xffff;
        return FDBinary.toString(getDataArray(length));
    }

    public byte getUInt8() {
		checkGet(1);
		List<Byte> p = buffer.subList(getIndex, getIndex + 1);
		getIndex += 1;
		return unpackUInt8(p);
	}

    public short getUInt16() {
		checkGet(2);
		List<Byte> p = buffer.subList(getIndex, getIndex + 2);
		getIndex += 2;
		return unpackUInt16(p);
	}

    public int getUInt24() {
        checkGet(3);
        List<Byte> p = buffer.subList(getIndex, getIndex + 3);
        getIndex += 3;
        return unpackUInt24(p);
    }

    public int getUInt32() {
        checkGet(4);
        List<Byte> p = buffer.subList(getIndex, getIndex + 4);
        getIndex += 4;
        return unpackUInt32(p);
    }

    public long getUInt64() {
		checkGet(8);
		List<Byte> p = buffer.subList(getIndex, getIndex + 8);
		getIndex += 8;
		return unpackUInt64(p);
	}

    public float getFloat16() {
		checkGet(2);
		List<Byte> p = buffer.subList(getIndex, getIndex + 2);
		getIndex += 2;
		return unpackFloat16(p);
	}

    public float getFloat32() {
		checkGet(4);
		List<Byte> p = buffer.subList(getIndex, getIndex + 4);
		getIndex += 4;
		return unpackFloat32(p);
	}

    public double getTime64() {
		checkGet(8);
		List<Byte> p = buffer.subList(getIndex, getIndex + 8);
		getIndex += 8;
		return unpackTime64(p);
	}

    public void putData(List<Byte> data) {
        buffer.addAll(data);
    }

    public void putData(byte[] data) {
        buffer.addAll(FDBinary.toList(data));
    }

    public void putString8(String string) {
        byte[] bytes = FDBinary.toByteArray(string);
        putUInt8((byte)bytes.length);
        putData(bytes);
    }

    public void putString16(String string) {
        byte[] bytes = FDBinary.toByteArray(string);
        putUInt16((short) bytes.length);
        putData(bytes);
    }

    public void putUInt8(byte value) {
		Byte bytes[] = { value };
		buffer.addAll(Arrays.asList(bytes));
	}

    public void putUInt16(short value) {
		Byte bytes[] = { (byte)(value), (byte)(value >> 8) };
        buffer.addAll(Arrays.asList(bytes));
	}

    public void putUInt24(int value) {
        Byte bytes[] = { (byte)(value), (byte)(value >> 8), (byte)(value >> 16) };
        buffer.addAll(Arrays.asList(bytes));
    }

    public void putUInt32(int value) {
        Byte bytes[] = { (byte)(value), (byte)(value >> 8), (byte)(value >> 16), (byte)(value >> 24) };
        buffer.addAll(Arrays.asList(bytes));
    }

    public void putUInt64(long value) {
		Byte bytes[] = { (byte)(value), (byte)(value >> 8), (byte)(value >> 16), (byte)(value >> 24), (byte)(value >> 32), (byte)(value >> 40), (byte)(value >> 48), (byte)(value >> 56) };
        buffer.addAll(Arrays.asList(bytes));
	}

    public void putFloat16(float value) {
		short bits = FDIEEE754.floatToUint16(value);
		putUInt16(bits);
	}

    public void putFloat32(float value) {
        int bits = FDIEEE754.floatToUint32(value);
        putUInt32(bits);
	}

    public void putTime64(double value) {
		int seconds = (int)value;
		int microseconds = (int)((value - seconds) * 1e6);
		putUInt32(seconds);
		putUInt32(microseconds);
	}

}
