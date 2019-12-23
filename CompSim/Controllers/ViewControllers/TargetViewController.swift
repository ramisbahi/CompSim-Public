//
//  TargetViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/19/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

class TargetViewController: UIViewController {
    
    @IBOutlet weak var MinTimeLabel: UIButton!
    @IBOutlet weak var MaxTimeLabel: UIButton!
    
    @IBOutlet weak var Dist1: UILabel!
    @IBOutlet weak var Dist2: UILabel!
    @IBOutlet weak var Dist3: UILabel!
    @IBOutlet weak var Dist4: UILabel!
    @IBOutlet weak var Dist5: UILabel!
    @IBOutlet weak var Dist6: UILabel!
    @IBOutlet weak var Dist7: UILabel!
    
    @IBOutlet weak var WinningTimeSetting: UISegmentedControl!
    @IBOutlet weak var DistributionImage: UIImageView!
    @IBOutlet weak var SetRangeLabel: UILabel!
    @IBOutlet weak var DistributionLabel: UILabel!
    @IBOutlet weak var ToLabel: UILabel!
    
    @IBOutlet weak var StackView: UIStackView!
    
    
    static var noWinning = false // no win
    static var singleWinning = false
    static var rangeWinning = true
    
    @IBOutlet weak var DarkBackground: UIImageView!
    @IBOutlet var BlackWhiteLabels: [UILabel]!
    
    @IBOutlet weak var Segment: UISegmentedControl!
    
    let realm = try! Realm()
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
       
        MinTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.minTime), for: .normal) // set label to min
        MaxTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.maxTime), for: .normal) // set label to max
        self.updateDistributionLabels()
        
        // set the selected segment correctly
        if(TargetViewController.noWinning)
        {
            WinningTimeSetting.selectedSegmentIndex = 0
            noWinningSetup()
        }
        else if(TargetViewController.singleWinning)
        {
            WinningTimeSetting.selectedSegmentIndex = 1
            singleWinningSetup()
        }
        else
        {
            WinningTimeSetting.selectedSegmentIndex = 2
            rangeWinningSetup()
        }
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
    }
    
    @IBAction func ValueChanged(_ sender: Any) // value changed on winning time setting
    {
        print("called")
        if WinningTimeSetting.selectedSegmentIndex == 0 // none
        {
            noWinningSetup()
            TargetViewController.noWinning = true
            TargetViewController.singleWinning = false
            TargetViewController.rangeWinning = false
        }
        else if WinningTimeSetting.selectedSegmentIndex == 1 // single
        {
            singleWinningSetup()
            TargetViewController.noWinning = false
            TargetViewController.singleWinning = true
            TargetViewController.rangeWinning = false
        }
        else // range
        {
            rangeWinningSetup()
            
            TargetViewController.noWinning = false
            TargetViewController.singleWinning = false
            TargetViewController.rangeWinning = true
        }
    }
    
    func noWinningSetup()
    {
        StackView.isHidden = true
        SetRangeLabel.isHidden = true
        DistributionLabel.isHidden = true
        DistributionImage.isHidden = true
        self.changeDistLabels(hide: true)
    }
    
    func singleWinningSetup()
    {
        SetRangeLabel.text = "  Set Time:"
        SetRangeLabel.font = UIFont.systemFont(ofSize: 40.0)
        StackView.isHidden = false
        SetRangeLabel.isHidden = false
        MinTimeLabel.isHidden = true
        DistributionLabel.isHidden = true
        DistributionImage.isHidden = true
        if(!ViewController.darkMode)
        {
            MinTimeLabel.setTitleColor(UIColor.white, for: .normal)
        }
        else
        {
            MinTimeLabel.setTitleColor(UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0), for: .normal)
        }
        MaxTimeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 30.0)
        ToLabel.isHidden = true
        self.changeDistLabels(hide: true)
    }
    
    func rangeWinningSetup()
    {
        SetRangeLabel.text = "Set Range:"
        SetRangeLabel.font = UIFont.systemFont(ofSize: 24.0)
        SetRangeLabel.isHidden = false
        StackView.isHidden = false
        MinTimeLabel.isHidden = false
        DistributionLabel.isHidden = false
        DistributionImage.isHidden = false
        MaxTimeLabel.titleLabel?.font = UIFont.systemFont(ofSize: 30.0)
        if(ViewController.darkMode) // if dark, set orange
        {
            MinTimeLabel.setTitleColor(ViewController.orangeColor(), for: .normal)
        }
        else
        {
            MinTimeLabel.setTitleColor(ViewController.blueColor(), for: .normal)
        }
        ToLabel.isHidden = false
        self.changeDistLabels(hide: false)
    }
    
    func changeDistLabels(hide: Bool)
    {
        Dist1.isHidden = hide
        Dist2.isHidden = hide
        Dist3.isHidden = hide
        Dist4.isHidden = hide
        Dist5.isHidden = hide
        Dist6.isHidden = hide
        Dist7.isHidden = hide
    }
    
    @IBAction func MinTimeTouched(_ sender: Any) {
        print("running")
        let alert = UIAlertController(title: "Enter Minimum Time", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            // Confirming deleted solve
            
            let textField = alert.textFields![0] // Force unwrapping because we know it exists. Let that textfield string storing your time
            let enteredTime = textField.text!
            
            if let floatTime = Float(enteredTime)
            {
                let temp = SolveTime(enteredTime: enteredTime, scramble: "")
                let str = temp.myString
                let intTime = temp.intTime
                
                if(intTime > ViewController.mySession.maxTime)
                {
                    self.MaxTimeLabel.setTitle(str, for: .normal) // set title to string version
                    try! self.realm.write
                    {
                        ViewController.mySession.maxTime = intTime
                    }
                }
                self.MinTimeLabel.setTitle(str, for: .normal) // set title to string version
                try! self.realm.write
                {
                    ViewController.mySession.minTime = intTime
                }
                self.updateDistributionLabels()
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        alert.preferredAction = confirmAction
        
        self.present(alert, animated: true)
        
    }
    @IBAction func MaxTimeTouched(_ sender: Any) {
        if(TargetViewController.singleWinning)
        {
            if(!ViewController.darkMode)
            {
                MinTimeLabel.setTitleColor(UIColor.white, for: .normal)
            }
            else
            {
                MinTimeLabel.setTitleColor(UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0), for: .normal)
            }
        }
        let alert = UIAlertController(title: "Enter Maximum Time", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        let confirmAction = UIAlertAction(title: "Enter", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            // Confirming deleted solve
            
            let textField = alert.textFields![0] // Force unwrapping because we know it exists. Let that textfield string storing your time
            let enteredTime = textField.text!
            
            let temp = SolveTime(enteredTime: enteredTime, scramble: "")
            let str = temp.myString
            let intTime = temp.intTime
            
            if let floatTime = Float(enteredTime)
            {
                
                if(TargetViewController.rangeWinning) // range winning
                {
                    
                    if(intTime < ViewController.mySession.minTime)
                    {
                        self.MinTimeLabel.setTitle(str, for: .normal) // set title to string version
                        try! self.realm.write
                        {
                            ViewController.mySession.minTime = intTime
                        }
                    }
                    self.MaxTimeLabel.setTitle(str, for: .normal) // set title to string version
                    try! self.realm.write
                    {
                        ViewController.mySession.maxTime = intTime
                    }
                    self.updateDistributionLabels()
                }
                else // single winning time - don't need to check
                {
                    self.MaxTimeLabel.setTitle(str, for: .normal) // set title to string version
                    try! self.realm.write
                    {
                        ViewController.mySession.maxTime = intTime
                    }
                }
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        alert.preferredAction = confirmAction
        
        self.present(alert, animated: true)
    }
    
    
    
    func alertValidTime(alertMessage: String)
    {
        let alert = UIAlertController(title: alertMessage, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    func updateDistributionLabels()
    {
        let min: Double = Double(ViewController.mySession.minTime) / 100.0
        let max: Double = Double(ViewController.mySession.maxTime) / 100.0
        Dist1.text = timeToThous(time: min)
        Dist7.text = timeToThous(time: max)
        let std: Double = (max - min) / 6.0
        Dist2.text = timeToThous(time: min + std)
        Dist3.text = timeToThous(time: min + 2*std)
        Dist4.text = timeToThous(time: min + 3*std)
        Dist5.text = timeToThous(time: min + 4*std)
        Dist6.text = timeToThous(time: min + 5*std) 
    }
    
    // time is hundredths (i.e. 249 for 2.49)
    // returns string for thousdandth (2.490)
    func timeToThous(time: Double) -> String
    {
        let num = Int(time * 1000 + 0.5)
        let stringNum: String = String(num)
        let beforeDecimal = String(stringNum.prefix(stringNum.count - 3))
        let afterDecimal = String(stringNum.suffix(3))
        return beforeDecimal + "." + afterDecimal
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.white
        }
        if(TargetViewController.singleWinning)
        {
            MinTimeLabel.setTitleColor(UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0), for: .normal)
        }
        Segment.tintColor = ViewController.orangeColor()
        MinTimeLabel.setTitleColor(ViewController.orangeColor(), for: .normal)
        MaxTimeLabel.setTitleColor(ViewController.orangeColor(), for: .normal)
    }
    
    func turnOffDarkMode()
    {
        DarkBackground.isHidden = true
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.black
        }
        if(TargetViewController.singleWinning)
        {
            MinTimeLabel.setTitleColor(UIColor.white, for: .normal)
        }
        Segment.tintColor = ViewController.blueColor()
        MinTimeLabel.setTitleColor(ViewController.blueColor(), for: .normal)
        MaxTimeLabel.setTitleColor(ViewController.blueColor(), for: .normal)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if ViewController.darkMode
        {
            return .lightContent
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
