//
//  ViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

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

class ViewController: UIViewController {
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
    @IBOutlet weak var SwipeUpLabel: UILabel!
    @IBOutlet weak var SwipeDownLabel: UILabel!
    
    @IBOutlet weak var SubmitButton: UIButton!
    
    @IBOutlet weak var TimerLabel: UILabel!
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    
    @IBOutlet weak var Logo: UIImageView!
    
    var labels = [UIButton]()
    
    // settings stuff
    
    static var darkMode = false
    static var changedDarkMode = false
    
    static var timing = true
    static var inspection = true
    
    static var cuber = "Random"
    
    static var holdingTime: Float = 0.55 
    
    static var mySession = Session(name: "3x3", enteredEvent: 1)
    static var allSessions: [Session] = [ViewController.mySession]
    
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
    
    let realm = try! Realm()
    
    struct Keys
    {
        static let darkMode = "darkMode"
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /*func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print("called")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "sticker", for: indexPath)
        
        cell.backgroundColor = .blue
        
        
        return cell
    }*/
    
    func hasSetSettings() -> Bool // one must be true
    {
        return UserDefaults.standard.bool(forKey: AppDelegate.ao5)
        || UserDefaults.standard.bool(forKey: AppDelegate.bo3)
        || UserDefaults.standard.bool(forKey: AppDelegate.mo3)
    }
    
    override func viewDidLayoutSubviews() {
        HelpButton.layer.cornerRadius = HelpButton.frame.size.height / 2.0
        if(NewScrambleButton.frame.size.width < 120)
        {
            NewScrambleButton.setTitle("New Scr.", for: .normal)
        }
        print(NewScrambleButton.frame.size.width)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.\
        print("viewcontroller did load")
        
        tabBarController?.tabBar.isHidden = false
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        
        self.gestureSetup()
        self.labels = [Time1, Time2, Time3, Time4, Time5] // add labels to labels array - one time thing
        
        if(ViewController.justOpened)
        {
            if hasSetSettings()
            {
                doSettings()
                ViewController.justOpened = false
            }
        }
        
        /*if(!AverageDetailViewController.justReturned && TimerViewController.resultTime == 0)
        {
            self.reset() // only when actually starting new round, not when returning from avgdetail or timer
        }*/
        print("result time \(TimerViewController.resultTime)")
        if(TimerViewController.resultTime != 0) // returned from timer
        {
            self.updateTimes(enteredTime: String(TimerViewController.resultTime), penalty: TimerViewController.penalty)
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
        
        
        if(ViewController.darkMode) // dark
        {
            makeDarkMode()
        }
        else // light
        {
            turnOffDarkMode()
        }
        
        if(ViewController.font == nil) // not set yet
        {
            ViewController.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.09, name: "Futura")
        }
        
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = ViewController.font
        }
        ScrambleLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.05, name: "System")
        TimerLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Geeza Pro")
        
        SubmitButton.titleLabel?.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.045, name: "Futura")
        
        
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
        let obj = (self.storyboard?.instantiateViewController(identifier: "HelpViewController"))!

                   let transition:CATransition = CATransition()
                   transition.duration = 0.3
                   transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
                   transition.type = .push
                   transition.subtype = .fromRight
               
               
                self.navigationController!.view.layer.add(transition, forKey: kCATransition)
                   self.navigationController?.pushViewController(obj, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        if(ViewController.changedDarkMode) // changed it - only have to do this once when changed
        {
            ViewController.darkMode ? makeDarkMode() : turnOffDarkMode()
            ViewController.changedDarkMode = false
        }
        
        if(ViewController.sessionChanged)
        {
            updateLabels()
            ViewController.mySession.scrambler.genScramble()
            ScrambleLabel.text = ViewController.mySession.getCurrentScramble()
            ViewController.sessionChanged = false
        }
        else
        {
            ScrambleLabel.text = ViewController.mySession.getCurrentScramble()
        }
        ViewController.timerPhase = self.IDLE
        
        if(usingLongPress())
        {
            GestureArea.removeGestureRecognizer(ViewController.longPress) // not sure if necessary
            ViewController.longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
            ViewController.longPress.allowableMovement = 50
            ViewController.longPress.minimumPressDuration = TimeInterval(ViewController.holdingTime)
            ViewController.longPress.cancelsTouchesInView = false
            GestureArea.addGestureRecognizer(ViewController.longPress)
        }
        else // inspection or 0.0+noinspection
        {
            GestureArea.removeGestureRecognizer(ViewController.longPress)
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
        DrawScrambleView.isHidden = !DrawScrambleView.isHidden
    }
    
    @objc func handleLongPress(sender: UIGestureRecognizer)
    {
        if(sender.state == .began) // reached holding time
        {
            if ViewController.timerPhase == self.IDLE
            {
                TimerLabel.isHidden = false
                ViewController.timerPhase = self.FROZEN
            }
            else
            {
                TimerLabel.textColor = .green
                ViewController.timerPhase = self.READY
            }
        }
        else if(sender.state == .cancelled)
        {
            cancelTimer()
        }
        else if(sender.state == .ended && ViewController.timerPhase == self.READY) // did holding time, released
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
        print("touches began")
        
        var inGestureArea = false
        for touch in touches
        {
            if(touch.location(in: GestureArea).y > 0)
            {
                inGestureArea = true
            }
        }
        
        if inGestureArea && usingLongPress() && ViewController.timerPhase == self.IDLE
        {
            TimerLabel.isHidden = false
            ViewController.timerPhase = self.FROZEN
            hideAll()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) // released before minimum hold time
    {
        print("touches ended")
        if(usingLongPress() && ViewController.timerPhase == FROZEN)
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
        SwipeUpLabel.isHidden = true
        SwipeDownLabel.isHidden = true
        
    }
    
    func showAll()
    {
        //print("showing all")
        updateLabels()
        ScrambleLabel.isHidden = false
        SwipeUpLabel.isHidden = false
        SwipeDownLabel.isHidden = false
        //TODO: show everything that should show
    }
    
    func cancelTimer()
    {
        //print("cancelling")
        TimerLabel.isHidden = true
        ViewController.timerPhase = IDLE
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
        let alert = alertService.alert(myTitle: "Reset Average?", completion: {
            self.reset()
        })
        self.present(alert, animated: true)
    }
    
    @IBAction func newScramblePressed(_ sender: Any) {
        ViewController.mySession.scrambler.genScramble()
        ScrambleLabel.text = ViewController.mySession.scrambler.currentScramble
    }
    
    func usingLongPress() -> Bool
    {
        return !ViewController.inspection && ViewController.holdingTime > 0.01 && ViewController.timing
    }
    
    func reset()
    {
        try! realm.write
        {
            ViewController.mySession.reset()
        }
        ScrambleLabel.text = String(ViewController.mySession.getCurrentScramble()) // next scramble
        updateLabels()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        
    }
    
    func alertValidTime(alertMessage: String)
    {
        let alertService = NotificationAlertService()
        let alert = alertService.alert(myTitle: "Invalid Time")
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
                    if(ViewController.mySession.times.count > 0)
                    {
                        deleteSolve()
                    }
                default:
                    break
            }
        }
        else if ViewController.timing && (ViewController.inspection || ViewController.holdingTime < 0.01) // tap gesture, timing
        {
            //print("tapped")
            self.performSegue(withIdentifier: "timerSegue", sender: self)
        }
    }
    
    func deleteSolve()
    {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: "Delete Last Solve?",
                                       completion: {
            
            try! self.realm.write
            {
                ViewController.mySession.deleteSolve()
            }
            self.ScrambleLabel.text = ViewController.mySession.getCurrentScramble()
            self.updateLabels()
            print(ViewController.mySession.currentIndex)
        })
        
        self.present(alert, animated: true)
    }
    
    func addSolve()
    {
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Time", usingPenalty: true, keyboardType: 0, myTitle: "Add Solve",
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            let penalties = [2, 0, 1] // adjust for index
            let inputPenalty = penalties[alertService.myVC.PenaltySelector.selectedSegmentIndex]
            
            if ViewController.validEntryTime(time: inputTime)
            {
                self.updateTimes(enteredTime: inputTime, penalty: inputPenalty) // add time, show label, change parentheses
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
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
        print("updating times w/ penalty")
        try! realm.write
        {
            print("in the realm write adding")
            ViewController.mySession.addSolve(time: enteredTime, penalty: penalty)
        }
        ScrambleLabel.text = ViewController.mySession.getCurrentScramble() // change scramble
        
        updateLabels()
    }
    
    func updateTimes(enteredTime: String)
    {
        print("updating times")
        try! realm.write
        {
            ViewController.mySession.addSolve(time: enteredTime)
        }
        
        
        ScrambleLabel.text = ViewController.mySession.getCurrentScramble() // change scramble
        
        updateLabels()
        
    }
    
    @IBAction func SubmitButtonPressed(_ sender: Any) {
        self.performSegue(withIdentifier: "viewControllerToResult", sender: self)
    }
    func updateLabels()
    {
        print("updating time labels")
        for i in 0..<ViewController.mySession.currentIndex
        {
            self.labels[i].setTitle(ViewController.mySession.times[i].myString, for: .normal)
            self.labels[i].isHidden = false
            if i != ViewController.mySession.currentIndex-1
            {
                self.labels[i].isEnabled = false
                
            }
            else
            {
                self.labels[i].isEnabled = true
            }
        }
        for i in ViewController.mySession.currentIndex..<5
        {
            self.labels[i].isHidden = true
        }
        
        if(ViewController.mySession.currentIndex == 5) || ViewController.mySession.currentIndex == 3 && ViewController.mySession.solveType > 0
        {
            self.performSegue(withIdentifier: "viewControllerToResult", sender: self)
        }
        else
        {
            ScrambleLabel.text = ViewController.mySession.getCurrentScramble() // change scramble
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
        let myScramble = ViewController.mySession.times[num].myScramble
        let myPenalty = ViewController.mySession.times[num].penalty
        
        let alertService = ViewSolveAlertService()
        let alert = alertService.alert(usingPenalty: true, title: myTitle!, scramble: myScramble, penalty: myPenalty, completion:
        {
            
            let penalties = [2, 0, 1] // adjust for index
            let inputPenalty = penalties[alertService.myVC.PenaltySelector.selectedSegmentIndex]
            try! self.realm.write
            {
                ViewController.mySession.changePenaltyStatus(index: num, penalty: inputPenalty)
            }
            self.updateLabels()
        })
        
        self.present(alert, animated: true)
    }
    
    func makeDarkMode()
    {
        BigView.backgroundColor = ViewController.darkModeColor()
        ScrambleLabel.textColor? = UIColor.white
        SwipeUpLabel.textColor? = UIColor.white
        SwipeDownLabel.textColor? = UIColor.white
        TimesCollection.forEach { (button) in
            button.setTitleColor(.white, for: .disabled)
            button.setTitleColor(ViewController.orangeColor(), for: .normal) // orange
        }
        SubmitButton.backgroundColor = .darkGray
        HelpButton.backgroundColor = .darkGray
        HelpButton.tintColor = .white
        ResetButton.backgroundColor = .darkGray
        ResetButton.titleLabel?.textColor = .white
        NewScrambleButton.backgroundColor = .darkGray
        NewScrambleButton.titleLabel?.textColor = .white
    }
    
    func turnOffDarkMode()
    {
        BigView.backgroundColor = .white
        ScrambleLabel.textColor = UIColor.black
        SwipeUpLabel.textColor = UIColor.black
        SwipeDownLabel.textColor = UIColor.black
        TimesCollection.forEach { (button) in
            button.setTitleColor(.black, for: .disabled)
            button.setTitleColor(UIColor.link, for: .normal) // orange
        }
        SubmitButton.backgroundColor = ViewController.darkBlueColor()
        HelpButton.backgroundColor = ViewController.darkBlueColor()
        HelpButton.tintColor = .white //ViewController.darkBlueColor()
        ResetButton.backgroundColor = ViewController.darkBlueColor()
        ResetButton.titleLabel?.textColor = .white
        NewScrambleButton.backgroundColor = ViewController.darkBlueColor()
        NewScrambleButton.titleLabel?.textColor = .white
        
    }
    
    func doSettings()
    {
        ViewController.darkMode = UserDefaults.standard.bool(forKey: AppDelegate.darkMode)
        ViewController.cuber = UserDefaults.standard.string(forKey: AppDelegate.cuber) ?? "Lucas"
        ViewController.timing = UserDefaults.standard.bool(forKey: AppDelegate.timing)
        ViewController.inspection = UserDefaults.standard.bool(forKey: AppDelegate.inspection)
        ViewController.holdingTime = UserDefaults.standard.float(forKey: AppDelegate.holdingTime)
        ViewController.timerUpdate = UserDefaults.standard.integer(forKey: AppDelegate.timerUpdate)
        ViewController.mySession.scrambler.doEvent(event: UserDefaults.standard.integer(forKey: AppDelegate.event))
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if ViewController.darkMode
        {
            return .lightContent
        }
        return .default
    }
    
    static func orangeColor() -> UIColor
    {
        return UIColor.init(displayP3Red: 255/255, green: 165/255, blue: 61/255, alpha: 1.0)
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

