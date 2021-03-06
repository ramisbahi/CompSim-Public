//
//  ViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import WebKit
import RealmSwift
import CoreBluetooth

var pooped = false

let jsURL = Bundle.main.url(forResource: "scramble-display.browser", withExtension: "js")
let draw_events = ["222", "333", "444", "555", "666", "777", "pyram", "minx", "sq1", "skewb", "clock", "333bf"]

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

extension UIView{
    func rotate(duration: CFTimeInterval, radians: Float) {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: radians)
        rotation.duration = duration
        rotation.isCumulative = true
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}

class HomeViewController: UIViewController, UIGestureRecognizerDelegate
{
    @IBOutlet var BigView: UIView!
    
    @IBOutlet weak var GestureArea: UIView!
    
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var SessionStackView: UIStackView!
    @IBOutlet weak var SessionButton: UIButton!
    var SessionCollection: [UIButton] = []
    
    @IBOutlet weak var Time1: UIButton!
    @IBOutlet weak var Time2: UIButton!
    @IBOutlet weak var Time3: UIButton!
    @IBOutlet weak var Time4: UIButton!
    @IBOutlet weak var Time5: UIButton!
    
    @IBOutlet weak var ScrambleLabel: UILabel!
    
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var HelpButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    @IBOutlet weak var RefreshButton: UILabel!
    @IBOutlet weak var TimerLabel: UILabel!
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    @IBOutlet weak var ScrambleContentView: UIView!
    
    @IBOutlet weak var MicButton: UIButton!
    
    @IBOutlet weak var Logo: UIImageView!
    
    @IBOutlet weak var refreshImage: UIImageView!
    
    static var scrambleChanged = false
    
    var currentPageIndex = 0
    
    var labels = [UIButton]()
    
    // settings stuff
    
    @IBOutlet weak var TargetLabel: UIButton!
    
    static var darkMode = false
    static var changedDarkMode = false
    
    static var timing = 0
    static var inspection = true
    
    static var cuber = NSLocalizedString("Random", comment: "") // holds first name of cuber
    
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
    static var webLongPress = UILongPressGestureRecognizer()
    
    static var font: UIFont? = nil
    
    static var deviceName: String = ""
    
    static var totalAverages: Int = 0 // for keeping track of user engagement
    
    let realm = try! Realm()
    
    var holdStartTime: UInt64 = 0
    
    var observer: NSObjectProtocol?
    
    
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
        
        
 
    }
    
    func disableWebZoom()
    {
        let source: String = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=0.5, maximum-scale=0.5, user-scalable=no';
        var head = document.getElementsByTagName('head')[0];
        head.appendChild(meta);
        """
        let zoomDisableScript = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            
        webView.configuration.userContentController.addUserScript(zoomDisableScript)
        webView.scrollView.isScrollEnabled = false
        webView!.isOpaque = false
        webView!.backgroundColor = UIColor.clear
        webView!.scrollView.backgroundColor = UIColor.clear
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        RefreshButton.text = NSLocalizedString("Tap to refresh", comment: "")
        
        disableWebZoom()
        updateDrawScramble()
        
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        
        
        
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
            HomeViewController.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.08, name: "Lato-Bold")
        }
        
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = HomeViewController.font
        }
        ScrambleLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.05, name: "System")
        TimerLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Lato-Regular")
        RefreshButton.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.03, name: "Lato-Regular")
        //TargetLabel.imageView?.backgroundColor = .red
        
        TargetLabel.imageView?.contentMode = .scaleAspectFit
        TargetLabel.contentVerticalAlignment = .fill
        //TargetLabel.contentHorizontalAlignment = .fill
        //TargetLabel.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 15)
    }
    
    static func fontToFitWidth(text: String, view: UIView, multiplier: Float, name: String) -> UIFont
    {
        var minFontSize: CGFloat = 1.0 // CGFloat 18
        var maxFontSize: CGFloat = 300.0     // CGFloat 67
        var currentFontSize: CGFloat = (minFontSize + maxFontSize ) / 2
        var textWidth: CGFloat = 0.0
        if(name == "System")
        {
            textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: currentFontSize)]).width
        }
        else
        {
            textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: currentFontSize)!]).width
        }
        let width = view.frame.size.width
        let multWidth = width * CGFloat(multiplier)
        
        while textWidth != multWidth && abs(maxFontSize - minFontSize) > 0.5
        {
            
            if(name == "System")
            {
                textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: currentFontSize)]).width
            }
            else
            {
                textWidth = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: currentFontSize)!]).width
            }
            
            if multWidth < textWidth
            {
                maxFontSize = currentFontSize
            }
            else // if multWidth > textWidth
            {
                minFontSize = currentFontSize
            }
            
            currentFontSize = (minFontSize + maxFontSize ) / 2
        }
        
        if(name == "System")
        {
            return UIFont.systemFont(ofSize: currentFontSize - 0.1)
        }
        return UIFont(name: name, size: currentFontSize - 0.1)!
    }
    

    static func fontToFitHeight(view: UIView, multiplier: Float, name: String) -> UIFont
    {
        var minFontSize: CGFloat = 1.0 // CGFloat 18
        var maxFontSize: CGFloat = 300.0     // CGFloat 67
        var currentFontSize: CGFloat = (minFontSize + maxFontSize ) / 2
        let text: NSString = "1.59"
        var textHeight: CGFloat = 0.0
        
        if(name == "System")
        {
            textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: currentFontSize)]).height
        }
        else
        {
            textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: currentFontSize)!]).height
        }
        let height = view.frame.size.height
        let multHeight = height * CGFloat(multiplier)
        
        
        while textHeight != multHeight && abs(maxFontSize - minFontSize) > 0.5
        {
            
            if(name == "System")
            {
                textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: currentFontSize)]).height
            }
            else
            {
                textHeight = text.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: name, size: currentFontSize)!]).height
            }
            
            if multHeight < textHeight
            {
                maxFontSize = currentFontSize
            }
            else // if multHeight > textHeight
            {
                minFontSize = currentFontSize
            }
            
            currentFontSize = (minFontSize + maxFontSize ) / 2
        }
        
        if(name == "System")
        {
            return UIFont.systemFont(ofSize: currentFontSize - 0.1)
        }
        return UIFont(name: name, size: currentFontSize - 0.1)!
    }
    
    @IBAction func HelpPressed(_ sender: Any) {
        segueToHelp()
    }
    
    func segueToHelp()
    {
       let obj = (self.storyboard?.instantiateViewController(withIdentifier: "HelpWalkthroughViewController"))!

       let transition:CATransition = CATransition()
       transition.duration = 0.3
       transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
       transition.type = .push
       transition.subtype = .fromRight
   
   
       self.navigationController!.view.layer.add(transition, forKey: kCATransition)
       self.navigationController?.pushViewController(obj, animated: true)
    }
    
    @IBAction func TargetPressed(_ sender: Any) {
     
        let alertService = InputAlertService()
        let alert = alertService.alert(placeholder: NSLocalizedString("Time", comment: ""), keyboardType: 0, myTitle: NSLocalizedString("Target Time", comment: ""),
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if HomeViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
               let str = temp.myString
               let intTime = temp.intTime
               
                let targetText = "  " + str
                self.TargetLabel.setTitle(targetText, for: .normal) // set title to string version
                self.TargetLabel.titleLabel?.font = HomeViewController.fontToFitWidth(text: targetText, view: self.TargetLabel, multiplier: 0.6, name: "Lato-Black")
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
    
    
    @IBAction func SessionButtonClicked(_ sender: Any) {
        if SessionCollection.count > 0
        {
            if SessionCollection[0].isHidden
            {
                SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
                if #available(iOS 13.0, *) {
                    //SessionButton.imageView?.rotate(duration: 0.25, radians: 0.5*Float.pi)
                    UIView.setAnimationsEnabled(false)
                    SessionButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
                    self.view.layoutIfNeeded()
                    UIView.setAnimationsEnabled(true)
                }
            }
            else
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
                {
                    self.SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                }
                if #available(iOS 13.0, *) {
                    UIView.setAnimationsEnabled(false)
                    SessionButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
                    self.view.layoutIfNeeded()
                    UIView.setAnimationsEnabled(true)
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
    
    // chose a session
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
            button.setTitleColor(.white, for: .normal)
        }
        
        if #available(iOS 13.0, *) {
            UIView.setAnimationsEnabled(false)
            SessionButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            self.view.layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        SessionButton.setTitle(title, for: .normal)
        sender.setTitleColor(HomeViewController.orangeColor(), for: .normal)
        
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
        retButton.backgroundColor = HomeViewController.darkMode ? HomeViewController.darkPurpleColor() : HomeViewController.darkBlueColor()
        retButton.isUserInteractionEnabled = true
        retButton.addTarget(self, action: #selector(SessionSelected(_:)), for: UIControl.Event.touchUpInside)
        retButton.layer.cornerRadius = 6.0
        retButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        return retButton
    }
    
    // called whenever something changed with sessions
    func setUpStackView()
    {
        SessionButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        SessionButton.setTitle(HomeViewController.mySession.name, for: .normal)
        SessionCollection = []
        for session in HomeViewController.allSessions
        {
            let newButton = createButton(name: session.name)
            if session.name == HomeViewController.mySession.name
            {
                newButton.setTitleColor(HomeViewController.orangeColor(), for: .normal)
            }
            SessionCollection.append(newButton)
            SessionStackView.addArrangedSubview(newButton)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        
        if NSLocale.preferredLanguages[0].contains("es-")
        {
            ResetButton.titleLabel?.font = UIFont(name: "Lato-Black", size: 13.0)
        }
        let stringSize = ResetButton.titleLabel?.intrinsicContentSize.width
        ResetButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
        
        setUpStackView()
        
        if #available(iOS 13.0, *) {
            UIView.setAnimationsEnabled(false)
            SessionButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
            self.view.layoutIfNeeded()
            UIView.setAnimationsEnabled(true)
        } 
        
        let targetText = "  \(SolveTime.makeMyString(num: HomeViewController.mySession.singleTime))"
        TargetLabel.setTitle(targetText, for: .normal)
        TargetLabel.titleLabel?.font = HomeViewController.fontToFitWidth(text: targetText, view: TargetLabel, multiplier: 0.6, name: "Lato-Black")
        
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
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        updateDrawScramble()
        
        
        HomeViewController.timerPhase = self.IDLE
        
        if(usingLongPress())
        {
            GestureArea.removeGestureRecognizer(HomeViewController.longPress) // not sure if necessary
            HomeViewController.longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
            HomeViewController.longPress.allowableMovement = 50
            HomeViewController.longPress.minimumPressDuration = TimeInterval(HomeViewController.holdingTime)
            HomeViewController.longPress.cancelsTouchesInView = false
            GestureArea.addGestureRecognizer(HomeViewController.longPress)
            
            webView.removeGestureRecognizer(HomeViewController.webLongPress)
            HomeViewController.webLongPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
            HomeViewController.webLongPress.allowableMovement = 50
            HomeViewController.webLongPress.minimumPressDuration = TimeInterval(HomeViewController.holdingTime)
            HomeViewController.webLongPress.cancelsTouchesInView = false
            HomeViewController.webLongPress.delegate = self
            webView.addGestureRecognizer(HomeViewController.webLongPress)
        }
        else // inspection or 0.0+noinspection
        {
            GestureArea.removeGestureRecognizer(HomeViewController.longPress)
            webView.removeGestureRecognizer(HomeViewController.webLongPress)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        
        
        closeStack()
            
        super.viewWillDisappear(animated)
            
            
    }
        
    func closeStack()
    {
        for button in SessionStackView.subviews
        {
            if button != SessionButton
            {
                button.isHidden = true
            }
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
      return true
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
        
        let webTap = UITapGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:)))
        webTap.delegate = self
        webView.addGestureRecognizer(webTap)
        
        let tapScramble = UITapGestureRecognizer(target: self, action: #selector(scrambleTapped(gesture:)))
        ScrambleContentView.addGestureRecognizer(tapScramble)
 
    }
    
    @objc func scrambleTapped(gesture: UIGestureRecognizer)
    {
        HomeViewController.mySession.scrambler.genScramble()
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        refreshImage.rotate(duration: 0.75, radians: 2*Float.pi)
        updateDrawScramble()
    }
    
    @objc func handleLongPress(sender: UIGestureRecognizer)
    {
        //print("handling long press")
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
        //print("touches canceled")
        if(usingLongPress())
        {
            cancelTimer()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //print("touches began")
        var inGestureArea = false
        for touch in touches
        {
            if(touch.location(in: GestureArea).y > 0 || touch.location(in: webView).y > 0)
            {
                inGestureArea = true
            }
        }
        
        //print("in gesture area \(inGestureArea)")
        
        if inGestureArea && usingLongPress() && HomeViewController.timerPhase == self.IDLE
        {
            TimerLabel.isHidden = false
            HomeViewController.timerPhase = self.FROZEN
            hideAll()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) // released before minimum hold time
    {
        //print("touches ended")
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
        webView.isHidden = true
        TargetLabel.isHidden = true
        ResetButton.isHidden = true
        HelpButton.isHidden = true
        SessionStackView.isHidden = true
    }
    
    func showAll()
    {
        //print("showing all")
        updateLabels()
        ScrambleContentView.isHidden = false
        webView.isHidden = false
        TargetLabel.isHidden = false
        ResetButton.isHidden = false
        HelpButton.isHidden = false
        SessionStackView.isHidden = false
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
        let alert = alertService.alert(myTitle: NSLocalizedString("Reset Average?", comment: ""), yesText: NSLocalizedString("Reset", comment: ""), completion: {
            self.reset()
        })
        self.present(alert, animated: true)
    }

    func usingLongPress() -> Bool
    {
        return !HomeViewController.inspection && HomeViewController.holdingTime > 0.01 && HomeViewController.timing == 0
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
        else if HomeViewController.timing == 0 && (HomeViewController.inspection || HomeViewController.holdingTime < 0.01) // tap gesture, timing
        {
            //print("tapped")
            self.performSegue(withIdentifier: "timerSegue", sender: self)
        }
        else if HomeViewController.timing == 1 // not timing... addsolve
        {
            addSolve()
        }
    }
    
    func deleteSolve()
    {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Delete Last Solve?", comment: ""), yesText: NSLocalizedString("Delete", comment: ""),
                                       completion: {
            
            try! self.realm.write
            {
                HomeViewController.mySession.deleteSolve()
            }
            self.ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
            self.updateDrawScramble()
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
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        updateDrawScramble()
        
        updateLabels()
    }
    
    func updateTimes(enteredTime: String)
    {
        try! realm.write
        {
            HomeViewController.mySession.addSolve(time: enteredTime)
        }
        
        
        ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
        updateDrawScramble()
        
        updateLabels()
        
    }
  
    func updateLabels()
    {
        let targetText = "  \(SolveTime.makeMyString(num: HomeViewController.mySession.singleTime))"
        TargetLabel.setTitle(targetText, for: .normal)
        TargetLabel.titleLabel?.font = HomeViewController.fontToFitWidth(text: targetText, view: TargetLabel, multiplier: 0.6, name: "Lato-Black")
        
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
            ScrambleLabel.text = HomeViewController.mySession.getCurrentScramble()
            updateDrawScramble()
            Logo.isHidden = true
        }
        
    }
    
    func updateDrawScramble()
    {
        let HTMLString = """
<!DOCTYPE html>
<html lang="en">
<head>
    <script src="scramble-display.browser.js"></script>
    <style type="text/css">
    <!--
    scramble-display
    {
        display: block;
        margin-left: 0px;
        margin-bottom: 0px;
    }
    -->
    </style>
</head>
<body>
    <scramble-display
        event="\(draw_events[HomeViewController.mySession.scrambler.myEvent])"
    scramble="\(HomeViewController.mySession.getCurrentScramble())"
    ></scramble-display>
</body>
</html>
"""
        webView!.loadHTMLString(HTMLString, baseURL: jsURL?.deletingLastPathComponent())
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
        
        tabBarController?.tabBar.barTintColor = HomeViewController.darkPurpleColor()
        
        HelpButton.tintColor = .white
        
        for button in [HelpButton, ResetButton, SessionButton]
        {
            button?.backgroundColor = HomeViewController.darkPurpleColor()
        }
        
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 13.0, *) {
            updateStatusBarBackground()
        } else {
            // Fallback on earlier versions
        }
        
        ScrambleContentView.backgroundColor = HomeViewController.darkModeColor()
        ScrambleContentView.layer.borderColor = UIColor.white.cgColor
        ScrambleLabel.textColor = .white
        refreshImage.image = UIImage(named: "refresh_white")
        RefreshButton.textColor = .white
        
    }
    
    @available(iOS 13.0, *)
    func updateStatusBarBackground()
    {
        let statusBar = UIView(frame: view.window?.windowScene?.statusBarManager?.statusBarFrame ?? CGRect.zero)
        statusBar.backgroundColor = HomeViewController.darkMode ?  HomeViewController.darkModeColor() : .white
        statusBar.overrideUserInterfaceStyle = HomeViewController.darkMode ? .light : .dark
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
        
        ScrambleContentView.layer.borderColor = HomeViewController.darkModeColor().cgColor
        
        for button in [HelpButton, ResetButton, SessionButton]
        {
            button?.backgroundColor = HomeViewController.darkBlueColor()
        }
        HelpButton.tintColor = .white

        
        setNeedsStatusBarAppearanceUpdate()
        if #available(iOS 13.0, *) {
            updateStatusBarBackground()
        } else {
            // Fallback on earlier versions
        }
        
        ScrambleContentView.layer.borderColor = HomeViewController.darkModeColor().cgColor
        ScrambleContentView.backgroundColor = .white
        ScrambleLabel.textColor = .black
        refreshImage.image = UIImage(named: "refresh")
        RefreshButton.textColor = HomeViewController.darkBlueColor()
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
        return UIColor.init(displayP3Red: 0/255, green: 51/255, blue: 89/255, alpha: 1.0)
    }
    
    static func greenColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 50/255, green: 142/255, blue: 84/255, alpha: 1.0)
    }
    
    static func grayColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 196/255, green: 196/255, blue: 196/255, alpha: 1.0)
    }
    
    static func redColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 164/255, green: 3/255, blue: 31/255, alpha: 1.0)
    }
    
    static func darkModeColor() -> UIColor
    {
        return UIColor.init(red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
    }
    
    static func darkPurpleColor() -> UIColor
    {
        return UIColor.init(red: 52/255, green: 55/255, blue: 75/255, alpha: 1.0)
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
