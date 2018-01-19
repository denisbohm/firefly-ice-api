//
//  Catalog.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 1/10/18.
//  Copyright © 2018 Firefly Design LLC. All rights reserved.
//

import Foundation

class Catalog {
    
    struct Device: Codable {
        let name: String
        let peripheralIdentifier: UUID
        let hardwareIdentifier: String
    }
    
    var deviceByHardwareIdentifier: [String: Device] = [:]
    var url: URL!
    
    var devices: [Device] {
        get {
            return Array(deviceByHardwareIdentifier.values)
        }
    }
    
    init() {
        let fileManager = FileManager.default
        let roots = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let root = roots.first!
        url = root.appendingPathComponent("catalog").appendingPathExtension("json")
    }
    
    func contains(hardwareIdentifier: String) -> Bool {
        return deviceByHardwareIdentifier.keys.contains(hardwareIdentifier)
    }
    
    func get(hardwareIdentifier: String) -> Device? {
        return deviceByHardwareIdentifier[hardwareIdentifier]
    }
    
    func put(device: Device) {
        deviceByHardwareIdentifier[device.hardwareIdentifier] = device
        save()
    }
    
    func remove(device: Device) {
        deviceByHardwareIdentifier.removeValue(forKey: device.hardwareIdentifier)
        save()
    }
    
    func load() {
        do {
            let decoder = JSONDecoder()
            let data = try Data(contentsOf: url, options: [])
            let devices = try decoder.decode([Device].self, from: data)
            deviceByHardwareIdentifier.removeAll()
            for device in devices {
                deviceByHardwareIdentifier[device.hardwareIdentifier] = device
            }
        } catch {
            NSLog("catalog load error: \(error.localizedDescription)")
        }
    }
    
    func save() {
        do {
            let encoder = JSONEncoder()
            let devices: [Device] = Array(deviceByHardwareIdentifier.values)
            let data = try encoder.encode(devices)
            try data.write(to: url, options: [])
        } catch {
            NSLog("catalog save error: \(error.localizedDescription)")
        }
    }
    
}
