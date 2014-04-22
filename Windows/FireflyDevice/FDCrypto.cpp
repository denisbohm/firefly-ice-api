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

#ifdef NO_XP
#include <bcrypt.h>

#pragma comment( lib, "Bcrypt" )

namespace FireflyDesign {

#define NT_SUCCESS(Status)          (((NTSTATUS)(Status)) >= 0)

#define STATUS_UNSUCCESSFUL         ((NTSTATUS)0xC0000001L)

	class WinSha1 {
	public:
		WinSha1();
		~WinSha1();

		std::vector<uint8_t> hash(std::vector<uint8_t> data);
	private:
		BCRYPT_ALG_HANDLE       hAlg;
		BCRYPT_HASH_HANDLE      hHash;
		NTSTATUS                status;
		DWORD                   cbData;
		DWORD					cbHash;
		DWORD					cbHashObject;
		PBYTE                   pbHashObject;
		PBYTE                   pbHash;
	};

	WinSha1::WinSha1()
	{
		hAlg = NULL;
		hHash = NULL;
		status = STATUS_UNSUCCESSFUL;
		cbData = 0;
		cbHash = 0;
		cbHashObject = 0;
		pbHashObject = NULL;
		pbHash = NULL;
	}

	std::vector<uint8_t> WinSha1::hash(std::vector<uint8_t> data)
	{
		//open an algorithm handle
		if (!NT_SUCCESS(status = BCryptOpenAlgorithmProvider(
			&hAlg,
			BCRYPT_SHA256_ALGORITHM,
			NULL,
			0)))
		{
			throw std::exception("error returned by BCryptOpenAlgorithmProvider");
		}

		//calculate the size of the buffer to hold the hash object
		if (!NT_SUCCESS(status = BCryptGetProperty(
			hAlg,
			BCRYPT_OBJECT_LENGTH,
			(PBYTE)&cbHashObject,
			sizeof(DWORD),
			&cbData,
			0)))
		{
			throw std::exception("errorreturned by BCryptGetProperty");
		}

		//allocate the hash object on the heap
		pbHashObject = (PBYTE)HeapAlloc(GetProcessHeap(), 0, cbHashObject);
		if (NULL == pbHashObject)
		{
			throw std::exception("memory allocation failed");
		}

		//calculate the length of the hash
		if (!NT_SUCCESS(status = BCryptGetProperty(
			hAlg,
			BCRYPT_HASH_LENGTH,
			(PBYTE)&cbHash,
			sizeof(DWORD),
			&cbData,
			0)))
		{
			throw std::exception("error returned by BCryptGetProperty");
		}

		//allocate the hash buffer on the heap
		pbHash = (PBYTE)HeapAlloc(GetProcessHeap(), 0, cbHash);
		if (NULL == pbHash)
		{
			throw std::exception("memory allocation failed");
		}

		//create a hash
		if (!NT_SUCCESS(status = BCryptCreateHash(
			hAlg,
			&hHash,
			pbHashObject,
			cbHashObject,
			NULL,
			0,
			0)))
		{
			throw std::exception("error returned by BCryptCreateHash");
		}

		//hash some data
		if (!NT_SUCCESS(status = BCryptHashData(
			hHash,
			(PBYTE)data.data(),
			sizeof(data.size()),
			0)))
		{
			throw std::exception("error returned by BCryptHashData");
		}

		//close the hash
		if (!NT_SUCCESS(status = BCryptFinishHash(
			hHash,
			pbHash,
			cbHash,
			0)))
		{
			throw std::exception("error returned by BCryptFinishHash");
		}

		std::vector<uint8_t> hash(pbHash, pbHash + cbHash);
		return hash;
	}

	WinSha1::~WinSha1()
	{
		if (hAlg)
		{
			BCryptCloseAlgorithmProvider(hAlg, 0);
		}

		if (hHash)
		{
			BCryptDestroyHash(hHash);
		}

		if (pbHashObject)
		{
			HeapFree(GetProcessHeap(), 0, pbHashObject);
		}

		if (pbHash)
		{
			HeapFree(GetProcessHeap(), 0, pbHash);
		}
	}

}
#endif

namespace FireflyDesign {

	class WinSha1 {
	public:
		WinSha1() {}
		~WinSha1() {}

		std::vector<uint8_t> hash(std::vector<uint8_t> data) {
			throw std::exception("unimplemented");
		}
	};

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
