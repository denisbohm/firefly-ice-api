package com.fireflydesign.fireflydevice;

public class FDFireflyIceHardwareId {

    public short vendor;
    public short product;
    public short major;
    public short minor;
    public byte[] unique;

    public String description() {
        String s = FDString.format("vendor 0x%04x, product 0x%04x, version %u.%u unique ", vendor, product, major, minor);
        for (byte b : unique) {
            s += FDString.format("%02x", b);
        }
        return s;
    }

}
