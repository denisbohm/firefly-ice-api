package com.fireflydesign.fireflydevice;

import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.content.BroadcastReceiver;
import android.content.Intent;
import android.content.IntentFilter;

public interface FDFireflyIceMediator {

    FDTimer makeTimer(FDTimer.Delegate invocation, double timeout, FDTimer.Type type);

    void runOnThread(Runnable action);

    Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter);
    void unregisterReceiver(BroadcastReceiver receiver);

    BluetoothGatt connectGatt(String address, boolean autoConnect, BluetoothGattCallback callback);

}
