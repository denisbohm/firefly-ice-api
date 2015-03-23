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
        s += FDString.format(" version=%u", version);
        s += FDString.format(" systemSteps=%u", systemSteps);
        s += FDString.format(" dataSteps=%u", dataSteps);
        s += FDString.format(" systemCredits=%u", systemCredits);
        s += FDString.format(" dataCredits=%u", dataCredits);
        s += FDString.format(" txPower=%u", txPower);
        s += FDString.format(" operatingMode=%u", operatingMode);
        s += FDString.format(" idle=%", idle ? "YES" : "NO");
        s += FDString.format(" dtm=%", dtm ? "YES" : "NO");
        s += FDString.format(" did=%02x", did);
        s += FDString.format(" disconnectAction=%u", disconnectAction);
        s += FDString.format(" pipesOpen=%016llx", pipesOpen);
        s += FDString.format(" dtmRequest=%u", dtmRequest);
        s += FDString.format(" dtmData=%u", dtmData);
        s += FDString.format(" bufferCount=%u", bufferCount);
        s += ")";
        return s;
    }

}
