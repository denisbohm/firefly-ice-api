package com.fireflydesign.fireflydevice;

import java.util.List;

public class FDFireflyIceObservable implements FDFireflyIceObserver {

    List<FDFireflyIceObserver> observers;

    public void addObserver(FDFireflyIceObserver observer) {
        observers.add(observer);
    }

    public void removeObserver(FDFireflyIceObserver observer) {
        observers.remove(observer);
    }

    public void fireflyIceStatus(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceChannel.Status status) {}
    public void fireflyIceDetourError(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDDetour detour, FDError error) {}
    public void fireflyIcePing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] data) {}
    public void fireflyIceVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion version) {}
    public void fireflyIceHardwareId(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceHardwareId hardwareId) {}
    public void fireflyIceBootVersion(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceVersion bootVersion) {}
    public void fireflyIceDebugLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, boolean debugLock) {}
    public void fireflyIceTime(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, double time) {}
    public void fireflyIcePower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIcePower power) {}
    public void fireflyIceSite(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String site) {}
    public void fireflyIceReset(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceReset reset) {}
    public void fireflyIceStorage(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceStorage storage) {}
    public void fireflyIceMode(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int mode) {}
    public void fireflyIceTxPower(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, int txPower) {}
    public void fireflyIceLock(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLock lock) {}
    public void fireflyIceLogging(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceLogging logging) {}
    public void fireflyIceName(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, String name) {}
    public void fireflyIceDiagnostics(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDiagnostics diagnostics) {}
    public void fireflyIceRetained(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceRetained retained) {}
    public void fireflyIceDirectTestModeReport(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceDirectTestModeReport directTestModeReport) {}
    public void fireflyIceExternalHash(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] externalHash) {}
    public void fireflyIcePageData(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] pageData) {}
    public void fireflyIceSectorHashes(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSectorHash[] sectorHashes) {}
    public void fireflyIceUpdateCommit(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceUpdateCommit updateCommit) {}
    public void fireflyIceSensing(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, FDFireflyIceSensing sensing) {}
    public void fireflyIceSync(FDFireflyIce fireflyIce, FDFireflyIceChannel channel, byte[] syncData) {}

    void except(Exception e) {
    }

}
