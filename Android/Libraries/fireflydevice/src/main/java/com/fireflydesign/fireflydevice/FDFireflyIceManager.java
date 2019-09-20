package com.fireflydesign.fireflydevice;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.ParcelUuid;

public class FDFireflyIceManager {

    public enum BluetoothState {
        Off, On
    }

    public interface Delegate {
        void fireflyIceManagerBluetoothState(FDFireflyIceManager manager, BluetoothState state);
        boolean fireflyIceManagerDiscovered(FDFireflyIceManager manager, ScanResult result);
        void fireflyIceManagerAdded(FDFireflyIceManager manager, FDFireflyIce fireflyIce);
    }

    Activity activity;
    BluetoothAdapter bluetoothAdapter;
    UUID serviceUUID;
    Delegate delegate;
    boolean discovery;
    Map<String, Map<String, Object>> discovered;

    BluetoothLeScanner bluetoothLeScanner;
    ScanCallback scanCallback;
    BroadcastReceiver broadcastReceiver;

    public FDFireflyIceManager(final Activity activity, BluetoothAdapter bluetoothAdapter, UUID serviceUUID, Delegate delegate) {
        this.activity = activity;
        this.bluetoothAdapter = bluetoothAdapter;
        this.serviceUUID = serviceUUID;
        this.delegate = delegate;
        this.discovered = new HashMap();

        scanCallback = new ScanCallback() {

            public void onScanResult(final int callbackType, final ScanResult result) {
                activity.runOnUiThread(
                        new Runnable() {
                            public void run() {
                                scanResult(result);
                            }
                        }
                );
            }

            public void onBatchScanResults(List<ScanResult> results) {
                for (ScanResult result : results) {
                    onScanResult(0, result);
                }
            }

            public void onScanFailed(int errorCode) {
            }

        };

        // !!! this is a workaround for Android 8.0 and on where BluetoothGattCallback.onConnectionStateChange
        // is not called when Bluetooth is turned off (https://issuetracker.google.com/69855257) -denis
        broadcastReceiver = new BroadcastReceiver() {

            public void onReceive(Context context, Intent intent) {
                final String action = intent.getAction();
                if (action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                    final int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                            BluetoothAdapter.ERROR);
                    switch (state) {
                        case BluetoothAdapter.STATE_OFF:
                            bluetoothOff();
                            break;
                        case BluetoothAdapter.STATE_TURNING_OFF:
                            bluetoothTurningOff();
                            break;
                        case BluetoothAdapter.STATE_ON:
                            bluetoothOn();
                            break;
                        case BluetoothAdapter.STATE_TURNING_ON:
                            bluetoothTurningOn();
                            break;
                    }
                }
            }

        };
        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        this.activity.registerReceiver(broadcastReceiver, filter);
    }

    public UUID getServiceUUID() {
        return serviceUUID;
    }

    void checkScanningState() {
        boolean isScanning = bluetoothLeScanner != null;
        boolean shouldScan = discovery || isAndroidCacheMessedUp();

        if (isScanning == shouldScan) {
            return;
        }

        if (shouldScan) {
            bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
            bluetoothLeScanner.startScan(scanCallback);
        } else {
            bluetoothLeScanner.stopScan(scanCallback);
            bluetoothLeScanner = null;
        }
    }

    public void setDiscovery(boolean discovery) {
        this.discovery = discovery;

        checkScanningState();
    }

    public Boolean getDiscovery() {
        return discovery;
    }

    void scanResult(ScanResult result) {
        ScanRecord record = result.getScanRecord();
        List<ParcelUuid> parcelUuids = record.getServiceUuids();
        if (parcelUuids != null) {
            for (ParcelUuid parcelUuid : parcelUuids) {
                UUID uuid = parcelUuid.getUuid();
                if (uuid.equals(serviceUUID)) {
                    discovered(result);
                    break;
                }
            }
        }
    }

    void discovered(ScanResult result) {
        if (!delegate.fireflyIceManagerDiscovered(this, result)) {
            addDevice(result.getDevice());
        }
    }

    boolean isAndroidCacheMessedUp(BluetoothDevice bluetoothDevice) {
        String name = bluetoothDevice.getName();
        return name == null;
    }

    boolean isAndroidCacheMessedUp() {
        for (Map<String, Object> map : this.discovered.values()) {
            boolean messedUp = (Boolean)map.get("isAndroidCacheMessedUp");
            if (messedUp) {
                return true;
            }
        }
        return false;
    }

    public FDFireflyIce getDeviceForAddress(String address) {
        Map<String, Object> map = this.discovered.get(address);
        if (map == null) {
            return null;
        }
        return (FDFireflyIce)map.get("fireflyIce");
    }

    public FDFireflyIce addDevice(BluetoothDevice bluetoothDevice) {
        String address = bluetoothDevice.getAddress();
        Map<String, Object> map = this.discovered.get(address);
        if (map == null) {
            FDFireflyIce fireflyIce = new FDFireflyIce(this.activity);
            FDFireflyIceChannelBLE channel = new FDFireflyIceChannelBLE(this.activity, this.serviceUUID.toString(), address);
            fireflyIce.addChannel(channel, "BLE");

            map = new HashMap();
            map.put("fireflyIce", fireflyIce);
            map.put("isAndroidCacheMessedUp", isAndroidCacheMessedUp(bluetoothDevice));
            this.discovered.put(address, map);
            delegate.fireflyIceManagerAdded(this, fireflyIce);
        } else {
            boolean wasMessedUp = (Boolean)map.get("isAndroidCacheMessedUp");
            boolean isMessedUp = isAndroidCacheMessedUp(bluetoothDevice);
            map.put("isAndroidCacheMessedUp", isMessedUp);

            if (wasMessedUp && !isMessedUp) {
                FDFireflyIce fireflyIce = (FDFireflyIce)map.get("fireflyIce");
                FDFireflyIceChannelBLE channel = (FDFireflyIceChannelBLE)fireflyIce.channels.get("BLE");
                if (channel.status == FDFireflyIceChannel.Status.Opening) {
                    channel.shutdown();
                    channel.open();
                }
            }
        }

        checkScanningState();

        return (FDFireflyIce)map.get("fireflyIce");
    }

    public FDFireflyIce addDeviceWithAddress(String address) {
        return addDevice(this.bluetoothAdapter.getRemoteDevice(address));
    }

    void bluetoothTurningOff() {
        bluetoothLeScanner = null;

        for (Map map : discovered.values()) {
            FDFireflyIce fireflyIce = (FDFireflyIce)map.get("fireflyIce");
            FDFireflyIceChannelBLE channel = (FDFireflyIceChannelBLE)fireflyIce.channels.get("BLE");
            if (channel.status != FDFireflyIceChannel.Status.Closed) {
                channel.bluetoothTurningOff();
            }
        }
    }

    void bluetoothOff() {
        delegate.fireflyIceManagerBluetoothState(this, BluetoothState.Off);
    }

    void bluetoothTurningOn() {
        for (Map<String, Object> map : this.discovered.values()) {
            map.put("isAndroidCacheMessedUp", true);
        }
    }

    void bluetoothOn() {
        checkScanningState();

        delegate.fireflyIceManagerBluetoothState(this, BluetoothState.On);
    }

}
