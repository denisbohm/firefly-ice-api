//
//  ViewController.swift
//  Firefly Activity
//
//  Created by Denis Bohm on 12/28/17.
//  Copyright © 2017 Firefly Design LLC. All rights reserved.
//

import CloudKit
import UIKit
import MessageUI
import FireflyDevice

class ViewController: UIViewController, BluetoothObserver, UITextFieldDelegate, MFMailComposeViewControllerDelegate, HelpViewControllerDelegate {

    enum Action {
        case none
        case check
        case edit
        case close
    }
    
    @IBOutlet var bluetoothImageView: UIImageView!
    @IBOutlet var cloudImageView: UIImageView!
    @IBOutlet var catalogView: UIView!
    @IBOutlet var deviceView: UIView!
    
    var catalogViewController: CatalogViewController!
    var deviceViewController: DeviceViewController!

    var installationDate: Date? = nil
    var installationUUID: String? = nil
    var studyIdentifier: String? = nil

    let history = History()
    let bluetooth = Bluetooth()
    let catalog = Catalog()
    var action: Action = .none
    var cloud: Cloud? = nil
    let container = CKContainer.default()
    var accountStatus: CKAccountStatus = .couldNotDetermine

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
    
    func metaHistoryValue() -> [String: Any] {
        var value: [String: Any] = [:]
        if let installationDate = installationDate {
            value["installationDate"] = Activity.rfc3339(date: installationDate)
        }
        if let installationUUID = installationUUID {
            value["installationUUID"] = installationUUID
        }
        if let studyIdentifier = studyIdentifier {
            value["studyIdentifier"] = studyIdentifier
        }
        var devices: [[String: String]] = []
        for device in catalog.devices {
            let item: [String: String] = ["name": device.name, "hardwareIdentifier": device.hardwareIdentifier]
            devices.append(item)
        }
        value["devices"] = devices
        return value
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.viewController = self
        }
        
        // !!! Just for testing, start with empty catalog -denis
        //        catalog.save()
        
#if targetEnvironment(simulator)
        createFakeDevices()
#endif
        
        catalog.load()
        
        initializeFromUserDefaults()
        try? history.save(type: "launch", value: metaHistoryValue())
        
        bluetooth.bluetoothObservers.append(self)
        bluetooth.initialize()
        
        catalogViewController = findChildViewController()
        deviceViewController = findChildViewController()

        catalogViewController.selectedCallback = checkDevice
        catalogViewController.editCallback = editDevice
        catalogViewController.deleteCallback = forgetDevice
        deviceViewController.backCallback = showCatalog
        deviceViewController.pullCallback = pullComplete
        
        var fireflyIces: [FDFireflyIce] = []
        for device in catalog.devices {
            if let fireflyIce = bluetooth.getFireflyIce(peripheralIdentifier: device.peripheralIdentifier) {
                fireflyIces.append(fireflyIce)
            }
        }
        catalogViewController.load(fireflyIces: fireflyIces)
        showCatalog()
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(accountChanged(_:)), name: Notification.Name.CKAccountChanged, object: nil)
        requestAccountStatus()

        pushToCloud()
    }
    
    func updateAccountStatus(accountStatus: CKAccountStatus) {
        self.accountStatus = accountStatus
        Log.info("cloud kit account status: \(accountStatus)")
    }
    
    func requestAccountStatus() {
        container.accountStatus { (accountStatus, error) in
            if let error = error {
                Log.error(error)
            } else {
                DispatchQueue.main.async {
                    self.updateAccountStatus(accountStatus: accountStatus)
                }
            }
        }
    }
    
    @objc func accountChanged(_ notification: Notification) {
        requestAccountStatus()
    }
    
    func initializeFromUserDefaults() {
        let userDefaults = UserDefaults.standard
        
        if let installationDate = userDefaults.object(forKey: "installationDate") as? Date {
            self.installationDate = installationDate
        } else {
            self.installationDate = Date()
            userDefaults.set(self.installationDate, forKey: "installatonDate")
        }
        
        if let installationUUID = userDefaults.string(forKey: "installationUUID") {
            self.installationUUID = installationUUID
        } else {
            self.installationUUID = UUID().uuidString
            userDefaults.set(self.installationUUID, forKey: "installationUUID")
        }
        
        studyIdentifier = userDefaults.string(forKey: "studyIdentifier")
    }
    
    func save(studyIdentifier: String) {
        Log.info("save study identifier \(studyIdentifier)")

        self.studyIdentifier = studyIdentifier
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(studyIdentifier, forKey: "studyIdentifier")
        userDefaults.synchronize()

        try? history.save(type: "saveStudy", value: metaHistoryValue())
        
        let savedStudyIdentifier = userDefaults.string(forKey: "studyIdentifier")
        Log.info("saved study identifier \(String(describing: savedStudyIdentifier))")
    }
    
    func bluetoothPoweredOn() {
        bluetoothImageView.tintColor = UIColor.lightGray
        if !catalogView.isHidden {
            bluetooth.scan()
        }
    }
    
    func bluetoothPoweredOff() {
        bluetoothImageView.tintColor = UIColor.red
    }
    
    func bluetoothDidDiscover(fireflyIce: FDFireflyIce, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        catalogViewController.display(fireflyIce: fireflyIce)
    }
    
    func catalogPut(fireflyIce: FDFireflyIce) -> Catalog.Device {
        let channel = fireflyIce.channels["BLE"] as! FDFireflyIceChannelBLE
        let peripheralIdentifier = channel.peripheral.identifier
        let hardwareIdentifier = FDHardwareId.hardwareId(fireflyIce.hardwareId.unique)
        let device = Catalog.Device(name: fireflyIce.name, peripheralIdentifier: peripheralIdentifier, hardwareIdentifier: hardwareIdentifier)
        catalog.put(device: device)
        return device
    }
    
    func catalogUpdate(fireflyIce: FDFireflyIce) {
        let channel = fireflyIce.channels["BLE"] as! FDFireflyIceChannelBLE
        if let oldDevice = catalog.get(peripheralIdentifier: channel.peripheral.identifier) {
            let device = Catalog.Device(name: fireflyIce.name, peripheralIdentifier: oldDevice.peripheralIdentifier, hardwareIdentifier: oldDevice.hardwareIdentifier)
            catalog.put(device: device)
        }
    }
    
    func bluetoothDidUpdateName(fireflyIce: FDFireflyIce) {
        catalogUpdate(fireflyIce: fireflyIce)
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
        let channel = fireflyIce.channels["BLE"] as! FDFireflyIceChannelBLE
        if let device = catalog.get(peripheralIdentifier: channel.peripheral.identifier) {
            catalog.remove(device: device)
            try? history.save(type: "forgetDevice",
                              value: ["name": device.name,
                                      "hardwareIdentifier": device.hardwareIdentifier])
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
        bluetoothImageView.tintColor = UIColor.orange

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
    
    func bluetoothIsConnecting(fireflyIce: FDFireflyIce) {
    }
    
    func bluetoothIsOpening(fireflyIce: FDFireflyIce) {
        bluetoothImageView.tintColor = UIColor.green
    }
    
    func bluetoothDidOpen(fireflyIce: FDFireflyIce) {
    }
    
    func bluetoothIsClosing(fireflyIce: FDFireflyIce) {
        action = .close
    }
    
    func bluetoothDidClose(fireflyIce: FDFireflyIce) {
        if action != .close {
            bluetoothImageView.tintColor = UIColor.red
        } else {
            bluetoothImageView.tintColor = UIColor.lightGray
        }
        action = .none
        self.dismiss(animated: true, completion: nil)
    }
    
    func closeDevice(item: CatalogViewController.Item) {
        if let channel = item.fireflyIce.channels["BLE"] as? FDFireflyIceChannelBLE {
            channel.close()
        }
        if !item.associated {
            showCatalog()
        }
    }
    
    func bluetoothDidIdentify(fireflyIce: FDFireflyIce) {
        self.dismiss(animated: true, completion: nil)
        
        bluetoothImageView.tintColor = UIColor.blue

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
        let _ = catalogUpdate(fireflyIce: fireflyIce)
        let hardwareIdentifier = FDHardwareId.hardwareId(fireflyIce.hardwareId.unique)
        try? history.save(type: "nameDevice",
                              value: ["name": name,
                                      "hardwareIdentifier": hardwareIdentifier])
        
        if action == .edit {
            catalogViewController.display(fireflyIce: fireflyIce)
            bluetooth.sendPingClose(fireflyIce: fireflyIce, channel: channel)
        } else
        if action == .check {
            catalogViewController.associate(fireflyIce: fireflyIce)
            let device = catalogPut(fireflyIce: fireflyIce)
            showDevice(hardwareIdentifier: device.hardwareIdentifier, fireflyIce: fireflyIce)
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
        
        try? history.save(type: "showDevice",
                          value: ["hardwareIdentifier": hardwareIdentifier])

        bluetooth.stopScan()
        catalogView.isHidden = true

        deviceViewController.showDevice(fireflyIce: fireflyIce, identifier: hardwareIdentifier)
        deviceViewController.pullActivityData()
        deviceView.isHidden = false
    }
    
    func pullComplete(hardwareIdentifier: String, error: Error?) {
        if let error = error {
            Log.error(error)
        }
        try? history.save(type: "pullComplete",
                          value: ["hardwareIdentifier": hardwareIdentifier,
                                  "error": error?.localizedDescription ?? "none"])
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
    
    @IBAction func pushToCloud() {
        if cloud != nil {
            NSLog("deferring push to cloud - previous cloud push still running")
        }
        let fileManager = FileManager.default
        guard let documentDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            NSLog("document directory not found")
            return
        }
        cloudImageView.tintColor = UIColor.blue
        let directory = documentDirectory.appendingPathComponent("database", isDirectory: true)
        let activityManager = ActivityManager.shared
        cloud = Cloud(installationUUID: activityManager.installationUUID, directory: directory) { (error) in
            DispatchQueue.main.async {
                self.pushToCloudComplete(error: error)
            }
        }
        cloud!.start()
    }
    
    func pushToCloudComplete(error: Error?) {
        if let error = error {
            Log.error(error)
        }
        cloudImageView.tintColor = error == nil ? UIColor.lightGray : UIColor.red
        cloud = nil
    }
    
    @IBAction func showHelp() {
        let helpViewController = storyboard!.instantiateViewController(withIdentifier: "help") as! HelpViewController
        helpViewController.delegate = self
        helpViewController.text = "Contact support by touching the 'Email Support' button below.\n\n\n" + supportDescription()
        helpViewController.modalPresentationStyle = .overFullScreen
        helpViewController.modalTransitionStyle = .crossDissolve
        self.present(helpViewController, animated: true, completion: nil)
    }
    
    func emailSupport(helpViewController: HelpViewController) {
        closeHelp(helpViewController: helpViewController)
        
        let email = Bundle.main.infoDictionary!["supportemail"] as? String ?? "denis@fireflydesign.com"
        sendMail(recipients: [email])
    }
    
    func closeHelp(helpViewController: HelpViewController) {
        helpViewController.dismiss(animated: false, completion: nil)
    }
    
    func alert(message: String) {
        let alertController = UIAlertController(title: "Mail Result", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func datastoreDescription(identifier: String) -> String {
        let end = Date()
        let calendar = NSCalendar(calendarIdentifier: .gregorian)!
        let start = calendar.date(byAdding: .day, value: -7, to: end)!
        let datastore = Datastore(identifier: identifier)
        let spans = datastore.query(start: start.timeIntervalSince1970, end: end.timeIntervalSince1970)
        var description = "\(spans.count) span"
        if spans.count != 1 {
            description += "s"
        }
        if let first = spans.first, let last = spans.last {
            let (start, _) = first.timeRange()
            let (_, end) = last.timeRange()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let startString = formatter.string(from: Date(timeIntervalSince1970: start))
            let endString = formatter.string(from: Date(timeIntervalSince1970: end))
            description += " from \(startString) to \(endString)"
        }
        description += "."
        return description
    }
    
    func datastoreDescriptions() -> String {
        var description = "Data:\n"
        for (_, device) in catalog.deviceByHardwareIdentifier {
            description += "  \(device.name) (\(device.hardwareIdentifier)) " + datastoreDescription(identifier: device.hardwareIdentifier) + "\n"
        }
        return description
    }
    
    func accountStatusDescription(_ status: CKAccountStatus) -> String {
        switch status {
        case .couldNotDetermine:
            return "could not be determined"
        case .available:
            return "available"
        case .noAccount:
            return "no account"
        case .restricted:
            return "restricted"
        }
    }
    
    func supportDescription() -> String {
        var description = ""
        let statusString = accountStatusDescription(accountStatus)
        description += "Cloud Kit Account Status: \(statusString)\n"
        if let studyIdentifier = studyIdentifier {
            description += "Study Identifier: \(studyIdentifier)\n"
        }
        description += "\n"
        description += datastoreDescriptions()
        description += "\n"
        if let installationDate = installationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let intallationDateString = formatter.string(from: installationDate)
            description += "Installation Date: \(intallationDateString)\n"
        }
        if let installationUUID = installationUUID {
            description += "Installation UUID: \(installationUUID)\n"
        }
        return description
    }
    
    func sendMail(recipients: [String]) {
        if !MFMailComposeViewController.canSendMail() {
            alert(message: "No mail account found.")
        }
        
        if let mailCompose: MFMailComposeViewController = MFMailComposeViewController() as MFMailComposeViewController? {
            mailCompose.mailComposeDelegate = self
            mailCompose.setToRecipients(recipients)
            let name = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
            var subject = "\(name) Help"
            if let studyIdentifier = studyIdentifier {
                subject += " for Study Identifier \(studyIdentifier)"
            }
            mailCompose.setSubject(subject)
            let message = supportDescription() + "\n\nLog is attached."
            mailCompose.setMessageBody(message, isHTML: false)
            if let url = try? Log.shared.getURL(), let data = try? Data(contentsOf: url, options: []) {
                let fileName = url.lastPathComponent
                mailCompose.addAttachmentData(data, mimeType: "text/plain", fileName: fileName)
            }
            present(mailCompose, animated: true, completion: nil)
        } else {
            alert(message: "Mail is not available.")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        switch result {
        case .cancelled:
            alert(message: "Mail was cancelled.")
        case .saved:
            alert(message: "Mail was saved.")
        case .sent:
            alert(message: "Mail was sent.")
        case .failed:
            alert(message: "Sending mail failed: \(String(describing: error)).")
        }
        dismiss(animated: false, completion: nil)
    }

}
