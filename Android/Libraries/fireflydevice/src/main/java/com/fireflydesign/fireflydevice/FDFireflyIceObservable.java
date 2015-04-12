package com.fireflydesign.fireflydevice;

public interface FDFireflyIceObservable extends FDFireflyIceObserver {

    void addObserver(FDFireflyIceObserver observer);
    void removeObserver(FDFireflyIceObserver observer);

}