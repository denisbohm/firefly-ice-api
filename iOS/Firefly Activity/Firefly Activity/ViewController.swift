//
//  ViewController.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 12/28/17.
//  Copyright © 2017 Firefly Design LLC. All rights reserved.
//

import UIKit
import FireflyDevice

class ViewController: UIViewController, BluetoothObserver, UITextFieldDelegate {

    enum Action {
        case none
        case check
        case edit
    }
    
    @IBOutlet var catalogView: UIView!
    @IBOutlet var deviceView: UIView!
    
    var catalogViewController: CatalogViewController!
    var deviceViewController: DeviceViewController!

    let bluetooth = Bluetooth()
    let catalog = Catalog()
    var action: Action = .none

    func findChildViewController<T>() -> T? where T: UIViewController {
        if let index = (childViewControllers.index { $0 is T }) {
            return childViewControllers[index] as? T
        }
        return nil
    }
    
    func createFakeData(identifier: String) throws {
        let endDate = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let startDate = calendar.date(byAdding: .day, value: -14, to: endDate)!
        let end = Int(endDate.timeIntervalSince1970)
        let days = Activity.daysInRange(start: startDate, end: endDate)
        for day in days {
            let datastore = Datastore(identifier: identifier)
            try datastore.load(day: day)
            var time = datastore.timeRange.start
            while (time < datastore.timeRange.end) {
                let vma = Float(arc4random_uniform(100)) / 100.0
                try datastore.update(time: time, vma: vma)
                time += datastore.interval
                if time > end {
                    break
                }
            }
            datastore.save()
        }
    }
    
    func createFakeDevices() {
        catalog.put(device:  Catalog.Device(name: "fido", peripheralIdentifier: UUID(uuidString: "E621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, hardwareIdentifier: "fake-fido"))
        try? createFakeData(identifier: "fake-fido")
        catalog.put(device:  Catalog.Device(name: "wolfie", peripheralIdentifier: UUID(uuidString: "F621E1F8-C36C-495A-93FC-0C247A3E6E5F")!, hardwareIdentifier: "fake-wolfie"))
        try? createFakeData(identifier: "fake-wolfie")
        catalog.save()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bluetooth.bluetoothObservers.append(self)
        bluetooth.initialize()
        
        // !!! Juat for testing, start with empty catalog -denis
        //catalog.save()
        
        if TARGET_OS_SIMULATOR != 0 {
            createFakeDevices()
        }
        
        catalog.load()
        
        catalogViewController = findChildViewController()
        deviceViewController = findChildViewController()

        catalogViewController.selectedCallback = checkDevice
        catalogViewController.editCallback = editDevice
        catalogViewController.deleteCallback = forgetDevice
        deviceViewController.backCallback = showCatalog
        
        var fireflyIces: [FDFireflyIce] = []
        for device in catalog.devices {
            if let fireflyIce = bluetooth.getFireflyIce(peripheralIdentifier: device.peripheralIdentifier) {
                fireflyIces.append(fireflyIce)
            }
        }
        catalogViewController.load(fireflyIces: fireflyIces)
        showCatalog()
    }
    
    func bluetoothPoweredOn() {
        if !catalogView.isHidden {
            bluetooth.scan()
        }
    }
    
    func bluetoothPoweredOff() {
    }
    
    func bluetoothDidDiscover(fireflyIce: FDFireflyIce, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        catalogViewController.display(fireflyIce: fireflyIce)
    }
    
    func catalogUpdate(fireflyIce: FDFireflyIce) -> Catalog.Device? {
        if fireflyIce.hardwareId != nil {
            let hardwareIdentifier = FDHardwareId.hardwareId(fireflyIce.hardwareId.unique)
            let channel = fireflyIce.channels["BLE"] as! FDFireflyIceChannelBLE
            let device = Catalog.Device(name: fireflyIce.name, peripheralIdentifier: channel.peripheral.identifier, hardwareIdentifier: hardwareIdentifier)
            catalog.put(device: device)
            return device
        } else {
            return nil
        }
    }
    
    func bluetoothDidUpdateName(fireflyIce: FDFireflyIce) {
        let _ = catalogUpdate(fireflyIce: fireflyIce)
        catalogViewController.display(fireflyIce: fireflyIce)
    }
    
    func checkDevice(item: CatalogViewController.Item) {
        openDevice(item: item, action: .check)
    }
    
    func editDevice(item: CatalogViewController.Item) {
        openDevice(item: item, action: .edit)
    }
    
    func forgetDevice(item: CatalogViewController.Item) {
        let fireflyIce = item.fireflyIce
        if let hardwareId = fireflyIce.hardwareId {
            let hardwareIdentifier = FDHardwareId.hardwareId(hardwareId.unique)
            if let device = catalog.get(hardwareIdentifier: hardwareIdentifier) {
                catalog.remove(device: device)
            }
        }
        catalogViewController.delete(item: item)
    }
    
    func openDevice(item: CatalogViewController.Item, action: Action) {
        let fireflyIce = item.fireflyIce
        guard let channel = fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE else {
            return
        }
        
        self.action = action
        channel.open()

        let message = "Connecting to the device.  The device can then be identified by a pulsing blue light."
        let alert = UIAlertController(title: "Connecting", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.closeDevice(item: item)
        })
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
        
        if (action == .check) && item.associated {
            if let device = catalog.get(peripheralIdentifier: channel.peripheral.identifier) {
                showDevice(hardwareIdentifier: device.hardwareIdentifier, fireflyIce: fireflyIce)
            }
        }
    }
    
    func bluetoothDidClose(fireflyIce: FDFireflyIce) {
        action = .none
        self.dismiss(animated: true, completion: nil)
    }

    func closeDevice(item: CatalogViewController.Item) {
        action = .none
        if let channel = item.fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE {
            channel.close()
        }
        if !item.associated {
            showCatalog()
        }
    }
    
    func bluetoothDidIdentify(fireflyIce: FDFireflyIce) {
        self.dismiss(animated: true, completion: nil)
        
        if action == .edit {
            useDevice(fireflyIce: fireflyIce)
            return
        }
        
        if !deviceView.isHidden {
            return
        }

        let message = "Do you want to use the device indicated by its pulsing blue light?"
        let alert = UIAlertController(title: "Use Device?", message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
            self.useDevice(fireflyIce: fireflyIce)
        })
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.doNotUseDevice(fireflyIce: fireflyIce)
        })
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let originalText: NSString = (textField.text ?? "") as NSString
        let text = originalText.replacingCharacters(in: range, with: string)
        let length = text.lengthOfBytes(using: .ascii)
        return length <= 8
    }
    
    func useDevice(fireflyIce: FDFireflyIce) {
        let message = "What name would you like to use for this device?"
        let alert = UIAlertController(title: "Name Device", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addTextField { (textField: UITextField) -> Void in
            textField.text = fireflyIce.name
            textField.delegate = self
        }
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: { action in
            let textField = alert.textFields![0]
            let name = textField.text ?? ""
            let length = name.lengthOfBytes(using: .ascii)
            if (length > 0) && (length <= 8) {
                self.nameDevice(fireflyIce: fireflyIce, name: name)
            } else {
                self.doNotUseDevice(fireflyIce: fireflyIce)
            }
        })
        alert.addAction(okAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            self.doNotUseDevice(fireflyIce: fireflyIce)
        })
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func nameDevice(fireflyIce: FDFireflyIce, name: String) {
        let channel = fireflyIce.channels["BLE"] as! FDFireflyIceChannelBLE
        
        fireflyIce.coder.sendSetPropertyName(channel, name: name)
        fireflyIce.name = name
        
        if action == .edit {
            let hardwareIdentifier = FDHardwareId.hardwareId(fireflyIce.hardwareId.unique)
            if catalog.contains(hardwareIdentifier: hardwareIdentifier) {
                let _ = catalogUpdate(fireflyIce: fireflyIce)
            }
            catalogViewController.display(fireflyIce: fireflyIce)
            bluetooth.sendPingClose(fireflyIce: fireflyIce, channel: channel)
        }
        if action == .check {
            let device = catalogUpdate(fireflyIce: fireflyIce)
            catalogViewController.associate(fireflyIce: fireflyIce)
            if let device = device {
                showDevice(hardwareIdentifier: device.hardwareIdentifier, fireflyIce: fireflyIce)
            }
        }
    }
    
    func doNotUseDevice(fireflyIce: FDFireflyIce) {
        if let channel = fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE {
            channel.close()
        }
        
        showCatalog()
    }
    
    func showDevice(hardwareIdentifier: String, fireflyIce: FDFireflyIce) {
        NSLog("show device \(fireflyIce.name)")
        
        bluetooth.stopScan()
        catalogView.isHidden = true

        deviceViewController.showDevice(fireflyIce: fireflyIce, identifier: hardwareIdentifier)
        deviceViewController.pullActivityData()
        deviceView.isHidden = false
    }
    
    func showCatalog() {
        NSLog("show catalog")
        
        deviceView.isHidden = true
        deviceViewController.stop()

        if bluetooth.isPoweredOn() {
            bluetooth.scan()
        }
        catalogView.isHidden = false
    }
    
}
