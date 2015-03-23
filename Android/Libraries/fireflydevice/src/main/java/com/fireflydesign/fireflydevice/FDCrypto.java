//
//  FDCrypto.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 9/15/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Arrays;

import javax.crypto.Cipher;

import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

public class FDCrypto {

	public static byte[] sha1(byte[] data) {
        try {
            MessageDigest messageDigest = MessageDigest.getInstance("SHA-1");
            messageDigest.reset();
            messageDigest.update(data);
            return messageDigest.digest();
        } catch (NoSuchAlgorithmException e) {
            return new byte[20];
        }
	}

    public static byte[] hash(byte[] keyBytes, byte[] ivBytes, byte[] data) {
        try {
            SecretKeySpec key = new SecretKeySpec(keyBytes, "AES");
            IvParameterSpec ivSpec = new IvParameterSpec(ivBytes);
            Cipher cipher = Cipher.getInstance("AES/CBC/PKCS5Padding");
            cipher.init(Cipher.ENCRYPT_MODE, key, ivSpec);
            byte[] result = cipher.doFinal(data);
            return Arrays.copyOfRange(result, 0, 20);
        } catch (Exception e) {
            return new byte[20];
        }
	}

	static byte defaultHashKeyBytes[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f };

	static byte defaultHashIVBytes[] = { 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13 };

    public static byte[] hash(byte[] data) {
		return hash(defaultHashKeyBytes, defaultHashIVBytes, data);
	}

}
