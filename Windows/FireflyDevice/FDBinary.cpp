//
//  FDBinary.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDBinary.h"
#include "FDIEEE754.h"

namespace fireflydesign {

	uint8_t FDBinary::unpackUInt8(uint8_t *buffer) {
		return buffer[0];
	}

	uint16_t FDBinary::unpackUInt16(uint8_t *buffer) {
		return (buffer[1] << 8) | buffer[0];
	}

	uint32_t FDBinary::unpackUInt32(uint8_t *buffer) {
		return (buffer[3] << 24) | (buffer[2] << 16) | (buffer[1] << 8) | buffer[0];
	}

	uint64_t FDBinary::unpackUInt64(uint8_t *buffer) {
		uint64_t lo = FDBinary::unpackUInt32(buffer);
		uint64_t hi = FDBinary::unpackUInt32(&buffer[8]);
		return (hi << 32) | lo;
	}

	float FDBinary::unpackFloat16(uint8_t *buffer) {
		uint16_t bits = FDBinary::unpackUInt16(buffer);
		return FDIEEE754::uint16ToFloat(bits);
	}

	typedef union {
		uint32_t asUint32;
		float asFloat32;
	} fd_int32_float32_t;

	float FDBinary::unpackFloat32(uint8_t *buffer) {
		fd_int32_float32_t u;
		u.asUint32 = FDBinary::unpackUInt32(buffer);
		return u.asFloat32;
	}

	FDBinary::time_type FDBinary::unpackTime64(uint8_t *buffer) {
		uint32_t seconds = FDBinary::unpackUInt32(buffer);
		uint32_t microseconds = FDBinary::unpackUInt32(&buffer[4]);
		return seconds + microseconds * 1e-6;
	}

	void FDBinary::packUInt8(uint8_t *buffer, uint8_t value) {
		buffer[0] = value;
	}

	void FDBinary::packUInt16(uint8_t *buffer, uint16_t value) {
		buffer[0] = uint8_t(value);
		buffer[1] = uint8_t(value >> 8);
	}

	void FDBinary::packUInt32(uint8_t *buffer, uint32_t value) {
		buffer[0] = value;
		buffer[1] = value >> 8;
		buffer[2] = value >> 16;
		buffer[3] = value >> 24;
	}

	void FDBinary::packUInt64(uint8_t *buffer, uint64_t value) {
	    FDBinary::packUInt32(buffer, (uint32_t)value);
	    FDBinary::packUInt32(&buffer[4], (uint32_t)(value >> 32));
	}

	void FDBinary::packFloat16(uint8_t *buffer, float value) {
		uint16_t bits = FDIEEE754::floatToUint16(value);
	    FDBinary::packUInt16(buffer, bits);
	}

	void FDBinary::packFloat32(uint8_t *buffer, float value) {
		fd_int32_float32_t u;
		u.asFloat32 = value;
	    FDBinary::packUInt32(buffer, u.asUint32);
	}

	void FDBinary::packTime64(uint8_t *buffer, time_type value) {
		uint32_t seconds = (uint32_t)value;
		uint32_t microseconds = (uint32_t)((value - seconds) * 1e6);
	    FDBinary::packUInt32(buffer, seconds);
	    FDBinary::packUInt32(&buffer[4], microseconds);
	}

	FDBinary::FDBinary() {
		buffer = std::vector<uint8_t>();
		getIndex = 0;
	}

	FDBinary::FDBinary(std::vector<uint8_t> data) {
		buffer = data;
		getIndex = 0;
	}

	std::size_t FDBinary::length() {
		return buffer.size();
	}

	std::vector<uint8_t> FDBinary::dataValue() {
		return buffer;
	}

	std::size_t FDBinary::getRemainingLength() {
		return buffer.size() - getIndex;
	}

	std::vector<uint8_t> FDBinary::getRemainingData() {
		return std::vector<uint8_t>(buffer.begin() + getIndex, buffer.end());
	}

	void FDBinary::checkGet(std::size_t amount) {
		if ((buffer.size() - getIndex) < amount) {
			throw std::out_of_range("index out of bounds");
		}
	}

	std::vector<uint8_t> FDBinary::getData(std::size_t length) {
		checkGet(length);
		std::vector<uint8_t> data = std::vector<uint8_t>(buffer.begin() + getIndex, buffer.begin() + getIndex + length);
		getIndex += length;
		return data;
	}

	uint8_t FDBinary::getUInt8() {
		checkGet(1);
		uint8_t *p = &buffer[getIndex];
		getIndex += 1;
		return FDBinary::unpackUInt8(p);
	}

	uint16_t FDBinary::getUInt16() {
		checkGet(2);
		uint8_t *p = &buffer[getIndex];
		getIndex += 2;
		return FDBinary::unpackUInt16(p);
	}

	uint32_t FDBinary::getUInt32() {
		checkGet(4);
		uint8_t *p = &buffer[getIndex];
		getIndex += 4;
		return FDBinary::unpackUInt32(p);
	}

	uint64_t FDBinary::getUInt64() {
		checkGet(8);
		uint8_t *p = &buffer[getIndex];
		getIndex += 8;
		return FDBinary::unpackUInt64(p);
	}

	float FDBinary::getFloat16() {
		checkGet(2);
		uint8_t *p = &buffer[getIndex];
		getIndex += 2;
		return FDBinary::unpackFloat16(p);
	}

	float FDBinary::getFloat32() {
		checkGet(4);
		uint8_t *p = &buffer[getIndex];
		getIndex += 4;
		return FDBinary::unpackFloat32(p);
	}

	FDBinary::time_type FDBinary::getTime64() {
		checkGet(8);
		uint8_t *p = &buffer[getIndex];
		getIndex += 8;
		return FDBinary::unpackTime64(p);
	}

	void FDBinary::putData(std::vector<uint8_t> data) {
		buffer.insert(buffer.end(), data.begin(), data.end());
	}

	void FDBinary::putUInt8(uint8_t value) {
		uint8_t bytes[] = { value };
		buffer.insert(buffer.end(), bytes, bytes + sizeof(bytes));
	}

	void FDBinary::putUInt16(uint16_t value) {
		uint8_t bytes[] = { uint8_t(value), uint8_t(value >> 8) };
		buffer.insert(buffer.end(), bytes, bytes + sizeof(bytes));
	}

	void FDBinary::putUInt32(uint32_t value) {
		uint8_t bytes[] = { uint8_t(value), uint8_t(value >> 8), uint8_t(value >> 16), uint8_t(value >> 24) };
		buffer.insert(buffer.end(), bytes, bytes + sizeof(bytes));
	}

	void FDBinary::putUInt64(uint64_t value) {
		uint8_t bytes[] = { uint8_t(value), uint8_t(value >> 8), uint8_t(value >> 16), uint8_t(value >> 24), uint8_t(value >> 32), uint8_t(value >> 40), uint8_t(value >> 48), uint8_t(value >> 56) };
		buffer.insert(buffer.end(), bytes, bytes + sizeof(bytes));
	}

	void FDBinary::putFloat16(float value) {
		uint32_t bits = FDIEEE754::floatToUint16(value);
		putUInt16(bits);
	}

	void FDBinary::putFloat32(float value) {
		fd_int32_float32_t u;
		u.asFloat32 = value;
		putUInt32(u.asUint32);
	}

	void FDBinary::putTime64(time_type value) {
		uint32_t seconds = (uint32_t)value;
		uint32_t microseconds = (uint32_t)((value - seconds) * 1e6);
		putUInt32(seconds);
		putUInt32(microseconds);
	}

}
