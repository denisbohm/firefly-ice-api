//
//  Bluetooth.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/15/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import CoreBluetooth
import FireflyDevice

protocol BluetoothObserver {
    func bluetoothPoweredOn()
    func bluetoothPoweredOff()
    func bluetoothDidDiscover(fireflyIce: FDFireflyIce, advertisementData: [String : Any], rssi RSSI: NSNumber)
    func bluetoothDidUpdateName(fireflyIce: FDFireflyIce)
    func bluetoothIsConnecting(fireflyIce: FDFireflyIce)
    func bluetoothIsOpening(fireflyIce: FDFireflyIce)
    func bluetoothDidOpen(fireflyIce: FDFireflyIce)
    func bluetoothIsClosing(fireflyIce: FDFireflyIce)
    func bluetoothDidClose(fireflyIce: FDFireflyIce)
    func bluetoothDidIdentify(fireflyIce: FDFireflyIce)
}

class Bluetooth: NSObject, CBCentralManagerDelegate, FDFireflyIceObserver, FDHelloTaskDelegate {
    
    let pingCloseData = Data(bytes: [0x43, 0x4C, 0x51, 0x53, 0x45])

    var centralManager: CBCentralManager!
    var bluetoothObservers: [BluetoothObserver] = []
    var fireflyIceByPeripheralIdentifier: [UUID: FDFireflyIce] = [:]
    
    override init() {
    }
    
    func initialize() {
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    func isPoweredOn() -> Bool {
        return centralManager.state == .poweredOn
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch centralManager.state {
        case .unknown:
            NSLog("bluetooth state unknown")
        case .unsupported:
            NSLog("bluetooth unsupported")
        case .unauthorized:
            NSLog("bluetooth unauthorized")
        case .resetting:
            NSLog("bluetooth resetting")
        case .poweredOff:
            NSLog("bluetooth powered off")
            bluetoothObservers.forEach { $0.bluetoothPoweredOff() }
        case .poweredOn:
            NSLog("bluetooth powered on")
            bluetoothObservers.forEach { $0.bluetoothPoweredOn() }
        }
    }
    
    func scan() {
        let services = [CBUUID(string: "310a0001-1b95-5091-b0bd-b7a681846399")]
        centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScan() {
        centralManager.stopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
//        NSLog("bluetooth peripheral did discover")
        let fireflyIce = getFireflyIce(peripheral: peripheral, advertisementData: advertisementData)
        bluetoothObservers.forEach { $0.bluetoothDidDiscover(fireflyIce: fireflyIce, advertisementData: advertisementData, rssi: rssi) }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        NSLog("bluetooth peripheral did connect")
        guard let fireflyIce = fireflyIceByPeripheralIdentifier[peripheral.identifier] else {
            return
        }
        guard let channel = fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE else {
            return
        }
        channel.didConnectPeripheral()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        NSLog("bluetooth peripheral did disconnect")
        if let error = error {
            Log.error(error)
        }
        guard let fireflyIce = fireflyIceByPeripheralIdentifier[peripheral.identifier] else {
            return
        }
        guard let channel = fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE else {
            return
        }
        channel.didDisconnectPeripheralError(error)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        NSLog("bluetooth peripheral did fail to connect")
        if let error = error {
            Log.error(error)
        }
    }
    
    func getFireflyIce(peripheral: CBPeripheral, advertisementData: [String: Any] = [:]) -> FDFireflyIce {
        if let existingFireflyDevice = fireflyIceByPeripheralIdentifier[peripheral.identifier] {
            if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
                if existingFireflyDevice.name != name {
                    existingFireflyDevice.name = name
                    bluetoothObservers.forEach { $0.bluetoothDidUpdateName(fireflyIce: existingFireflyDevice) }
                }
            }
            return existingFireflyDevice
        }
        
        NSLog("creating firefly ice for peripheral \(peripheral.identifier.description)")
        let fireflyIce = FDFireflyIce()
        if let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            fireflyIce.name = name
        } else {
            fireflyIce.name = peripheral.name
        }
        fireflyIce.observable.addObserver(self)
        let serviceUUID = CBUUID(string: "310a0001-1b95-5091-b0bd-b7a681846399")
        let channel = FDFireflyIceChannelBLE(centralManager: centralManager, with: peripheral, withServiceUUID: serviceUUID)
        fireflyIce.addChannel(channel, type: "BLE")
        fireflyIceByPeripheralIdentifier[peripheral.identifier] = fireflyIce
        return fireflyIce
    }
    
    func getFireflyIce(peripheralIdentifier: UUID) -> FDFireflyIce? {
        guard let peripheral = centralManager.retrievePeripherals(withIdentifiers: [peripheralIdentifier]).first else {
            NSLog("cannot retrieve peripheral")
            return nil
        }
        return getFireflyIce(peripheral: peripheral)
    }
    
    func fireflyIce(_ fireflyIce: FDFireflyIce!, channel: FDFireflyIceChannel!, status: FDFireflyIceChannelStatus) {
        switch status {
        case .connecting:
            fireflyIceConnecting(fireflyIce: fireflyIce, channel: channel);
        case .open:
            fireflyIceOpen(fireflyIce: fireflyIce, channel: channel);
        case .opening:
            fireflyIceOpening(fireflyIce: fireflyIce, channel: channel);
        case .closing:
            fireflyIceClosing(fireflyIce: fireflyIce, channel: channel);
        case .closed:
            fireflyIceClosed(fireflyIce: fireflyIce, channel: channel);
        }
    }
    
    func fireflyIceOpening(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        bluetoothObservers.forEach { $0.bluetoothIsOpening(fireflyIce: fireflyIce) }
    }
    
    func fireflyIceConnecting(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        bluetoothObservers.forEach { $0.bluetoothIsConnecting(fireflyIce: fireflyIce) }
    }
    
    func fireflyIceOpen(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        bluetoothObservers.forEach { $0.bluetoothDidOpen(fireflyIce: fireflyIce) }
        fireflyIce.coder.sendIdentify(channel, duration: 10.0)
        fireflyIce.executor.execute(FDHelloTask(fireflyIce, channel: channel, delegate: self))
    }
    
    func fireflyIceClosing(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        bluetoothObservers.forEach { $0.bluetoothIsClosing(fireflyIce: fireflyIce) }
    }
    
    func fireflyIceClosed(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        bluetoothObservers.forEach { $0.bluetoothDidClose(fireflyIce: fireflyIce) }
    }
    
    func helloTaskSuccess(_ helloTask: FDHelloTask) {
        let fireflyIce = helloTask.fireflyIce
        bluetoothObservers.forEach { $0.bluetoothDidIdentify(fireflyIce: fireflyIce) }
    }
    
    func helloTask(_ helloTask: FDHelloTask, error: Error?) {
        if let error = error {
            Log.error(error)
        }
        helloTask.channel.close()
    }
    
    func sendPingClose(fireflyIce: FDFireflyIce, channel: FDFireflyIceChannel) {
        fireflyIce.coder.sendPing(channel, data: pingCloseData)
    }
    
    func fireflyIce(_ fireflyIce: FDFireflyIce!, channel: FDFireflyIceChannel!, ping: Data) {
        if ping == pingCloseData {
            channel.close()
        }
    }
    
}
