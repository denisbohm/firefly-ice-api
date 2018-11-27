package com.fireflydesign.fireflydevice;

import java.util.List;
import java.util.UUID;

import android.app.Activity;
import android.bluetooth.BluetoothAdapter;

import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;

import android.os.ParcelUuid;

public class FDFireflyIceManager {
    public interface Delegate {
        void discovered(FDFireflyIceManager manager, ScanResult result);
    }

    Activity activity;
    BluetoothAdapter bluetoothAdapter;
    UUID serviceUUID;
    Delegate delegate;
    Boolean discovery;

    ScanCallback scanCallback;

    public FDFireflyIceManager(final Activity activity, BluetoothAdapter bluetoothAdapter, UUID serviceUUID, Delegate delegate) {
        this.activity = activity;
        this.bluetoothAdapter = bluetoothAdapter;
        this.serviceUUID = serviceUUID;
        this.delegate = delegate;

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
    }

    public UUID getServiceUUID() {
        return serviceUUID;
    }

    public void setDiscovery(boolean discovery) {
        this.discovery = discovery;
        BluetoothLeScanner bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        if (discovery) {
            bluetoothLeScanner.startScan(scanCallback);
        } else {
            bluetoothLeScanner.stopScan(scanCallback);
        }
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
        delegate.discovered(this, result);
    }
}
