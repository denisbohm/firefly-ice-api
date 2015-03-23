package com.fireflydesign.fireflydevice;

public class FDFireflyIceLogging {

    public int flags;
    public int count;
    public int state;

    public String description() {
        String s = "logging";
        if ((flags & FDFireflyIceCoder.FD_CONTROL_LOGGING_STATE) != 0) {
            s += FDString.format(" storage=%", (state & FDFireflyIceCoder.FD_CONTROL_LOGGING_STORAGE) != 0 ? "YES" : "NO");
        }
        if ((flags & FDFireflyIceCoder.FD_CONTROL_LOGGING_COUNT) != 0) {
            s += FDString.format(" count=%u", count);
        }
        return s;
    }

}
