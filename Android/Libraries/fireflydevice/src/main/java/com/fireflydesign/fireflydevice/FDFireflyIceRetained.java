package com.fireflydesign.fireflydevice;

public class FDFireflyIceRetained {

    public boolean retained;
    public byte[] data;

    public String description() {
        return FDString.format("retained %s", retained ? "YES" : "NO");
    }

}
