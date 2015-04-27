package com.fireflydesign.fireflydevice;

import junit.framework.Assert;
import junit.framework.TestCase;

import java.util.Arrays;

public class FDCryptoTest extends TestCase {

    public void testSha1() throws Exception {
        byte[] actual = FDCrypto.sha1(new byte[] {(byte)0x00, (byte)0x01, (byte)0x02, (byte)0x03, (byte)0x04, (byte)0x05, (byte)0x06, (byte)0x07, (byte)0x08, (byte)0x09, (byte)0x0a, (byte)0x0b, (byte)0x0c, (byte)0x0d, (byte)0x0f});
        byte[] expected = new byte[] {(byte)0xd4, (byte)0x8a, (byte)0xa2, (byte)0x4e, (byte)0x9f, (byte)0xee, (byte)0x0d, (byte)0xe3, (byte)0x40, (byte)0xea, (byte)0x7c, (byte)0xd5, (byte)0x13, (byte)0x88, (byte)0x6e, (byte)0xf6, (byte)0xe3, (byte)0x20, (byte)0xe9, (byte)0x09};
        Assert.assertTrue(Arrays.equals(actual, expected));
    }

}