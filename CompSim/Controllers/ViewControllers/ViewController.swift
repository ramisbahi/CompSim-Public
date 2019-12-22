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
    
    @IBOutlet weak var Time1: UIButton!
    @IBOutlet weak var Time2: UIButton!
    @IBOutlet weak var Time3: UIButton!
    @IBOutlet weak var Time4: UIButton!
    @IBOutlet weak var Time5: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    @IBOutlet weak var BackgroundImage: UIImageView!
    
    @IBOutlet weak var ScrambleLabel: UILabel!
    @IBOutlet weak var SwipeUpLabel: UILabel!
    @IBOutlet weak var SwipeDownLabel: UILabel!
    
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    var labels = [UIButton]()
    
    // settings stuff
    
    static var darkMode = false
    static var changedDarkMode = false
    
    static var timing = true
    static var inspection = true
    
    static var cuber = "Lucas"
    
    static var ao5 = true
    static var mo3 = false
    static var bo3 = false
    
    static var holdingTime: Float = 0.55 
    
    static var mySession = Session(name: "3x3x3")
    static var allSessions: [String : Session] = ["3x3x3" : ViewController.mySession]
    
    
    static var justOpened = true
    static var sessionChanged = false
    
    static var hasSaved = false
    
    let realm = try! Realm()
    
    struct Keys
    {
        static let darkMode = "darkMode"
    }
    
    func hasSetSettings() -> Bool // one must be true
    {
        return UserDefaults.standard.bool(forKey: AppDelegate.ao5)
        || UserDefaults.standard.bool(forKey: AppDelegate.bo3)
        || UserDefaults.standard.bool(forKey: AppDelegate.mo3)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.\
        print("viewcontroller did load")
        
        saveRealmStuff()
        
        if(ViewController.justOpened && hasSetSettings())
        {
            doSettings()
            ViewController.justOpened = false
        }
        
        self.gestureSetup()
        self.labels = [Time1, Time2, Time3, Time4, Time5] // add labels to labels array - one time thing
        
        if(!AverageDetailViewController.justReturned && TimerViewController.resultTime == 0)
        {
            self.reset() // only when actually starting new round, not when returning from avgdetail or timer
        }
        else if(TimerViewController.resultTime != 0) // returned from timer
        {
            self.updateTimes(enteredTime: String(TimerViewController.resultTime), penalty: TimerViewController.penalty)
            TimerViewController.penalty = 0
            TimerViewController.resultTime = 0
        }
        else // just returned from avgdetail
        {
            self.updateTimeLabels()
            AverageDetailViewController.justReturned = false
        }
        
        //aprint(ViewController.mySession.scrambler.scrambles)
        
        if(ViewController.darkMode) // dark
        {
            makeDarkMode()
        }
        else // light
        {
            turnOffDarkMode()
        }
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
            updateTimeLabels()
            try! realm.write
            {
                ScrambleLabel.text = ViewController.mySession.scrambler.getChangedSessionScramble()
            }
            ViewController.sessionChanged = false
        }
        else
        {
            try! realm.write
            {
                ScrambleLabel.text = ViewController.mySession.scrambler.getCurrentScramble()
            }
        }
    }
    
    
    func gestureSetup()
    {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToGesture(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeUp.direction = .up // ...when up swipe is done
        self.view.addGestureRecognizer(swipeUp) // allow view to recognize
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeDown.direction = .down // ...when down swipe is done
        self.view.addGestureRecognizer(swipeDown) // allow view to recognize
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:)))
        self.view.addGestureRecognizer(tap)
    }
    
    func reset()
    {
        try! realm.write
        {
            ViewController.mySession.reset()
            ScrambleLabel.text = String(ViewController.mySession.scrambler.nextScramble()) // next scramble
        }
    }
    
    func saveRealmStuff()
    {
        print("saving realm stuff")
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        
        let session = ViewController.mySession
        try! realm.write
        {
            realm.add(session)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        
        
    }
    
    
    
    
    
    
    func alertValidTime(alertMessage: String)
    {
        let alert = UIAlertController(title: alertMessage, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
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
        else if ViewController.timing // tap gesture, timing
        {
            print("tapped")
            self.performSegue(withIdentifier: "timerSegue", sender: self)
        }
    }
    
    func deleteSolve()
    {
        let alert = UIAlertController(title: "Delete last solve?", message: "", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .default, handler: {
            _ in
            // Confirming deleted solve
            try! self.realm.write
            {
                ViewController.mySession.deleteSolve()
                self.ScrambleLabel.text = ViewController.mySession.scrambler.previousScramble()
            }
            self.labels[ViewController.mySession.currentIndex].setTitle("", for: .normal)
            self.labels[ViewController.mySession.currentIndex].isHidden = true
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            _ in
            
        })
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        
        self.present(alert, animated: true)
    }
    
    
    
    func addSolve()
    {
        let alert = UIAlertController(title: "Add Solve", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        }
        )
        
        let enterAction = UIAlertAction(title: "Enter", style: .default, handler: {
            
            // Everything in here is executed when a time is entered
            
            [weak alert] (_) in
            
            let textField = alert!.textFields![0] // your time
            let inputTime = textField.text!
            
            if(inputTime.countInstances(of: ".") <= 1 && inputTime.last != "." && inputTime.count > 0)
            {
                self.updateTimes(enteredTime: inputTime) // add time, show label, change parentheses
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
        }
        )
        
        
        
        alert.addAction(cancelAction)
        alert.addAction(enterAction)
        alert.preferredAction = enterAction
        
        self.present(alert, animated: true)
    }
    
    // double is entered, converted to int for hundredth precision (i.e. 4.0 will become 400 now)
    // converted to string for proper representation (i.e. 4.0 will become 4.00 now)
    
    func updateTimes(enteredTime: String, penalty: Int)
    {
        print("updating times w/ penalty")
        try! realm.write
        {
            ViewController.mySession.addSolve(time: enteredTime, penalty: penalty)
        }
        if(ViewController.mySession.currentIndex >= 5 || ViewController.mySession.currentIndex >= 3 && (ViewController.mo3 || ViewController.bo3)) // change view when 5 solves done, or 3 for mo3/bo3
        {
            self.performSegue(withIdentifier: "viewControllerToResult", sender: self)
        }
        else // next scramble
        {
            print("in update times")
            try! realm.write
            {
                ScrambleLabel.text = ViewController.mySession.scrambler.nextScramble() // change scramble
            }
        }
        
        updateTimeLabels()
    }
    
    func updateTimes(enteredTime: String)
    {
        print("updating times")
        try! realm.write
        {
            ViewController.mySession.addSolve(time: enteredTime)
        }
        
        if(ViewController.mySession.currentIndex >= 5 || ViewController.mySession.currentIndex >= 3 && (ViewController.mo3 || ViewController.bo3)) // change view when 5 solves done, or 3 for mo3/bo3
        {
            self.performSegue(withIdentifier: "viewControllerToResult", sender: self)
        }
        else // next scramble
        {
            print("in update times")
            try! realm.write
            {
                ScrambleLabel.text = ViewController.mySession.scrambler.nextScramble() // change scramble
            }
        }
        
        updateTimeLabels()
    }
    
    func updateTimeLabels()
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
        let myText = self.labels[num].titleLabel!.text
        
        /*
        for scramble in ViewController.mySession.scrambler.scrambles
        {
            print(scramble)
        }*/
        let alert = UIAlertController(title: myText, message: ViewController.mySession.scrambler.getScramble(number: (ViewController.mySession.roundNumber - 1) * 5 + num), preferredStyle: .alert)
        
        let noPenaltyAction = UIAlertAction(title: "No Penalty", style: .default, handler: {
            _ in
            // Confirming deleted solve
            try! self.realm.write
            {
                ViewController.mySession.changePenaltyStatus(index: num, penalty: 0)
            }
            self.updateTimeLabels()
        })
        
        let plusTwoAction = UIAlertAction(title: "+2", style: .default, handler: {
            _ in
            // Confirming deleted solve
            try! self.realm.write
            {
                ViewController.mySession.changePenaltyStatus(index: num, penalty: 1)
            }
            self.updateTimeLabels()
        })
        
        let DNFAction = UIAlertAction(title: "DNF", style: .default, handler: {
            _ in
            // Confirming deleted solve
            try! self.realm.write
            {
                ViewController.mySession.changePenaltyStatus(index: num, penalty: 2)
            }
            self.updateTimeLabels()
        })

        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        alert.addAction(noPenaltyAction)
        alert.addAction(plusTwoAction)
        alert.addAction(DNFAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func makeDarkMode()
    {
        BackgroundImage.isHidden = false
        ScrambleLabel.textColor? = UIColor.white
        SwipeUpLabel.textColor? = UIColor.white
        SwipeDownLabel.textColor? = UIColor.white
        TimesCollection.forEach { (button) in
            button.setTitleColor(.white, for: .disabled)
            button.setTitleColor(ViewController.orangeColor(), for: .normal) // orange
        }
    }
    
    func turnOffDarkMode()
    {
        BackgroundImage.isHidden = true
        ScrambleLabel.textColor = UIColor.black
        SwipeUpLabel.textColor = UIColor.black
        SwipeDownLabel.textColor = UIColor.black
        TimesCollection.forEach { (button) in
            button.setTitleColor(.black, for: .disabled)
            button.setTitleColor(UIColor.link, for: .normal) // orange
        }
        
    }
    
    func doSettings()
    {
        ViewController.darkMode = UserDefaults.standard.bool(forKey: AppDelegate.darkMode)
        ViewController.cuber = UserDefaults.standard.string(forKey: AppDelegate.cuber) ?? "Lucas"
        ViewController.ao5 = UserDefaults.standard.bool(forKey: AppDelegate.ao5)
        ViewController.bo3 = UserDefaults.standard.bool(forKey: AppDelegate.bo3)
        ViewController.mo3 = UserDefaults.standard.bool(forKey: AppDelegate.mo3)
        ViewController.timing = UserDefaults.standard.bool(forKey: AppDelegate.timing)
        ViewController.inspection = UserDefaults.standard.bool(forKey: AppDelegate.inspection)
        ViewController.holdingTime = UserDefaults.standard.float(forKey: AppDelegate.holdingTime)
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
    
    
}

