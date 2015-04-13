//
//  FDFireflyIceChannelBLE.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import android.app.Activity;

import java.util.List;
import java.util.UUID;

import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothProfile;

public class FDFireflyIceChannelBLE implements FDFireflyIceChannel {

    FDFireflyDeviceLog log;
    FDDetour detour;
    FDFireflyIceChannel.Delegate delegate;
    FDFireflyIceChannel.Status status;

    Activity activity;
    UUID bluetoothGattCharacteristicUUID;
    BluetoothDevice bluetoothDevice;

    BluetoothGattCallback bluetoothGattCallback;
    BluetoothGatt bluetoothGatt;
    BluetoothGattCharacteristic bluetoothGattCharacteristic;

    public FDFireflyIceChannelBLE(Activity activity, String bluetoothGattServiceUUIDString, BluetoothDevice bluetoothDevice) {
        this.detour = new FDDetour();

        this.activity = activity;
        StringBuffer bluetoothGattCharacteristicUUIDString = new StringBuffer(bluetoothGattServiceUUIDString);
        bluetoothGattCharacteristicUUIDString.replace(4, 8, "0002");
        this.bluetoothGattCharacteristicUUID = UUID.fromString(bluetoothGattCharacteristicUUIDString.toString());
        this.bluetoothDevice = bluetoothDevice;

        bluetoothGattCallback = new BluetoothGattCallback() {
            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic) {
                byte[] data = characteristic.getValue();
                characteristicValueChange(data);
            }

            @Override
            public void onConnectionStateChange(final BluetoothGatt gatt, final int status, final int newState) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    bluetoothGatt.discoverServices();
                }
            }

            @Override
            public void onServicesDiscovered(final BluetoothGatt gatt, final int status) {
                servicesDiscovered();
            }
        };
    }

	public String getName() {
		return "BLE";
	}

	public FDFireflyDeviceLog getLog() {
		return log;
	}

	public void setLog(FDFireflyDeviceLog log) {
		this.log = log;
	}

	public void setDelegate(FDFireflyIceChannel.Delegate delegate) {
		this.delegate = delegate;
	}

	public FDFireflyIceChannel.Delegate getDelegate() {
		return delegate;
	}

	public FDFireflyIceChannel.Status getStatus() {
		return status;
	}

	public void open() {
		status = FDFireflyIceChannel.Status.Opening;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}

        bluetoothGatt = bluetoothDevice.connectGatt(activity, false, bluetoothGattCallback);
	}

	public void close() {
        bluetoothGatt.disconnect();
        bluetoothGatt.close();

		detour.clear();
		status = FDFireflyIceChannel.Status.Closed;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}
	}

    void servicesDiscovered() {
        List<BluetoothGattService> services = bluetoothGatt.getServices();
        for (BluetoothGattService service : services) {
            List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
            for (BluetoothGattCharacteristic characteristic : characteristics) {
                UUID uuid = characteristic.getUuid();
                if (uuid.equals(bluetoothGattCharacteristicUUID)) {
                    bluetoothGattCharacteristic = characteristic;
                    bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic, true);
                    break;
                }
            }
        }

        if (bluetoothGattCharacteristic != null) {
            this.status = FDFireflyIceChannel.Status.Open;
            if (delegate != null) {
                delegate.fireflyIceChannelStatus(this, status);
            }
        }
    }

	public void fireflyIceChannelSend(byte[] data) {
		FDDetourSource source = new FDDetourSource(20, FDBinary.toList(data));
		List<Byte> subdata;
		while ((subdata = source.next()).size() > 0) {
            FDFireflyDeviceLogger.debug(log, "FDFireflyIceChannelBLE:fireflyIceChannelSend:subdata %@", subdata);
			bluetoothGattCharacteristic.setValue(FDBinary.toByteArray(subdata));
		}
	}

	public void characteristicValueChange(byte[] data) {
		FDFireflyDeviceLogger.debug(log, "FDFireflyIceChannelBLE:characteristicValueChange %@", data);
		detour.detourEvent(FDBinary.toList(data));
		if (detour.state == FDDetour.State.Success) {
			if (delegate != null) {
				delegate.fireflyIceChannelPacket(this, FDBinary.toByteArray(detour.buffer));
			}
			detour.clear();
		} else
		if (detour.state == FDDetour.State.Error) {
			if (delegate != null) {
				delegate.fireflyIceChannelDetourError(this, detour, detour.error);
			}
			detour.clear();
		}
	}

}
