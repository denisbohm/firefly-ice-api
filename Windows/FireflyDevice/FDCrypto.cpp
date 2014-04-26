//
//  FDCrypto.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/15/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

#include "FDCrypto.h"

#include <windows.h>
#include <stdio.h>

namespace FireflyDesign {

	class WinSha1 {
	public:
		WinSha1();
		~WinSha1();

		std::vector<uint8_t> hash(std::vector<uint8_t> data);
		
	private:
		HCRYPTPROV hProv;
		HCRYPTHASH hHash;
	};

	WinSha1::WinSha1() {
		hProv = 0;
		hHash = 0;
	}

	WinSha1::~WinSha1() {
		if (hHash != 0) {
			CryptDestroyHash(hHash);
			hHash = 0;
		}
		if (hProv != 0) {
			CryptReleaseContext(hProv, 0);
			hProv = 0;
		}
	}

	std::vector<uint8_t> WinSha1::hash(std::vector<uint8_t> data) {
		if (!CryptAcquireContext(&hProv, NULL, NULL, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT)) {
			throw std::exception("error returned by CryptAcquireContext");
		}

		if (!CryptCreateHash(hProv, CALG_SHA, 0, 0, &hHash)) {
			throw std::exception("error returned by CryptCreateHash");
		}

		if (!CryptHashData(hHash, data.data(), data.size(), 0)) {
			throw std::exception("error returned by CryptHashData");
		}

		uint8_t hash[20]; //SHA hash is 20 bytes
		DWORD hashLength = sizeof(hash);
		if (!CryptGetHashParam(hHash, HP_HASHVAL, hash, &hashLength, 0)) {
			throw std::exception("error returned by CryptGetHashParam");
		}

		return std::vector<uint8_t>(hash, hash + sizeof(hash));
	}

	class WinAes {
	public:
		WinAes();
		~WinAes();

		std::vector<uint8_t> hash(std::vector<uint8_t> key, std::vector<uint8_t> iv, std::vector<uint8_t> data);

	private:
		HCRYPTPROV hCryptProv;
		HCRYPTKEY hCryptKey;
		uint8_t* buffer;
	};

	WinAes::WinAes()
	{
		hCryptProv = 0;
		hCryptKey = 0;
		buffer = 0;
	}

	WinAes::~WinAes() {
		if (hCryptProv) {
			CryptReleaseContext(hCryptProv, 0);
		}
		if (hCryptKey) {
			CryptDestroyKey(hCryptKey);
		}
		if (buffer) {
			delete buffer;
		}
	}

#define kAesBytes128 16

	typedef struct {
		BLOBHEADER	header;
		DWORD		key_length;
		BYTE		key_bytes[kAesBytes128];
	} AesBlob128;

	std::vector<uint8_t> WinAes::hash(std::vector<uint8_t> key, std::vector<uint8_t> iv, std::vector<uint8_t> data)
	{
		if (!CryptAcquireContext(
			&hCryptProv,
			NULL,
			NULL,
			PROV_RSA_AES,
			0))
		{
			throw std::exception("error returned by CryptAcquireContext");
		}

		AesBlob128 aes_blob;
		aes_blob.header.bType = PLAINTEXTKEYBLOB;
		aes_blob.header.bVersion = CUR_BLOB_VERSION;
		aes_blob.header.reserved = 0;
		aes_blob.header.aiKeyAlg = CALG_AES_128;
		aes_blob.key_length = kAesBytes128;
		memcpy(aes_blob.key_bytes, key.data(), kAesBytes128);

		// Create the crypto key struct that Windows needs.
		if (!CryptImportKey(
			hCryptProv,
			reinterpret_cast<BYTE*>(&aes_blob),
			sizeof(AesBlob128),
			NULL,  // hPubKey = not encrypted
			0,     // dwFlags
			&hCryptKey))
		{
			throw std::runtime_error("Unable to create crypto key.");
		}

		int buffer_length = data.size() + 2 * kAesBytes128;
		buffer = new uint8_t[];

		HCRYPTHASH hHash = NULL;
		BOOL Final = true;
		DWORD dwFlags = 0;
		DWORD pdwDataLen = data.size();
		if (!CryptEncrypt(hCryptKey, hHash, Final, dwFlags, buffer, &pdwDataLen, buffer_length)) {
			throw std::exception("error returned by CryptEncrypt");
		}

		uint8_t *end = buffer + buffer_length;
		std::vector<uint8_t> hash(end - 20, end);
		return hash;
	}

	std::vector<uint8_t> FDCrypto::sha1(std::vector<uint8_t> data)
	{
		WinSha1 winSha1;
		return winSha1.hash(data);
	}

	std::vector<uint8_t> FDCrypto::hash(std::vector<uint8_t> key, std::vector<uint8_t> iv, std::vector<uint8_t> data)
	{
		WinAes winAes;
		return winAes.hash(key, iv, data);
	}

	static uint8_t defaultHashKeyBytes[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };

	static uint8_t defaultHashIVBytes[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13 };

	std::vector<uint8_t> FDCrypto::hash(std::vector<uint8_t> data)
	{
		std::vector<uint8_t> key(defaultHashKeyBytes, defaultHashKeyBytes + sizeof(defaultHashKeyBytes));
		std::vector<uint8_t> iv(defaultHashIVBytes, defaultHashIVBytes + sizeof(defaultHashIVBytes));
		return FDCrypto::hash(key, iv, data);
	}

}
