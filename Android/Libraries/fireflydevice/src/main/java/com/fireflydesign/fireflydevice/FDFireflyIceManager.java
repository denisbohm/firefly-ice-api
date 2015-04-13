package com.fireflydesign.fireflydevice;

import java.util.List;
import java.util.UUID;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;

import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;

import android.os.ParcelUuid;

public class FDFireflyIceManager {

    public interface Delegate {
        void discovered(FDFireflyIceManager manager, BluetoothDevice device);
    }

    BluetoothAdapter bluetoothAdapter;
    UUID serviceUUID;
    Delegate delegate;

    ScanCallback scanCallback;

    public FDFireflyIceManager(BluetoothAdapter bluetoothAdapter, UUID serviceUUID, Delegate delegate) {
        this.bluetoothAdapter = bluetoothAdapter;
        this.serviceUUID = serviceUUID;
        this.delegate = delegate;

        scanCallback = new ScanCallback() {

            public void onScanResult(int callbackType, ScanResult result) {
                scanDiscovery(result);
            }

            public void onBatchScanResults(List<ScanResult> results) {
                for (ScanResult result : results) {
                    scanDiscovery(result);
                }
            }

            public void onScanFailed(int errorCode) {
            }

        };
    }

    public void setDiscovery(boolean discover) {
        BluetoothLeScanner bluetoothLeScanner = bluetoothAdapter.getBluetoothLeScanner();
        if (discover) {
            bluetoothLeScanner.startScan(scanCallback);
        } else {
            bluetoothLeScanner.stopScan(scanCallback);
        }
    }

    void scanDiscovery(ScanResult result) {
        ScanRecord record = result.getScanRecord();
        List<ParcelUuid> parcelUuids = record.getServiceUuids();
        if (parcelUuids != null) {
            for (ParcelUuid parcelUuid : parcelUuids) {
                UUID uuid = parcelUuid.getUuid();
                if (uuid.equals(serviceUUID)) {
                    discovered(result.getDevice());
                    break;
                }
            }
        }
    }

    void discovered(BluetoothDevice device) {
        delegate.discovered(this, device);
    }

}
