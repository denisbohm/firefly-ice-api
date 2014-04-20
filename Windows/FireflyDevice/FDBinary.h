//
//  FDBinary.h
//  FireflyDevice
//
//  Created by Denis Bohm on 4/16/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#ifndef FDBINARY_H
#define FDBINARY_H

#include <cstdint>
#include <vector>

namespace FireflyDesign {

	class FDBinary {
	public:
		typedef double time_type;

		FDBinary();
		FDBinary(std::vector<uint8_t> data);

		std::size_t length();
		std::vector<uint8_t> dataValue();

		std::size_t getIndex;

		std::size_t getRemainingLength();
		std::vector<uint8_t> getRemainingData();
		std::vector<uint8_t> getData(std::size_t length);
		uint8_t getUInt8();
		uint16_t getUInt16();
		uint32_t getUInt32();
		uint64_t getUInt64();
		float getFloat16();
		float getFloat32();
		time_type getTime64();

		void putData(std::vector<uint8_t> data);
		void putUInt8(uint8_t value);
		void putUInt16(uint16_t value);
		void putUInt32(uint32_t value);
		void putUInt64(uint64_t value);
		void putFloat16(float value);
		void putFloat32(float value);
		void putTime64(time_type value);

		static uint8_t unpackUInt8(uint8_t *buffer);
		static uint16_t unpackUInt16(uint8_t *buffer);
		static uint32_t unpackUInt32(uint8_t *buffer);
		static uint64_t unpackUInt64(uint8_t *buffer);
		static float unpackFloat16(uint8_t *buffer);
		static float unpackFloat32(uint8_t *buffer);
		static time_type unpackTime64(uint8_t *buffer);

		static void packUInt8(uint8_t *buffer, uint8_t value);
		static void packUInt16(uint8_t *buffer, uint16_t value);
		static void packUInt32(uint8_t *buffer, uint32_t value);
		static void packUInt64(uint8_t *buffer, uint64_t value);
		static void packFloat16(uint8_t *buffer, float value);
		static void packFloat32(uint8_t *buffer, float value);
		static void packTime64(uint8_t *buffer, time_type value);

	private:
		std::vector<uint8_t> buffer;

		void checkGet(std::size_t amount);
	};

}

#endif