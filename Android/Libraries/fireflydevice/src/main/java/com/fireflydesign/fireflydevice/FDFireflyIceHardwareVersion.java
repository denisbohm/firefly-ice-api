package com.fireflydesign.fireflydevice;

/**
 * Created by denis on 9/10/15.
 */
public class FDFireflyIceHardwareVersion {

    public short major;
    public short minor;

    public String description() {
        return FDString.format("version %d.%d", major, minor);
    }

}
