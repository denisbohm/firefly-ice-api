package com.fireflydesign.fireflydevice;

public class FDFireflyIceDiagnosticsBLE {

    public int version;
    public int systemSteps;
    public int dataSteps;
    public int systemCredits;
    public int dataCredits;
    public byte txPower;
    public byte operatingMode;
    public boolean idle;
    public boolean dtm;
    public byte did;
    public byte disconnectAction;
    public long pipesOpen;
    public short dtmRequest;
    public short dtmData;
    public int bufferCount;

    public String description() {
        String s = "BLE(";
        s += FDString.format(" version=%d", version);
        s += FDString.format(" systemSteps=%d", systemSteps);
        s += FDString.format(" dataSteps=%d", dataSteps);
        s += FDString.format(" systemCredits=%d", systemCredits);
        s += FDString.format(" dataCredits=%d", dataCredits);
        s += FDString.format(" txPower=%d", txPower);
        s += FDString.format(" operatingMode=%d", operatingMode);
        s += FDString.format(" idle=%s", idle ? "YES" : "NO");
        s += FDString.format(" dtm=%s", dtm ? "YES" : "NO");
        s += FDString.format(" did=%02x", did);
        s += FDString.format(" disconnectAction=%d", disconnectAction);
        s += FDString.format(" pipesOpen=%016x", pipesOpen);
        s += FDString.format(" dtmRequest=%d", dtmRequest);
        s += FDString.format(" dtmData=%d", dtmData);
        s += FDString.format(" bufferCount=%d", bufferCount);
        s += ")";
        return s;
    }

}
