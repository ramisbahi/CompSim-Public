//
//  EventViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/4/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

class SettingsViewController: UIViewController {
    
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
    
    let cuberDictionary = ["Bill" : "Bill Wang", "Lucas" : "Lucas Etter", "Feliks" : "Feliks Zemdegs", "Kian" : "Kian Mansour", "Random" : "Random", "Rami" : "Rami Sbahi", "Patrick" : "Patrick Ponce", "Max" : "Max Park", "Kevin" : "Kevin Hays"]
    
    let realm = try! Realm()
    
    @IBAction func DarkModeChanged(_ sender: Any) {
        ViewController.changedDarkMode = true
        if(!ViewController.darkMode) // not dark, set to dark
        {
            ViewController.darkMode = true
            makeDarkMode()
        }
        else // dark, turn off
        {
            ViewController.darkMode = false
            turnOffDarkMode()
        }
    }
    
    @IBAction func TimingChanged(_ sender: Any) {
        if(ViewController.timing)
        {
            ViewController.timing = false
            InspectionControl.isEnabled = false
            InspectionVoiceAlertsControl.isEnabled = false
        }
        else
        {
            ViewController.timing = true
            InspectionControl.isEnabled = true
            if(ViewController.inspection)
            {
                InspectionVoiceAlertsControl.isEnabled = true
            }
        }
    }
    
    @IBAction func InspectionChanged(_ sender: Any) {
        if(ViewController.inspection)
        {
            ViewController.inspection = false
            InspectionVoiceAlertsControl.isEnabled = false
        }
        else
        {
            ViewController.inspection = true
            InspectionVoiceAlertsControl.isEnabled = true
        }
    }
    
    @IBAction func InspectionVoiceAlertsChanged(_ sender: Any) {
        ViewController.inspectionSound = !ViewController.inspectionSound
    }
    
    func makeDarkMode()
    {
        BigView.backgroundColor = ViewController.darkModeColor()
        LittleView.backgroundColor = ViewController.darkModeColor()
        ScrollView.backgroundColor = ViewController.darkModeColor()
        TopButtons.forEach{ (button) in
        
            button.backgroundColor = UIColor.darkGray
        }
        TopLabels.forEach{ (label) in
        
            label.backgroundColor = UIColor.darkGray
        }
        
        
        for control in [DarkModeControl, TimingControl, InspectionControl, TimerUpdateControl, solveTypeControl, InspectionVoiceAlertsControl]
        {
            //control!.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "Futura", size: 13.0)!], for: .normal) - later - make futura
            control!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        }
        
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
            statusBar.backgroundColor = ViewController.darkMode ?  ViewController.darkModeColor() : .white
             view.addSubview(statusBar)
        }
    }
    
    func turnOffDarkMode()
    {
        BigView.backgroundColor = .white
        LittleView.backgroundColor = .white
        ScrollView.backgroundColor = .white
        TopButtons.forEach{ (button) in
        
            button.backgroundColor = ViewController.darkBlueColor()
        }
        TopLabels.forEach{ (label) in
            label.backgroundColor = ViewController.darkBlueColor()
        }
        
        for control in [DarkModeControl, TimingControl, InspectionControl, TimerUpdateControl, solveTypeControl, InspectionVoiceAlertsControl]
        {
            //control!.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "Futura", size: 14.0)!], for: .normal) - later - make futura
            control!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
        }
        
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
        print("view did load") 
        
        if(ViewController.darkMode)
        {
            DarkModeControl.selectedSegmentIndex = 0
            makeDarkMode()
            print("just made dark")
        }
        else
        {
            turnOffDarkMode()
        }
        
        
        if(ViewController.ao5)
        {
            solveTypeControl.selectedSegmentIndex = 0
        }
        else if(ViewController.mo3)
        {
            solveTypeControl.selectedSegmentIndex = 1
        }
        else
        {
            solveTypeControl.selectedSegmentIndex = 2
        }
        
        
        if(ViewController.timing)
        {
            TimingControl.selectedSegmentIndex = 0
        }
        else // not timing
        {
            TimingControl.selectedSegmentIndex = 1
            InspectionControl.isEnabled = false
        }
        
        if(!(ViewController.timing && ViewController.inspection))
        {
            InspectionVoiceAlertsControl.isEnabled = false
        }
        
        if(ViewController.inspection)
        {
            InspectionControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionControl.selectedSegmentIndex = 1
        }
        
        if(ViewController.inspectionSound)
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 0
        }
        else
        {
            InspectionVoiceAlertsControl.selectedSegmentIndex = 1
        }
        
        CuberButton.setTitle("Cuber: \(cuberDictionary[ViewController.cuber]!)", for: .normal)
        
        HoldingTimeSlider.value = ViewController.holdingTime
        HoldingTimeLabel.text = String(format: "Holding Time: %.2f", ViewController.holdingTime)
        
        TimerUpdateControl.selectedSegmentIndex = ViewController.timerUpdate
        
        super.viewDidLoad()
        
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let eventNames = ["2x2x2", "3x3x3", "4x4x4", "5x5x5", "6x6x6", "7x7x7", "Pyraminx", "Megaminx", "Square-1", "Skewb", "Clock", "3x3x3 BLD"]
        let title = eventNames[ViewController.mySession.scrambler.myEvent]
        ScrambleTypeButton.setTitle("Scramble Type: \(title)", for: .normal)
        
        super.viewWillAppear(false)
        eventCollection.forEach { (button) in
            button.isHidden = true
        }
        
        
        solveTypeControl.isEnabled = ViewController.mySession.currentIndex < 1
    }
    
    @IBAction func HoldingTimeChanged(_ sender: Any) {
        
        let roundedTime = round(HoldingTimeSlider.value * 20) / 20 // 0.29 --> 0.3, 0.27 --> 0.25
        HoldingTimeLabel.text = String(format: "Holding Time: %.2f", roundedTime)
        ViewController.holdingTime = roundedTime
        
        
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(false)
        
        switch(solveTypeControl.selectedSegmentIndex)
        {
        case 0:
            ViewController.ao5 = true
            ViewController.mo3 = false
            ViewController.bo3 = false
            break
        case 1:
            ViewController.mo3 = true
            ViewController.ao5 = false
            ViewController.bo3 = false
            break
        default:
            ViewController.bo3 = true
            ViewController.ao5 = false
            ViewController.mo3 = false
        }
        
        ViewController.timerUpdate = TimerUpdateControl.selectedSegmentIndex
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
        
        CuberButton.setTitle("Cuber: \(title)", for: .normal)
        
        let nameArr = title.components(separatedBy: " ")
        ViewController.cuber = nameArr[0]
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
        
        ScrambleTypeButton.setTitle("Scramble Type: \(title)", for: .normal)
        
        try! realm.write
        {
            switch event
            {
                case .twoCube:
                    ViewController.mySession.doEvent(enteredEvent: 0)
                case .threeCube:
                    ViewController.mySession.doEvent(enteredEvent: 1)
                case .fourCube:
                    ViewController.mySession.doEvent(enteredEvent: 2)
                case .fiveCube:
                    ViewController.mySession.doEvent(enteredEvent: 3)
                case .sixCube:
                    ViewController.mySession.doEvent(enteredEvent: 4)
                case .sevenCube:
                    ViewController.mySession.doEvent(enteredEvent: 5)
                case .pyra:
                    ViewController.mySession.doEvent(enteredEvent: 6)
                case .mega:
                    ViewController.mySession.doEvent(enteredEvent: 7)
                case .sq1:
                    ViewController.mySession.doEvent(enteredEvent: 8)
                case .skewb:
                    ViewController.mySession.doEvent(enteredEvent: 9)
                case .clock:
                    ViewController.mySession.doEvent(enteredEvent: 10)
                case .BLD:
                    ViewController.mySession.doEvent(enteredEvent: 11)
            }
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if #available(iOS 13.0, *)
        {
            if ViewController.darkMode
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
