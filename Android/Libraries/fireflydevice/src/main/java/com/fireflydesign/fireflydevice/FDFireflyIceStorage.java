package com.fireflydesign.fireflydevice;

public class FDFireflyIceStorage {

    public int pageCount;

    public String description() {
        return FDString.format("page count %u", pageCount);
    }

}
