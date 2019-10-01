package com.fireflydesign.fireflydevice;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;

public class FDFireflyIceMediatorActivity implements FDFireflyIceMediator {

    public Activity activity;
    FDTimerFactory timerFactory;

    public FDFireflyIceMediatorActivity(Activity activity) {
        this.activity = activity;
        this.timerFactory = new FDTimerFactory(activity);
    }

    public FDTimer makeTimer(FDTimer.Delegate invocation, double timeout, FDTimer.Type type) {
        return timerFactory.makeTimer(invocation, timeout, type);
    }

    public void runOnThread(Runnable action) {
        activity.runOnUiThread(action);
    }

    public Intent registerReceiver(BroadcastReceiver receiver, IntentFilter filter) {
        return activity.registerReceiver(receiver, filter);
    }

    public void unregisterReceiver(BroadcastReceiver receiver) {
        activity.unregisterReceiver(receiver);
    }

    public BluetoothGatt connectGatt(String address, boolean autoConnect, BluetoothGattCallback callback) {
        BluetoothManager bluetoothManager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
        BluetoothAdapter bluetoothAdapter = bluetoothManager.getAdapter();
        BluetoothDevice bluetoothDevice = bluetoothAdapter.getRemoteDevice(address);
        return bluetoothDevice.connectGatt(activity, autoConnect, callback);
    }

}
