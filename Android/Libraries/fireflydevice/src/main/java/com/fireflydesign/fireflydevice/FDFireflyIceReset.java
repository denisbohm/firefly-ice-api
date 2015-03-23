package com.fireflydesign.fireflydevice;

public class FDFireflyIceReset {

    public int cause;
    public double date;

    public String description() {
        if ((cause & 1) != 0) {
            return "Power On Reset";
        }
        if ((cause & 2) != 0) {
            return "Brown Out Detector Unregulated Domain Reset";
        }
        if ((cause & 4) != 0) {
            return "Brown Out Detector Regulated Domain Reset";
        }
        if ((cause & 8) != 0) {
            return "External Pin Reset";
        }
        if ((cause & 16) != 0) {
            return "Watchdog Reset";
        }
        if ((cause & 32) != 0) {
            return "LOCKUP Reset";
        }
        if ((cause & 64) != 0) {
            return "System Request Reset";
        }
        if (cause == 0) {
            return "No Reset";
        }
        return FDString.format("0x%08x Reset", cause);
    }

}
