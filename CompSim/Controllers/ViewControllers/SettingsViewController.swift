//
//  EventViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/4/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import MessageUI
import RealmSwift
import CoreBluetooth

var txCharacteristic : CBCharacteristic?
var rxCharacteristic : CBCharacteristic?
var blePeripheral : CBPeripheral?
var characteristicASCIIValue = NSString()


class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource
{
    /*
    Invoked when the central manager’s state is updated.
    This is where we start the scan if Bluetooth is turned on and on stackmat mode.
    */
    func centralManagerDidUpdateState(_ central: CBCentralManager)
    {
        if central.state == CBManagerState.poweredOn
        {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            if HomeViewController.timing == 2
            {
                startScan()
            }
        }
    }

 /*Okay, now that we have our CBCentalManager up and running, it's time to start searching for devices. You can do this by calling the "scanForPeripherals" method.*/
    
    func startScan() {
        peripherals = []
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [BLEService_UUID] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(withTimeInterval: 17, repeats: false) {_ in
            self.cancelScan()
        }
    }
    
    /*We also need to stop scanning at some point so we'll also create a function that calls "stopScan"*/
    func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    func refreshScanView() {
        baseTableView.reloadData()
    }
    
    //-Terminate all Peripheral Connection
    /*
     Call this when things either go wrong, or you're done with the connection.
     This cancels any subscriptions if there are any, or straight disconnects if not.
     (didUpdateNotificationStateForCharacteristic will cancel the connection if a subscription is involved)
     */
    func disconnectFromDevice () {
        if blePeripheral != nil {
            // We have a connection to the device but we are not subscribed to the Transfer Characteristic for some reason.
            // Therefore, we will just disconnect from the peripheral
            centralManager?.cancelPeripheralConnection(blePeripheral!)
        }
    }
    
    
    func restoreCentralManager() {
        //Restores Central Manager delegate if something went wrong
        centralManager?.delegate = self
    }
    
    /*
     Called when the central manager discovers a peripheral while scanning. Also, once peripheral is connected, cancel scanning.
     */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        blePeripheral = peripheral
        self.peripherals.append(peripheral)
        self.RSSIs.append(RSSI)
        peripheral.delegate = self
        self.baseTableView.reloadData()
        if blePeripheral == nil {
            print("Found new pheripheral devices with services")
            print("Peripheral name: \(String(describing: peripheral.name))")
            print("**********************************")
            print ("Advertisement Data : \(advertisementData)")
        }
    }
    
    //Peripheral Connections: Connecting, Connected, Disconnected
    
    //-Connection
    func connectToDevice () {
        centralManager?.connect(blePeripheral!, options: nil)
    }
    
    /*
     Invoked when a connection is successfully created with a peripheral.
     This method is invoked when a call to connect(_:options:) is successful. You typically implement this method to set the peripheral’s delegate and to discover its services.
     */
    //-Connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("*****************************")
        print("Connection complete")
        print("Peripheral info: \(String(describing: blePeripheral))")
        
        //Stop Scan- We don't need to scan once we've connected to a peripheral. We got what we came for.
        centralManager?.stopScan()
        print("Scan Stopped")
        
        //Erase data that we might have
        data.length = 0
        
        //Discovery callback
        peripheral.delegate = self
        //Only look for services that matches transmit uuid
        peripheral.discoverServices([BLEService_UUID])
        
    }
    
    /*
     Invoked when the central manager fails to create a connection with a peripheral.
     */
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(blePeripheral!)
    }
    
    /*
     Invoked when you discover the peripheral’s available services.
     This method is invoked when your app calls the discoverServices(_:) method. If the services of the peripheral are successfully discovered, you can access them through the peripheral’s services property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            return
        }
        //We need to discover the all characteristic
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            // bleService = service
        }
        print("Discovered Services: \(services)")
    }
    
    /*
     Invoked when you discover the characteristics of a specified service.
     This method is invoked when your app calls the discoverCharacteristics(_:for:) method. If the characteristics of the specified service are successfully discovered, you can access them through the service's characteristics property. If successful, the error parameter is nil. If unsuccessful, the error parameter returns the cause of the failure.
     */
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("*******************************************************")
        
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        print("Found \(characteristics.count) characteristics!")
        
        for characteristic in characteristics {
            //looks for the right characteristic
            
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Rx)  {
                rxCharacteristic = characteristic
                
                //Once found, subscribe to the this particular characteristic...
                peripheral.setNotifyValue(true, for: rxCharacteristic!)
                // We can return after calling CBPeripheral.setNotifyValue because CBPeripheralDelegate's
                // didUpdateNotificationStateForCharacteristic method will be called automatically
                peripheral.readValue(for: characteristic)
                print("Rx Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Tx){
                txCharacteristic = characteristic
                print("Tx Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
    }
    
    // MARK: - Getting Values From Characteristic
    /** After you've found a characteristic of a service that you are interested in, you can read the characteristic's value by calling the peripheral "readValueForCharacteristic" method within the "didDiscoverCharacteristicsFor service" delegate.
     */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard characteristic == rxCharacteristic,
            let characteristicValue = characteristic.value,
            let ASCIIstring = NSString(data: characteristicValue,
                                       encoding: String.Encoding.utf8.rawValue)
            else { return }
        
        characteristicASCIIValue = ASCIIstring
        print("Value Recieved: \((characteristicASCIIValue as String))")
        NotificationCenter.default.post(name:NSNotification.Name(rawValue: "Notify"), object: self)
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        guard let descriptors = characteristic.descriptors else { return }
            
        descriptors.forEach { descript in
            print("function name: DidDiscoverDescriptorForChar \(String(describing: descript.description))")
            print("Rx Value \(String(describing: rxCharacteristic?.value))")
            print("Tx Value \(String(describing: txCharacteristic?.value))")

        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("*******************************************************")
        
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }
    
    //Table View Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        //Connect to device where the peripheral is connected
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! PeripheralTableViewCell
        let peripheral = self.peripherals[indexPath.row]
        let RSSI = self.RSSIs[indexPath.row]
        
        
        if peripheral.name == nil {
            cell.peripheralLabel.text = "nil"
        } else {
            cell.peripheralLabel.text = peripheral.name
        }
        cell.rssiLabel.text = "RSSI: \(RSSI)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        blePeripheral = peripherals[indexPath.row]
        connectToDevice()
    }
    
    
    //Data
    var centralManager : CBCentralManager!
    var RSSIs = [NSNumber]()
    var data = NSMutableData()
    var writeData: String = ""
    var peripherals: [CBPeripheral] = []
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    var characteristics = [String : CBCharacteristic]()
    
    @IBOutlet weak var baseTableView: UITableView!
    
    @IBOutlet weak var DarkModeLabel: UILabel!
    @IBOutlet weak var DarkModeControl: UISegmentedControl!
    @IBOutlet weak var ScrollView: UIScrollView!
    
    @IBOutlet weak var solveTypeLabel: UILabel!
    @IBOutlet weak var solveTypeControl: UISegmentedControl!
    // checked for when view disappears, no point updating every time it changes
    
    @IBOutlet weak var TimingControl: UISegmentedControl!
    @IBOutlet weak var InspectionControl: UISegmentedControl!
    
    @IBOutlet weak var HoldingTimeLabel: UILabel!
    @IBOutlet weak var HoldingTimeSlider: UISlider!
    
    @IBOutlet var eventCollection: [UIButton]!
    
    @IBOutlet var cuberCollection: [UIButton]!
    
    @IBOutlet var TopButtons: [UIButton]!
    
    @IBOutlet var TopLabels: [UILabel]!
    
    @IBOutlet var BigView: UIView!
    @IBOutlet weak var LittleView: UIView!
    
    
    @IBOutlet weak var CuberButton: UIButton!
    @IBOutlet weak var ScrambleTypeButton: UIButton!
    
    @IBOutlet weak var InspectionVoiceAlertsControl: UISegmentedControl!
    @IBOutlet weak var TimerUpdateControl: UISegmentedControl!
    
    @IBOutlet weak var VersionLabel: UILabel!
    
    @IBOutlet weak var WebsiteButton: UIButton!
    
    @IBOutlet weak var EmailButton: UIButton!
    
    var cuberDictionary = ["Bill" : "Bill Wang", "Lucas" : "Lucas Etter", "Feliks" : "Feliks Zemdegs", "Kian" : "Kian Mansour", "Random" : NSLocalizedString("Random", comment: ""), "Rami" : "Rami Sbahi", "Patrick" : "Patrick Ponce", "Max" : "Max Park", "Kevin" : "Kevin Hays"]
    
    let realm = try! Realm()
    
    @IBAction func DarkModeChanged(_ sender: Any) {
        HomeViewController.changedDarkMode = true
        if(!HomeViewController.darkMode) // not dark, set to dark
        {
            HomeViewController.darkMode = true
            makeDarkMode()
        }
        else // dark, turn off
        {
            HomeViewController.darkMode = false
            turnOffDarkMode()
        }
    }
    
    @IBAction func TimingChanged(_ sender: Any) {
        HomeViewController.timing = TimingControl.selectedSegmentIndex
        if(HomeViewController.timing != 1)
        {
            InspectionControl.isEnabled = false
            InspectionVoiceAlertsControl.isEnabled = false
            if(HomeViewController.timing == 2)
            {
                //`startScan()
            }
        }
        else
        {
            InspectionControl.isEnabled = true
            if(HomeViewController.inspection)
            {
                InspectionVoiceAlertsControl.isEnabled = true
            }
        }
    }
    
    @IBAction func WebsiteButtonTouched(_ sender: Any) {
        guard let url = URL(string: "http://www.compsim.net") else {
          return //be safe
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBAction func EmailButtonTouched(_ sender: Any) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["compsimcubing@gmail.com"])
            mail.setSubject("CompSim Inquiry")
            mail.setMessageBody("<p>Dear CompSim,</p>", isHTML: true)

            present(mail, animated: true)
        } else {
            print("fail")
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    @IBAction func InspectionChanged(_ sender: Any) {
        if(HomeViewController.inspection)
        {
            HomeViewController.inspection = false
            InspectionVoiceAlertsControl.isEnabled = false
        }
        else
        {
            HomeViewController.inspection = true
            InspectionVoiceAlertsControl.isEnabled = true
        }
    }
    
    @IBAction func InspectionVoiceAlertsChanged(_ sender: Any) {
        HomeViewController.inspectionSound = !HomeViewController.inspectionSound
    }
    
    func makeDarkMode()
    {
        BigView.backgroundColor = HomeViewController.darkModeColor()
        LittleView.backgroundColor = HomeViewController.darkModeColor()
        ScrollView.backgroundColor = HomeViewController.darkModeColor()
        TopButtons.forEach{ (button) in
        
            button.backgroundColor = UIColor.darkGray
        }
        TopLabels.forEach{ (label) in
        
            label.backgroundColor = UIColor.darkGray
        }
        
        
        for control in [DarkModeControl, TimingControl, InspectionControl, TimerUpdateControl, solveTypeControl, InspectionVoiceAlertsControl]
        {
            control!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "Futura", size: 13)!], for: .normal)
        }
        
        VersionLabel.textColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        updateStatusBarBackground()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        updateStatusBarBackground()
    }
    
    func updateStatusBarBackground()
    {
        if #available(iOS 13.0, *) {
            let statusBar = UIView(frame: view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
            statusBar.backgroundColor = HomeViewController.darkMode ?  HomeViewController.darkModeColor() : .white
             view.addSubview(statusBar)
        }
    }
    
    func turnOffDarkMode()
    {
        BigView.backgroundColor = .white
        LittleView.backgroundColor = .white
        ScrollView.backgroundColor = .white
        TopButtons.forEach{ (button) in
        
            button.backgroundColor = HomeViewController.darkBlueColor()
        }
        TopLabels.forEach{ (label) in
            label.backgroundColor = HomeViewController.darkBlueColor()
        }
        
        for control in [DarkModeControl, TimingControl, InspectionControl, TimerUpdateControl, solveTypeControl, InspectionVoiceAlertsControl]
        {
            control!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont(name: "Futura", size: 13)!], for: .normal)
        }
        
        VersionLabel.textColor = .black
        setNeedsStatusBarAppearanceUpdate()
        updateStatusBarBackground()
    }
    
    
    
    @IBAction func handleSelection(_ sender: UIButton) // clicked select
    {
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func handleCuberSelection(_ sender: Any) {
        
        cuberCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    override func viewDidLoad() // only need to do these things when lose instance anyways, so call in view did load (selected index wont change when go between tabs)
    {
        self.baseTableView.delegate = self
        self.baseTableView.dataSource = self
        if HomeViewController.timing == 2
        {
            self.baseTableView.reloadData()
        }
        /*Our key player in this app will be our CBCentralManager. CBCentralManager objects are used to manage discovered or connected remote peripheral devices (represented by CBPeripheral objects), including scanning for, discovering, and connecting to advertising peripherals.
         */
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        
        cuberDictionary["Aleatorio"] = NSLocalizedString("Random", comment: "") // need to go through each
        if(cuberDictionary[NSLocalizedString("Random", comment: "")] == nil)
        {
            cuberDictionary[NSLocalizedString("Random", comment: "")] = NSLocalizedString("Random", comment: "")
        }
        if(HomeViewController.darkMode)
        {
            DarkModeControl.selectedSegmentIndex = 0
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
        TimingControl.selectedSegmentIndex = HomeViewController.timing
        if(HomeViewController.timing != 1)
        {
            InspectionControl.isEnabled = false
        }
        
        if(HomeViewController.timing != 1 || !HomeViewController.inspection)
        {
            InspectionVoiceAlertsControl.isEnabled = false
        }
        
        if(HomeViewController.inspection)
        {
            InspectionControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionControl.selectedSegmentIndex = 1
        }
        
        if(HomeViewController.inspectionSound)
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 1
        }
        
        let cuber = NSLocalizedString("Cuber", comment: "")
        CuberButton.setTitle("\(cuber): \(cuberDictionary[HomeViewController.cuber]!)", for: .normal)
        
        HoldingTimeSlider.value = HomeViewController.holdingTime
        let holdingTime = NSLocalizedString("Holding Time", comment: "")
        HoldingTimeLabel.text = String(format: "\(holdingTime): %.2f", HomeViewController.holdingTime)
        
        TimerUpdateControl.selectedSegmentIndex = HomeViewController.timerUpdate
        
        WebsiteButton.setTitle(NSLocalizedString("Website", comment: ""), for: .normal)
        EmailButton.setTitle(NSLocalizedString("Email", comment: ""), for: .normal)
        VersionLabel.text = NSLocalizedString("Version", comment: "") + ": \(appVersion)"
        
        super.viewDidLoad()
        
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let eventNames = ["2x2x2", "3x3x3", "4x4x4", "5x5x5", "6x6x6", "7x7x7", "Pyraminx", "Megaminx", "Square-1", "Skewb", "Clock", "3x3x3 BLD"]
        let title = eventNames[HomeViewController.mySession.scrambler.myEvent]
        let scrType = NSLocalizedString("Scramble Type", comment: "")
        ScrambleTypeButton.setTitle("\(scrType): \(title)", for: .normal)
        
        
        
        super.viewWillAppear(false)
        eventCollection.forEach { (button) in
            button.isHidden = true
        }
        
        
        solveTypeControl.isEnabled = HomeViewController.mySession.currentIndex < 1
        solveTypeControl.selectedSegmentIndex = HomeViewController.mySession.solveType
    }
    
    @IBAction func HoldingTimeChanged(_ sender: Any) {
        
        let roundedTime = round(HoldingTimeSlider.value * 20) / 20 // 0.29 --> 0.3, 0.27 --> 0.25
        let holdingTime = NSLocalizedString("Holding Time", comment: "")
        HoldingTimeLabel.text = String(format: "\(holdingTime): %.2f", roundedTime)
        HomeViewController.holdingTime = roundedTime
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(false)
        
        try! realm.write {
            HomeViewController.mySession.solveType = solveTypeControl.selectedSegmentIndex
        }
        
        HomeViewController.timerUpdate = TimerUpdateControl.selectedSegmentIndex
        
        print("Stop Scanning")
        centralManager?.stopScan()
    }
    
    enum Events: String
    {
        case twoCube = "2x2x2"
        case threeCube = "3x3x3"
        case fourCube = "4x4x4"
        case fiveCube = "5x5x5"
        case sixCube = "6x6x6"
        case sevenCube = "7x7x7"
        case pyra = "Pyraminx"
        case mega = "Megaminx"
        case sq1 = "Square-1"
        case skewb = "Skewb"
        case clock = "Clock"
        case BLD = "3x3x3 BLD"
    }
    
    
    @IBAction func cuberTapped(_ sender: UIButton) {
        
        cuberCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        let cuber = NSLocalizedString("Cuber", comment: "")
        CuberButton.setTitle("\(cuber): \(title)", for: .normal)
        
        let nameArr = title.components(separatedBy: " ")
        HomeViewController.cuber = nameArr[0]
    }
    
    
    @IBAction func eventTapped(_ sender: UIButton) {
        
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle, let event = Events(rawValue: title) else
        {
            return // doesn't have title
        }
        
        let scrType = NSLocalizedString("Scramble Type", comment: "")
        ScrambleTypeButton.setTitle("\(scrType): \(title)", for: .normal)
        
        try! realm.write
        {
            switch event
            {
                case .twoCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 0)
                case .threeCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 1)
                case .fourCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 2)
                case .fiveCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 3)
                case .sixCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 4)
                case .sevenCube:
                    HomeViewController.mySession.doEvent(enteredEvent: 5)
                case .pyra:
                    HomeViewController.mySession.doEvent(enteredEvent: 6)
                case .mega:
                    HomeViewController.mySession.doEvent(enteredEvent: 7)
                case .sq1:
                    HomeViewController.mySession.doEvent(enteredEvent: 8)
                case .skewb:
                    HomeViewController.mySession.doEvent(enteredEvent: 9)
                case .clock:
                    HomeViewController.mySession.doEvent(enteredEvent: 10)
                case .BLD:
                    HomeViewController.mySession.doEvent(enteredEvent: 11)
            }
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if #available(iOS 13.0, *)
        {
            if HomeViewController.darkMode
            {
                return .lightContent
            }
            
        }
        
        return .default
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
