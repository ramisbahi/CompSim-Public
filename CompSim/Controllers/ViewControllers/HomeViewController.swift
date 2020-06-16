//
//  ViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift
import CoreBluetooth

extension String {
    /// stringToFind must be at least 1 character.
    func countInstances(of stringToFind: String) -> Int {
        assert(!stringToFind.isEmpty)
        var count = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: stringToFind, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }
}

class HomeViewController: UIViewController, CBPeripheralManagerDelegate {
    @IBOutlet var BigView: UIView!
    
    @IBOutlet weak var ScrambleArea: UIView!
    @IBOutlet weak var GestureArea: UIView!
    
    @IBOutlet weak var DrawScrambleView: UIView!
    
    @IBOutlet weak var Time1: UIButton!
    @IBOutlet weak var Time2: UIButton!
    @IBOutlet weak var Time3: UIButton!
    @IBOutlet weak var Time4: UIButton!
    @IBOutlet weak var Time5: UIButton!
    
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var NewScrambleButton: UIButton!
    @IBOutlet weak var HelpButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    @IBOutlet weak var ScrambleLabel: UILabel!
    
    @IBOutlet weak var TimerLabel: UILabel!
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    @IBOutlet weak var MicButton: UIButton!
    
    @IBOutlet weak var Logo: UIImageView!
    
    static var scrambleChanged = false
    
    var labels = [UIButton]()
    var peripheralManager: CBPeripheralManager?
    
    // settings stuff
    
    static var darkMode = false
    static var changedDarkMode = false
    
    static var timing = 1
    static var inspection = true
    
    static var cuber = NSLocalizedString("Random", comment: "")
    
    static var holdingTime: Float = 0.55 
    
    static var mySession = Session(name: "3x3", enteredEvent: 1)
    static var allSessions: [Session] = [HomeViewController.mySession]
    
    static var timerUpdate = 0 // 0 = update, 1 = seconds, 2 = none
    
    static var justOpened = true
    static var sessionChanged = false
    
    static var inspectionSound = true
    
    let IDLE = 0
    let FROZEN = 2
    let READY = 3
    static var timerPhase = 0 // IDLE
    
    static var longPress = UILongPressGestureRecognizer()
    
    static var font: UIFont? = nil
    
    static var deviceName: String = ""
    
    static var totalAverages: Int = 0 // for keeping track of user engagement
    
    let realm = try! Realm()
    
    struct Keys
    {
        static let darkMode = "darkMode"
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    static func hasSetSettings() -> Bool // one must be true
    {
        return UserDefaults.standard.bool(forKey: AppDelegate.hasSet)
    }
    
    override func viewDidLayoutSubviews() {
        HelpButton.layer.cornerRadius = HelpButton.frame.size.height / 2.0
        
        var stringSize = NewScrambleButton.titleLabel?.intrinsicContentSize.width
        NewScrambleButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
        if(NewScrambleButton.frame.size.width > 150)
        {
            NewScrambleButton.setTitle(NSLocalizedString("New Scr.", comment: ""), for: .normal)
            stringSize = NewScrambleButton.titleLabel?.intrinsicContentSize.width
            NewScrambleButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
        }
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if HomeViewController.timing == 2
        {
            peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            //-Notification for updating the text view with incoming text
            updateIncomingData()
        }
        
        TimerViewController.initializeFormatters() // have to do this once in a while....
        
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.gestureSetup()
        self.labels = [Time1, Time2, Time3, Time4, Time5] // add labels to labels array - one time thing
        
        if(HomeViewController.justOpened)
        {
            if HomeViewController.hasSetSettings()
            {
                doSettings()
                HomeViewController.justOpened = false
            }
        }
        
        if(TimerViewController.resultTime != 0) // returned from timer
        {
            self.updateTimes(enteredTime: TimerViewController.resultTime.format(allowsFractionalUnits: true)!, penalty: TimerViewController.penalty)
            TimerViewController.penalty = 0
            TimerViewController.resultTime = 0
        }
        else
        {
            self.updateLabels()
            if AverageDetailViewController.justReturned // just returned from avgdetail
            {
                AverageDetailViewController.justReturned = false
            }
        }
        
        
        if(HomeViewController.darkMode) // dark
        {
            makeDarkMode()
        }
        else // light
        {
            turnOffDarkMode()
        }
        
        if(HomeViewController.font == nil) // not set yet
        {
            HomeViewController.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.09, name: "Futura")
        }
        
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = HomeViewController.font
        }
        ScrambleLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.05, name: "System")
        TimerLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Geeza Pro")
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
           if peripheral.state == .poweredOn {
               return
           }
           print("Peripheral manager is running")
       }
       
    //Check when someone subscribe to our characteristic, start sending the data
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("Device subscribe to characteristic")
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("\(error)")
            return
        }
    }
    
    func updateIncomingData () {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil){
            notification in
            print("[Incoming]: " + (characteristicASCIIValue as String))
            
        }
    }
    
    @available(iOS 13.0, *)
    @IBAction func MicTapped(_ sender: Any) {
       // ViewController.usingMic ? turnOffMic(changeStatus: true) : turnOnMic()
        
    }
    
    static func fontToFitWidth(text: String, view: UIView, multiplier: Float, name: String) -> UIFont
    {
        let minFontSize: CGFloat = 1.0 // CGFloat 18
        let maxFontSize: CGFloat = 300.0     // CGFloat 67
        var fontSize = maxFontSize
        var textWidth: CGFloat = 0.0
        if(name == "System")
        {
            textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]).width
        }
        else
        {
            textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: fontSize)!]).width
        }
        let width = view.frame.size.width
        let multWidth = width * CGFloat(multiplier)
        print("width \(width)")
        
        while (textWidth > multWidth && fontSize > minFontSize) {
                fontSize -= 1
            if(name == "System")
            {
                textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]).width
            }
            else
            {
                textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: fontSize)!]).width
            }
        }
        
        if(name == "System")
        {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return UIFont(name: name, size: fontSize)!
    }
    

    static func fontToFitHeight(view: UIView, multiplier: Float, name: String) -> UIFont
    {
        let minFontSize: CGFloat = 1.0 // CGFloat 18
        let maxFontSize: CGFloat = 300.0     // CGFloat 67
        var fontSize = maxFontSize
        let text: NSString = "1.59"
        var textHeight: CGFloat = 0.0
        if(name == "System")
        {
            textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]).height
        }
        else
        {
            textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: fontSize)!]).height
        }
        let height = view.frame.size.height
        let multHeight = height * CGFloat(multiplier)
        
        while (textHeight > multHeight && fontSize > minFontSize) {
                fontSize -= 1
            if(name == "System")
            {
                textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)]).height
            }
            else
            {
                textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: fontSize)!]).height
            }
            }
        
        if(name == "System")
        {
            return UIFont.systemFont(ofSize: fontSize)
        }
        return UIFont(name: name, size: fontSize)!
    }
    
    @IBAction func HelpPressed(_ sender: Any) {
        segueToHelp()
    }
    
    func segueToHelp()
    {
       let obj = (self.storyboard?.instantiateViewController(withIdentifier: "HelpViewController"))!

       let transition:CATransition = CATransition()
       transition.duration = 0.3
       transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
       transition.type = .push
       transition.subtype = .fromRight
   
   
       self.navigationController!.view.layer.add(transition, forKey: kCATransition)
       self.navigationController?.pushViewController(obj, animated: true)
    }
    
    override func viewWillLayoutSubviews() {
        let stringSize = ResetButton.titleLabel?.intrinsicContentSize.width
        ResetButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        if(HomeViewController.changedDarkMode) // changed it - only have to do this once when changed
        {
            HomeViewController.darkMode ? makeDarkMode() : turnOffDarkMode()
            HomeViewController.changedDarkMode = false
        }
        
        if(HomeViewController.sessionChanged)
        {
            updateLabels()
            HomeViewController.mySession.scrambler.genScramble()
            ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
            HomeViewController.sessionChanged = false
        }
        else
        {
            ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        }
        HomeViewController.timerPhase = self.IDLE
        
        if(usingLongPress())
        {
            GestureArea.removeGestureRecognizer(HomeViewController.longPress) // not sure if necessary
            HomeViewController.longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
            HomeViewController.longPress.allowableMovement = 50
            HomeViewController.longPress.minimumPressDuration = TimeInterval(HomeViewController.holdingTime)
            HomeViewController.longPress.cancelsTouchesInView = false
            GestureArea.addGestureRecognizer(HomeViewController.longPress)
        }
        else // inspection or 0.0+noinspection
        {
            GestureArea.removeGestureRecognizer(HomeViewController.longPress)
        }
        
    }
    
    
    func gestureSetup()
    {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToGesture(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeUp.direction = .up // ...when up swipe is done
        GestureArea.addGestureRecognizer(swipeUp) // allow view to recognize
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeDown.direction = .down // ...when down swipe is done
        GestureArea.addGestureRecognizer(swipeDown) // allow view to recognize
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:)))
        GestureArea.addGestureRecognizer(tap)
        
        let tapScramble = UITapGestureRecognizer(target: self, action: #selector(scrambleTapped(gesture:)))
        ScrambleArea.addGestureRecognizer(tapScramble)
    }
    
    @objc func scrambleTapped(gesture: UIGestureRecognizer)
    {
        if(HomeViewController.mySession.scrambler.myEvent == 1)
        {
            DrawScrambleView.isHidden = !DrawScrambleView.isHidden
        }
        else
        {
            DrawScrambleView.isHidden = true
            self.respondToGesture(gesture: gesture)
        }
    }
    
    @objc func handleLongPress(sender: UIGestureRecognizer)
    {
        if(sender.state == .began) // reached holding time
        {
            if HomeViewController.timerPhase == self.IDLE
            {
                TimerLabel.isHidden = false
                HomeViewController.timerPhase = self.FROZEN
            }
            else
            {
                TimerLabel.textColor = .green
                HomeViewController.timerPhase = self.READY
            }
        }
        else if(sender.state == .cancelled)
        {
            cancelTimer()
        }
        else if(sender.state == .ended && HomeViewController.timerPhase == self.READY) // did holding time, released
        {
            self.performSegue(withIdentifier: "timerSegue", sender: self)
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if(usingLongPress())
        {
            cancelTimer()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        var inGestureArea = false
        for touch in touches
        {
            if(touch.location(in: GestureArea).y > 0)
            {
                inGestureArea = true
            }
        }
        
        if inGestureArea && usingLongPress() && HomeViewController.timerPhase == self.IDLE
        {
            TimerLabel.isHidden = false
            HomeViewController.timerPhase = self.FROZEN
            hideAll()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) // released before minimum hold time
    {
        if(usingLongPress() && HomeViewController.timerPhase == FROZEN)
        {
            cancelTimer()
        }
    }
    
    
    
    func hideAll()
    {
        TimesCollection.forEach{ (button) in
            button.isHidden = true
        }
        ScrambleLabel.isHidden = true
        
    }
    
    func showAll()
    {
        //print("showing all")
        updateLabels()
        ScrambleLabel.isHidden = false
        //TODO: show everything that should show
    }
    
    func cancelTimer()
    {
        //print("cancelling")
        TimerLabel.isHidden = true
        HomeViewController.timerPhase = IDLE
        showAll()
    }
    
    func removeGestures()
    {
        
        for recognizer in GestureArea.gestureRecognizers!
        {
            GestureArea.removeGestureRecognizer(recognizer)
        }
        
        // then re-add... improve this
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeDown.direction = .down // ...when down swipe is done
        GestureArea.addGestureRecognizer(swipeDown) // allow view to recognize
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Reset Average?", comment: ""), completion: {
            self.reset()
        })
        self.present(alert, animated: true)
    }
    
    @IBAction func newScramblePressed(_ sender: Any) {
        HomeViewController.mySession.scrambler.genScramble()
        ScrambleLabel.text = HomeViewController.mySession.scrambler.currentScramble
    }
    
    func usingLongPress() -> Bool
    {
        return !HomeViewController.inspection && HomeViewController.holdingTime > 0.01 && HomeViewController.timing == 1
    }
    
    func reset()
    {
        try! realm.write
        {
            HomeViewController.mySession.reset()
        }
        ScrambleLabel.text = String(HomeViewController.mySession.getCurrentScramble()) // next scramble
        updateLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        
    }
    
    func alertValidTime(alertMessage: String)
    {
        let alertService = NotificationAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Invalid Time", comment: ""))
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    @objc func respondToGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch(swipeGesture.direction)
            {
                case .up:
                    addSolve()
                case .down:
                    if(HomeViewController.mySession.times.count > 0)
                    {
                        deleteSolve()
                    }
                default:
                    break
            }
        }
        else if HomeViewController.timing == 1 && (HomeViewController.inspection || HomeViewController.holdingTime < 0.01) // tap gesture, timing
        {
            //print("tapped")
            self.performSegue(withIdentifier: "timerSegue", sender: self)
        }
        else if HomeViewController.timing == 0 // not timing... addsolve
        {
            addSolve()
        }
    }
    
    func deleteSolve()
    {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Delete Last Solve?", comment: ""),
                                       completion: {
            
            try! self.realm.write
            {
                HomeViewController.mySession.deleteSolve()
            }
            self.ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
            self.updateLabels()
        })
        
        self.present(alert, animated: true)
    }
    
    func addSolve()
    {
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: NSLocalizedString("Time", comment: ""), usingPenalty: true, keyboardType: 0, myTitle: NSLocalizedString("Add Solve", comment: ""),
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            let penalties = [2, 0, 1] // adjust for index
            let inputPenalty = penalties[alertService.myVC.PenaltySelector.selectedSegmentIndex]
            
            if HomeViewController.validEntryTime(time: inputTime)
            {
                self.updateTimes(enteredTime: inputTime, penalty: inputPenalty) // add time, show label, change parentheses
            }
            else
            {
                self.alertValidTime(alertMessage: NSLocalizedString("Please enter valid time", comment: ""))
            }
        })
        
        self.present(alert, animated: true)
    }
    
    static func validEntryTime(time: String) -> Bool
    {
        if let _ = Float(time.replacingOccurrences(of: ",", with: "."))
        {
            return true
        }
        return false
    }
    
    // double is entered, converted to int for hundredth precision (i.e. 4.0 will become 400 now)
    // converted to string for proper representation (i.e. 4.0 will become 4.00 now)
    
    func updateTimes(enteredTime: String, penalty: Int)
    {
        try! realm.write
        {
            HomeViewController.mySession.addSolve(time: enteredTime, penalty: penalty)
        }
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble() // change scramble
        
        updateLabels()
    }
    
    func updateTimes(enteredTime: String)
    {
        try! realm.write
        {
            HomeViewController.mySession.addSolve(time: enteredTime)
        }
        
        
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble() // change scramble
        
        updateLabels()
        
    }
  
    func updateLabels()
    {
        for i in 0..<HomeViewController.mySession.currentIndex
        {
            self.labels[i].setTitle(HomeViewController.mySession.times[i].myString, for: .normal)
            self.labels[i].isHidden = false
            if i != HomeViewController.mySession.currentIndex-1
            {
                self.labels[i].isEnabled = false
                
            }
            else
            {
                self.labels[i].isEnabled = true
            }
        }
        for i in HomeViewController.mySession.currentIndex..<5
        {
            self.labels[i].isHidden = true
        }
        
        if(HomeViewController.mySession.currentIndex == 5) || HomeViewController.mySession.currentIndex == 3 && HomeViewController.mySession.solveType > 0
        {
            self.performSegue(withIdentifier: "viewControllerToResult", sender: self)
        }
        else
        {
            ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble() // change scramble
            Logo.isHidden = true
        }
        
    }
    
    @IBAction func Time1Touched(_ sender: Any) {
        
        self.showScramble(num: 0)
    }
    
    @IBAction func Time2Touched(_ sender: Any) {
        self.showScramble(num: 1)
    }
    
    @IBAction func Time3Touched(_ sender: Any) {
        self.showScramble(num: 2)
    }
    
    @IBAction func Time4Touched(_ sender: Any) {
        self.showScramble(num: 3)
    }
    
    @IBAction func Time5Touched(_ sender: Any) {
        self.showScramble(num: 4)
    }
    
    func showScramble(num: Int)
    {
        let myTitle = self.labels[num].titleLabel!.text
        let myScramble = HomeViewController.mySession.times[num].myScramble
        let myPenalty = HomeViewController.mySession.times[num].penalty
        
        let alertService = ViewSolveAlertService()
        let alert = alertService.alert(usingPenalty: true, delete: true, title: myTitle!, scramble: myScramble, penalty: myPenalty, completion:
            {
                let penalties = [2, 0, 1] // adjust for index
                let inputPenalty = penalties[alertService.myVC.PenaltySelector.selectedSegmentIndex]
                try! self.realm.write
                {
                    HomeViewController.mySession.changePenaltyStatus(index: num, penalty: inputPenalty)
                }
                self.updateLabels()
            }, deletion:
            {
                self.deleteSolve()
            }
        )
        
        self.present(alert, animated: true)
    }
    
    func makeDarkMode()
    {
        BigView.backgroundColor = HomeViewController.darkModeColor()
        ScrambleArea.backgroundColor = HomeViewController.darkModeColor()
        GestureArea.backgroundColor = HomeViewController.darkModeColor()
        ScrambleLabel.textColor? = UIColor.white
        TimesCollection.forEach { (button) in
            button.setTitleColor(.white, for: .disabled)
            button.setTitleColor(HomeViewController.orangeColor(), for: .normal) // orange
        }
        
        HelpButton.backgroundColor = .darkGray
        HelpButton.tintColor = .white
        ResetButton.backgroundColor = .darkGray
        ResetButton.titleLabel?.textColor = .white
        NewScrambleButton.backgroundColor = .darkGray
        NewScrambleButton.titleLabel?.textColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 13.0, *) {
            updateStatusBarBackground()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 13.0, *)
    func updateStatusBarBackground()
    {
        let statusBar = UIView(frame: view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
        statusBar.backgroundColor = HomeViewController.darkMode ?  HomeViewController.darkModeColor() : .white
         view.addSubview(statusBar)
    }
    
    func turnOffDarkMode()
    {
        ScrambleArea.backgroundColor = .white
        GestureArea.backgroundColor = .white
        BigView.backgroundColor = .white
        ScrambleLabel.textColor = UIColor.black
        TimesCollection.forEach { (button) in
            button.setTitleColor(.black, for: .disabled)
            if #available(iOS 13.0, *) {
                button.setTitleColor(UIColor.link, for: .normal)
            } else {
                button.setTitleColor(UIColor(displayP3Red: 0, green: 122.0/255, blue: 1, alpha: 1.0), for: .normal)
                // Fallback on earlier versions
            } // link
        }
        
        HelpButton.backgroundColor = HomeViewController.darkBlueColor()
        HelpButton.tintColor = .white //HomeViewController.darkBlueColor()
        ResetButton.backgroundColor = HomeViewController.darkBlueColor()
        ResetButton.titleLabel?.textColor = .white
        NewScrambleButton.backgroundColor = HomeViewController.darkBlueColor()
        NewScrambleButton.titleLabel?.textColor = .white
        
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 13.0, *) {
            updateStatusBarBackground()
        } else {
            // Fallback on earlier versions
        }
        
    }
    
    func doSettings()
    {
        HomeViewController.darkMode = UserDefaults.standard.bool(forKey: AppDelegate.darkMode)
        HomeViewController.cuber = UserDefaults.standard.string(forKey: AppDelegate.cuber) ?? "Random"
        HomeViewController.timing = UserDefaults.standard.integer(forKey: AppDelegate.timing)
        HomeViewController.inspection = UserDefaults.standard.bool(forKey: AppDelegate.inspection)
        HomeViewController.holdingTime = UserDefaults.standard.float(forKey: AppDelegate.holdingTime)
        HomeViewController.timerUpdate = UserDefaults.standard.integer(forKey: AppDelegate.timerUpdate)
        HomeViewController.mySession.scrambler.doEvent(event: UserDefaults.standard.integer(forKey: AppDelegate.event))
        if(HomeViewController.hasSetSettings())
        {
            HomeViewController.totalAverages = UserDefaults.standard.integer(forKey: AppDelegate.totalAverages)
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if HomeViewController.darkMode
        {
            return .lightContent
        }
        return .default
    }
    
    static func orangeColor() -> UIColor
    {
        return UIColor(displayP3Red: 255/255, green: 165/255, blue: 61/255, alpha: 1.0)
    }
    
    static func blueColor() ->  UIColor
    {
        return UIColor.init(displayP3Red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
    }
    
    static func darkBlueColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 8/255, green: 4/255, blue: 68/255, alpha: 1)
    }
    
    static func greenColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 0/255, green: 175/255, blue: 0/255, alpha: 1)
    }
    
    static func darkModeColor() -> UIColor
    {
        return UIColor.init(red: 29/250, green: 29/250, blue: 29/250, alpha: 1)
    }
    
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
    return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
    guard let input = input else { return nil }
    return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
