package com.fireflydesign.fireflydevice;

public class FDFireflyIceSectorHash {

    public short sector;
    public byte[] hash;

    public String description() {
        String s = FDString.format("sector %d hash 0x", sector);
        for (byte b : hash) {
            s += FDString.format("%02x", b);
        }
        return s;
    }

}
