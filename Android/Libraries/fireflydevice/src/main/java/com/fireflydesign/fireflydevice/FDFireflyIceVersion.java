package com.fireflydesign.fireflydevice;

public class FDFireflyIceVersion {

    public short major;
    public short minor;
    public short patch;
    public int capabilities;
    public byte[] gitCommit;

    public String description() {
        String s = FDString.format("version %d.%d.%d, capabilities 0x%08x, git commit ", major, minor, patch, capabilities);
        for (byte b : gitCommit) {
            s += FDString.format("%02x", b);
        }
        return s;
    }

}
