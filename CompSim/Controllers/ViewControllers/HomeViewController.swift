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

extension HomeViewController: UIPageViewControllerDelegate
{
   
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        print("current page index \(currentPageIndex)")
        return currentPageIndex
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 2
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if #available(iOS 13.0, *), viewController is DrawScrambleViewController
        {
            let scrambleViewController =  storyboard?.instantiateViewController(identifier: String(describing: ScrambleViewController.self)) as? ScrambleViewController
            scrambleViewController?.scrambleText = HomeViewController.mySession.getCurrentScramble()
            return scrambleViewController
        }
        else
        {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?
    {
        if #available(iOS 13.0, *), viewController is ScrambleViewController
        {
            let newVC =  storyboard?.instantiateViewController(identifier: String(describing: DrawScrambleViewController.self)) as? DrawScrambleViewController
            
            myDrawScrambleViewController = newVC
            
            return newVC
        }
        else
        {
            return nil
        }
    }
    
}

class HomeViewController: UIViewController, CBPeripheralManagerDelegate, UIPageViewControllerDataSource {
    @IBOutlet var BigView: UIView!
    
    @IBOutlet weak var GestureArea: UIView!
    

    @IBOutlet weak var SessionStackView: UIStackView!
    @IBOutlet weak var SessionButton: UIButton!
    var SessionCollection: [UIButton] = []
    
    @IBOutlet weak var Time1: UIButton!
    @IBOutlet weak var Time2: UIButton!
    @IBOutlet weak var Time3: UIButton!
    @IBOutlet weak var Time4: UIButton!
    @IBOutlet weak var Time5: UIButton!
    
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var HelpButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    @IBOutlet weak var TimerLabel: UILabel!
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    @IBOutlet weak var ScrambleContentView: UIView!
    
    @IBOutlet weak var MicButton: UIButton!
    
    @IBOutlet weak var Logo: UIImageView!
    
    static var scrambleChanged = false
    
    var currentPageIndex = 0
    
    var labels = [UIButton]()
    
    var peripheralManager: CBPeripheralManager?
    
    // settings stuff
    
    @IBOutlet weak var TargetLabel: UIButton!
    
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
    
    var holdStartTime: UInt64 = 0
    
    var observer: NSObjectProtocol?
    
    var myPageViewController: ScramblePageViewController?
    var myScrambleViewController: ScrambleViewController?
    var myDrawScrambleViewController: DrawScrambleViewController?
    
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
        super.viewDidLayoutSubviews()
        

        
        HelpButton.layer.cornerRadius = HelpButton.frame.size.height / 3.5
        
        
        ScrambleContentView.layer.cornerRadius = 6.0
        
        ScrambleContentView.layer.borderWidth = 1
        ScrambleContentView.layer.borderColor = HomeViewController.darkBlueColor().cgColor
        
        
 
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        configurePageViewController()
        
        // Do any additional setup after loading the view.
        print("loaded, going to set peripheral manager")
        
        
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
            //-Notification for updating the text view with incoming text
        
        
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
            HomeViewController.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.09, name: "Lato-Black")
        }
        
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = HomeViewController.font
        }
        //ScrambleLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.05, name: "System")
        TimerLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Lato-Regular")
    }
    
    func configurePageViewController()
    {
        guard let pageViewController = storyboard?.instantiateViewController(withIdentifier: String(describing: ScramblePageViewController.self)) as? ScramblePageViewController else
        {
            return
        }
    
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        self.addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        pageViewController.view.layer.position.y = -10.0
        
        ScrambleContentView.addSubview(pageViewController.view)
        
        let views: [String : Any] = ["pageView" : pageViewController.view as Any]

        ScrambleContentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
    
        let topShift = BigView.frame.size.height * 3.0 / 65.0
        let bottomShift = -1 * BigView.frame.size.height / 65.0
        
        let verticalConstraint = "V:|-\(topShift)-[pageView]-(\(bottomShift))-|"
        
        print("vertical constraint " + verticalConstraint)
        
        ScrambleContentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: verticalConstraint, options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
 
        
        
        if #available(iOS 13.0, *)
        {
            guard let scrambleViewController =
                storyboard?.instantiateViewController(identifier: String(describing: ScrambleViewController.self)) as? ScrambleViewController
            else
            {
                return
            }
            
            scrambleViewController.scrambleText = HomeViewController.mySession.getCurrentScramble()
            pageViewController.setViewControllers([scrambleViewController], direction: .forward, animated: true)
            
            self.myPageViewController = pageViewController
            self.myScrambleViewController = scrambleViewController
        }
        else
        {
            return
        }
        
        
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
    
    func updateIncomingData() {
        print("WE ADDING OBSERVER from home")
        observer = NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Notify"), object: nil , queue: nil)
        {
            notification in
            
            let message = characteristicASCIIValue as String
            print("[Incoming from home]: " + message)
            
            if message == "Bravo"
            {
                self.stackmatTouched()
            }
            else if message == "Six"
            {
                self.stackmatReleased()
            }
        }
    }
    
    func removeIncomingData()
    {
        print("removing from home")
        NotificationCenter.default.removeObserver(observer!)
        observer = nil
    }
    
    func stackmatTouched()
    {
        print("BRUH stackmat touched")
        if HomeViewController.timerPhase == self.IDLE
        {
            TimerLabel.isHidden = false
            HomeViewController.timerPhase = self.FROZEN
            print("BRUH going to hide all")
            hideAll()
            
            // make green after holding time
            Timer.scheduledTimer(withTimeInterval:  TimeInterval(HomeViewController.holdingTime), repeats: false) {_ in
                print("BRUH scheduled timer called")
                if HomeViewController.timerPhase == self.FROZEN
                {
                    self.TimerLabel.textColor = .green
                    HomeViewController.timerPhase = self.READY
                }
            }
        }
        
    }
    
    /*
    func pastHoldingTime() -> Bool
    {
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return false  }
        let currentTime = mach_absolute_time()
        let nano = UInt64(currentTime - self.holdStartTime) * UInt64(info.numer) / UInt64(info.denom)
        let timePassed =  Float(nano) / 1000000000.0
        
        return timePassed >= HomeViewController.holdingTime
    }*/
    
    func stackmatReleased()
    {
        if HomeViewController.timerPhase == self.FROZEN
        {
            self.cancelTimer()
        }
        else // if(HomeViewController.timerPhase == self.READY) // did holding time, released
        {
            self.performSegue(withIdentifier: "timerSegue", sender: self)
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
    
    @IBAction func TargetPressed(_ sender: Any) {
     
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: NSLocalizedString("Time", comment: ""), usingPenalty: false, keyboardType: 0, myTitle: NSLocalizedString("Target Time", comment: ""),
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if HomeViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
               let str = temp.myString
               let intTime = temp.intTime
               
                self.TargetLabel.setTitle("  " + str, for: .normal) // set title to string version
               try! self.realm.write
               {
                   HomeViewController.mySession.singleTime = intTime
               }
            }
            else
            {
                self.alertValidTime()
            }
        })
        
        self.present(alert, animated: true)
    }
    
    func alertValidTime()
    {
        let alertService = NotificationAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Invalid Time", comment: ""))
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    
    override func viewWillLayoutSubviews() {
        let stringSize = ResetButton.titleLabel?.intrinsicContentSize.width
        ResetButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
    }
    
    
    @IBAction func SessionButtonClicked(_ sender: Any) {
        if SessionCollection.count > 0
        {
            if SessionCollection[0].isHidden
            {
                SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            }
            else
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
                {
                    self.SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                }
            }
        }
        
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func sessionNamed(title: String) -> Session?
    {
        for session in HomeViewController.allSessions
        {
            if session.name == title
            {
                return session
            }
        }
        return nil
    }
    
    @objc func SessionSelected(_ sender: UIButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
        {
            self.SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        SessionButton.setTitle(title, for: .normal)
        if title != HomeViewController.mySession.name // exists,// not same - so switch session
        {
            HomeViewController.mySession = sessionNamed(title: title)!
            HomeViewController.mySession.updateScrambler()
            updateLabels()
            HomeViewController.mySession.scrambler.genScramble()
            HomeViewController.sessionChanged = false
        }
    }
    
    func createButton(name: String) -> UIButton
    {
        SessionCollection.forEach({button in
            button.layer.cornerRadius = 0.0
        })
        
        let retButton = UIButton(type: .system)
        retButton.setTitle(name, for: .normal)
        retButton.isHidden = true
        retButton.setTitleColor(.white, for: .normal)
        retButton.titleLabel?.font = UIFont(name: "Lato-Black", size: 17)
        retButton.backgroundColor = HomeViewController.darkBlueColor()
        retButton.isUserInteractionEnabled = true
        retButton.addTarget(self, action: #selector(SessionSelected(_:)), for: UIControl.Event.touchUpInside)
        retButton.layer.cornerRadius = 6.0
        retButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        return retButton
    }
    
    // called whenever something changed with sessions
    func setUpStackView()
    {
        SessionButton.setTitle(HomeViewController.mySession.name, for: .normal)
        SessionCollection = []
        for session in HomeViewController.allSessions
        {
            let newButton = createButton(name: session.name)
            SessionCollection.append(newButton)
            SessionStackView.addArrangedSubview(newButton)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        
        setUpStackView()
        
        TargetLabel.setTitle("  \(SolveTime.makeMyString(num: HomeViewController.mySession.singleTime))", for: .normal)
        
        if(HomeViewController.changedDarkMode) // changed it - only have to do this once when changed
        {
            HomeViewController.darkMode ? makeDarkMode() : turnOffDarkMode()
            HomeViewController.changedDarkMode = false
        }
        
        if(HomeViewController.sessionChanged)
        {
            updateLabels()
            HomeViewController.mySession.scrambler.genScramble()
            HomeViewController.sessionChanged = false
        }
        self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
        self.myDrawScrambleViewController?.updateDrawScramble()
        
        
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
        
        if HomeViewController.timing == 2
        {
            updateIncomingData() // moved here
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if(HomeViewController.timing == 2)
        {
            removeIncomingData()
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
        ScrambleContentView.addGestureRecognizer(tapScramble)
 
    }
    
    @objc func scrambleTapped(gesture: UIGestureRecognizer)
    {
        HomeViewController.mySession.scrambler.genScramble()
        self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
        self.myDrawScrambleViewController?.updateDrawScramble()
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
        ScrambleContentView.isHidden = true
        
    }
    
    func showAll()
    {
        //print("showing all")
        updateLabels()
        ScrambleContentView.isHidden = false
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
            self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
            self.myDrawScrambleViewController?.updateDrawScramble()
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
        self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
        self.myDrawScrambleViewController?.updateDrawScramble()
        
        updateLabels()
    }
    
    func updateTimes(enteredTime: String)
    {
        try! realm.write
        {
            HomeViewController.mySession.addSolve(time: enteredTime)
        }
        
        
        self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
        self.myDrawScrambleViewController?.updateDrawScramble()
        
        updateLabels()
        
    }
  
    func updateLabels()
    {
        TargetLabel.setTitle("  \(SolveTime.makeMyString(num: HomeViewController.mySession.singleTime))", for: .normal)
        
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
            self.myScrambleViewController!.updateScrambleLabel(scramble: HomeViewController.mySession.getCurrentScramble())
            self.myDrawScrambleViewController?.updateDrawScramble()
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
        GestureArea.backgroundColor = HomeViewController.darkModeColor()
        //ScrambleLabel.textColor? = UIColor.white
        TimesCollection.forEach { (button) in
            button.setTitleColor(.white, for: .disabled)
            button.setTitleColor(HomeViewController.orangeColor(), for: .normal) // orange
        }
        
        HelpButton.backgroundColor = .darkGray
        HelpButton.tintColor = .white
        ResetButton.backgroundColor = .darkGray
        ResetButton.titleLabel?.textColor = .white
        
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
        GestureArea.backgroundColor = .white
        BigView.backgroundColor = .white
        //ScrambleLabel.textColor = UIColor.black
        TimesCollection.forEach { (button) in
            button.setTitleColor(.black, for: .disabled)
            button.setTitleColor(HomeViewController.orangeColor(), for: .normal)
        }
        
        HelpButton.backgroundColor = HomeViewController.darkBlueColor()
        HelpButton.tintColor = .white //HomeViewController.darkBlueColor()
        ResetButton.backgroundColor = HomeViewController.darkBlueColor()
        ResetButton.titleLabel?.textColor = .white
        
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
        return UIColor(displayP3Red: 242/255, green: 193/255, blue: 78/255, alpha: 1.0)
    }
    
    static func blueColor() ->  UIColor
    {
        return UIColor.init(displayP3Red: 0/255, green: 122/255, blue: 255/255, alpha: 1.0)
    }
    
    static func darkBlueColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 0/255, green: 51/255, blue: 89/255, alpha: 1)
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
