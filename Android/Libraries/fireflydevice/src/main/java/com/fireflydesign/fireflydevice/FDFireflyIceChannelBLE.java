//
//  FDFireflyIceChannelBLE.cpp
//  FireflyDevice
//
//  Created by Denis Bohm on 5/3/13.
//  Copyright (c) 2013-2014 Firefly Design LLC / Denis Bohm. All rights reserved.
//

package com.fireflydesign.fireflydevice;

import android.app.Activity;

import java.util.ArrayList;
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

    List<FDDetourSource> detourSources;
    boolean writePending;
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

        detourSources = new ArrayList<FDDetourSource>();
        bluetoothGattCallback = new BluetoothGattCallback() {
            @Override
            public void onCharacteristicChanged(BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic) {
                byte[] data = characteristic.getValue();
                characteristicValueChange(data);
            }

            @Override
            public void onCharacteristicWrite(BluetoothGatt gatt, BluetoothGattCharacteristic characteristic, int status) {
//    FDFireflyDeviceLogDebug(@"didWriteValueForCharacteristic %s", error);
                writePending = false;
                checkWrite();
            }

            @Override
            public void onConnectionStateChange(final BluetoothGatt gatt, final int status, final int newState) {
                if (newState == BluetoothProfile.STATE_CONNECTED) {
                    FDFireflyDeviceLogger.debug(log, "connected to firefly");
                    bluetoothGatt.discoverServices();
                } else
                if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                    FDFireflyDeviceLogger.debug(log, "disconnected from firefly");
                    shutdown();
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
        FDFireflyDeviceLogger.debug(log, "opening firefly");
		status = FDFireflyIceChannel.Status.Opening;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}

        bluetoothGatt = bluetoothDevice.connectGatt(activity, false, bluetoothGattCallback);
	}

    void shutdown() {
        FDFireflyDeviceLogger.debug(log, "closed firefly");
        status = FDFireflyIceChannel.Status.Closed;

        if (bluetoothGatt != null) {
            if (bluetoothGattCharacteristic != null) {
                bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic, true);
            }
            bluetoothGatt.disconnect();
            bluetoothGatt.close();
        }
        bluetoothGatt = null;
        bluetoothGattCharacteristic = null;

        detour.clear();
        detourSources.clear();
        writePending = false;
    }

    public void close() {
        shutdown();

		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}
	}

    void servicesDiscovered() {
        FDFireflyDeviceLogger.debug(log, "found firefly service");
        List<BluetoothGattService> services = bluetoothGatt.getServices();
        for (BluetoothGattService service : services) {
            List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
            for (BluetoothGattCharacteristic characteristic : characteristics) {
                UUID uuid = characteristic.getUuid();
                if (uuid.equals(bluetoothGattCharacteristicUUID)) {
                    FDFireflyDeviceLogger.debug(log, "found firefly service characteristic");

                    bluetoothGattCharacteristic = characteristic;
                    bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic, true);

                    // 0x2902 org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
                    UUID clientCharacteristicConfigurationUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
                    BluetoothGattDescriptor descriptor = characteristic.getDescriptor(clientCharacteristicConfigurationUuid);
                    descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                    bluetoothGatt.writeDescriptor(descriptor);
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

    void checkWrite() {
        if (writePending) {
            return;
        }

        while (!detourSources.isEmpty()) {
            FDDetourSource detourSource = detourSources.get(0);
            List<Byte> subdata = detourSource.next();
            if (subdata.size() > 0) {
                boolean canSetValue = bluetoothGattCharacteristic.setValue(FDBinary.toByteArray(subdata));
                int properties = bluetoothGattCharacteristic.getProperties();
                if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE) == 0) {
                    return;
                }
                if ((properties & BluetoothGattCharacteristic.PROPERTY_WRITE_NO_RESPONSE) == 0) {
                    return;
                }

                boolean canWriteCharacteristic = bluetoothGatt.writeCharacteristic(bluetoothGattCharacteristic);
                FDFireflyDeviceLogger.debug(
                        log,
                        "FDFireflyIceChannelBLE:fireflyIceChannelSend:subdata %s, set=%s, write=%s",
                        FDBinary.toHexString(FDBinary.toByteArray(subdata)),
                        canSetValue ? "YES" : "NO",
                        canWriteCharacteristic ? "YES" : "NO"
                );
                if (!canWriteCharacteristic) {
                    return;
                }
                writePending = true;
                break;
            }
            detourSources.remove(0);
        }
    }

    public void fireflyIceChannelSend(byte[] data) {
        detourSources.add(new FDDetourSource(20, FDBinary.toList(data)));
        checkWrite();
	}

	public void characteristicValueChange(byte[] data) {
		FDFireflyDeviceLogger.debug(log, "FDFireflyIceChannelBLE:characteristicValueChange %s", FDBinary.toHexString(data));
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
