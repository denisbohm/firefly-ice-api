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
    UUID bluetoothGattCharacteristicNoResponseUUID;
    BluetoothDevice bluetoothDevice;

    List<FDDetourSource> detourSources;
    int writePending;
    int writePendingLimit;
    BluetoothGattCallback bluetoothGattCallback;
    BluetoothGatt bluetoothGatt;
    BluetoothGattCharacteristic bluetoothGattCharacteristic;
    BluetoothGattCharacteristic bluetoothGattCharacteristicNoResponse;

    public FDFireflyIceChannelBLE(final Activity activity, final String bluetoothGattServiceUUIDString, final BluetoothDevice bluetoothDevice) {
        this.detour = new FDDetour();

        this.activity = activity;
        StringBuffer bluetoothGattCharacteristicUUIDString = new StringBuffer(bluetoothGattServiceUUIDString);
        bluetoothGattCharacteristicUUIDString.replace(4, 8, "0002");
        this.bluetoothGattCharacteristicUUID = UUID.fromString(bluetoothGattCharacteristicUUIDString.toString());
        bluetoothGattCharacteristicUUIDString.replace(4, 8, "0003");
        this.bluetoothGattCharacteristicNoResponseUUID = UUID.fromString(bluetoothGattCharacteristicUUIDString.toString());
        this.bluetoothDevice = bluetoothDevice;

        detourSources = new ArrayList<FDDetourSource>();
        bluetoothGattCallback = new BluetoothGattCallback() {
            @Override
            public void onCharacteristicChanged(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic) {
                final byte[] data = characteristic.getValue();
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        characteristicChanged(gatt, characteristic, data);
                    }
                });
            }

            @Override
            public void onCharacteristicWrite(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic, final int status) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        writeComplete(gatt, status);
                    }
                });
            }

            @Override
            public void onDescriptorWrite(final BluetoothGatt gatt, final BluetoothGattDescriptor descriptor, final int status) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        writeComplete(gatt, status);
                    }
                });
            }

            @Override
            public void onConnectionStateChange(final BluetoothGatt gatt, final int status, final int newState) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        connectionStateChange(gatt, status, newState);
                    }
                });
            }

            @Override
            public void onServicesDiscovered(final BluetoothGatt gatt, final int status) {
                activity.runOnUiThread(new Runnable() {
                    public void run() {
                        servicesDiscovered(gatt, status);
                    }
                });
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
        FDFireflyDeviceLogger.debug(log, "FD010901", "opening firefly");
		status = FDFireflyIceChannel.Status.Opening;
		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}

        bluetoothGatt = bluetoothDevice.connectGatt(activity, false, bluetoothGattCallback);
	}

    void shutdown() {
        FDFireflyDeviceLogger.debug(log, "FD010902", "closed firefly");
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
        bluetoothGattCharacteristicNoResponse = null;

        detour.clear();
        detourSources.clear();
        writePending = 0;
        writePendingLimit = 1;
    }

    public void close() {
        shutdown();

		if (delegate != null) {
			delegate.fireflyIceChannelStatus(this, status);
		}
	}

    void servicesDiscovered(final BluetoothGatt gatt, final int status) {
        FDFireflyDeviceLogger.debug(log, "FD010903", "found firefly service");
        List<BluetoothGattService> services = bluetoothGatt.getServices();
        for (BluetoothGattService service : services) {
            List<BluetoothGattCharacteristic> characteristics = service.getCharacteristics();
            for (BluetoothGattCharacteristic characteristic : characteristics) {
                UUID uuid = characteristic.getUuid();
                if (uuid.equals(bluetoothGattCharacteristicUUID)) {
                    FDFireflyDeviceLogger.debug(log, "FD010904", "found firefly service characteristic");

                    bluetoothGattCharacteristic = characteristic;

                    bluetoothGatt.setCharacteristicNotification(bluetoothGattCharacteristic, true);
                    // 0x2902 org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
                    UUID clientCharacteristicConfigurationUuid = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb");
                    BluetoothGattDescriptor descriptor = characteristic.getDescriptor(clientCharacteristicConfigurationUuid);
                    descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
                    boolean canWrite = bluetoothGatt.writeDescriptor(descriptor);
                    writePending = writePendingLimit;
                } else
                if (uuid.equals(bluetoothGattCharacteristicNoResponseUUID)) {
                    FDFireflyDeviceLogger.debug(log, "FD010904", "found firefly service characteristic");

                    bluetoothGattCharacteristicNoResponse = characteristic;
                }
            }
        }

        if ((bluetoothGattCharacteristic != null) && (bluetoothGattCharacteristicNoResponse != null)) {
            writePendingLimit = 12;
        }

        if (bluetoothGattCharacteristic != null) {
            this.status = FDFireflyIceChannel.Status.Open;
            if (delegate != null) {
                delegate.fireflyIceChannelStatus(this, this.status);
            }
        }
    }

    void connectionStateChange(final BluetoothGatt gatt, final int status, final int newState) {
        if (newState == BluetoothProfile.STATE_CONNECTED) {
            FDFireflyDeviceLogger.debug(log, "FD010905", "connected to firefly");
            bluetoothGatt.discoverServices();
        } else
        if (newState == BluetoothProfile.STATE_DISCONNECTED) {
            FDFireflyDeviceLogger.debug(log, "FD010906", "disconnected from firefly");
            shutdown();
        }
    }

    boolean attemptWrite(BluetoothGattCharacteristic characteristic, List<Byte> data) {
        boolean canSetValue = characteristic.setValue(FDBinary.toByteArray(data));
        Object value = characteristic.getValue();
        BluetoothGattService service = characteristic.getService();
        BluetoothDevice device = bluetoothGatt.getDevice();

        boolean canWriteCharacteristic = bluetoothGatt.writeCharacteristic(characteristic);
        FDFireflyDeviceLogger.info(
                log,
                "FD010908",
                "FDFireflyIceChannelBLE:fireflyIceChannelSend:subdata %s, set=%s, write=%s",
                FDBinary.toHexString(FDBinary.toByteArray(data)),
                canSetValue ? "YES" : "NO",
                canWriteCharacteristic ? "YES" : "NO"
        );
        return canWriteCharacteristic;
    }

    void checkWrite() {
        FDFireflyDeviceLogger.info(log, "FD010907", "check write");
        while ((writePending < writePendingLimit) && !detourSources.isEmpty()) {
            FDDetourSource detourSource = detourSources.get(0);
            List<Byte> subdata = detourSource.next();
            if (subdata.size() > 0) {
                boolean success;
                ++writePending;
                if (writePending < writePendingLimit) {
                    success = attemptWrite(bluetoothGattCharacteristicNoResponse, subdata);
                } else {
                    success = attemptWrite(bluetoothGattCharacteristic, subdata);
                }
                if (!success) {
                    --writePending;
                    detourSource.pushBack(subdata);
                    return;
                }
            } else {
                detourSources.remove(0);
            }
        }
    }

    void writeComplete(final BluetoothGatt gatt, final int status) {
        FDFireflyDeviceLogger.info(log, "FD010909", "writeComplete %d", status);
        writePending = 0;
        checkWrite();
    }

    public void fireflyIceChannelSend(final byte[] data) {
        detourSources.add(new FDDetourSource(20, FDBinary.toList(data)));
        checkWrite();
	}

	public void characteristicChanged(final BluetoothGatt gatt, final BluetoothGattCharacteristic characteristic, final byte[] data) {
        FDFireflyDeviceLogger.info(log, "FD010910", "FDFireflyIceChannelBLE:characteristicValueChange %s", FDBinary.toHexString(data));
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
