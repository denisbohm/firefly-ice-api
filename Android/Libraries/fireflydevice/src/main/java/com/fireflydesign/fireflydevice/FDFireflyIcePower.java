package com.fireflydesign.fireflydevice;

public class FDFireflyIcePower {

    public float batteryLevel;
    public float batteryVoltage;
    public boolean isUSBPowered;
    public boolean isCharging;
    public float chargeCurrent;
    public float temperature;

    public String description()	 {
        return FDString.format("battery level %0.2f, battery voltage %0.2f V, USB power %s, charging %s, charge current %0.1f mA, temperature %0.1f C", batteryLevel, batteryVoltage, isUSBPowered ? "YES" : "NO", isCharging ? "YES" : "NO", chargeCurrent * 1000.0, temperature);
    }

}
