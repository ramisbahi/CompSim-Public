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
    @IBOutlet weak var SingleTimeLabel: UIButton!
    
    
    @IBOutlet weak var Dist1: UILabel!
    @IBOutlet weak var Dist2: UILabel!
    @IBOutlet weak var Dist3: UILabel!
    @IBOutlet weak var Dist4: UILabel!
    @IBOutlet weak var Dist5: UILabel!
    @IBOutlet weak var Dist6: UILabel!
    @IBOutlet weak var Dist7: UILabel!
    
    @IBOutlet weak var WinningTimeSetting: UISegmentedControl!
    @IBOutlet weak var DistributionImage: UIImageView!
    @IBOutlet weak var DistributionLabel: UILabel!
    @IBOutlet weak var ToLabel: UILabel!
    
    
    
    static var noWinning = false // no win
    static var singleWinning = false
    static var rangeWinning = true
    
    @IBOutlet weak var DarkBackground: UIImageView!
    @IBOutlet var BlackWhiteLabels: [UILabel]!
    
    let realm = try! Realm()
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
       
        MinTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.minTime), for: .normal) // set label to min
        MaxTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.maxTime), for: .normal) // set label to max
        SingleTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.singleTime), for: .normal)
        
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
        MaxTimeLabel.isHidden = true
        ToLabel.isHidden = true
        MinTimeLabel.isHidden = true
        SingleTimeLabel.isHidden = true
        DistributionLabel.isHidden = true
        DistributionImage.isHidden = true
        self.changeDistLabels(hide: true)
    }
    
    func singleWinningSetup()
    {
        SingleTimeLabel.isHidden = false
        MaxTimeLabel.isHidden = true
        ToLabel.isHidden = true
        MinTimeLabel.isHidden = true
        DistributionLabel.isHidden = true
        DistributionImage.isHidden = true
        ToLabel.isHidden = true
        self.changeDistLabels(hide: true)
    }
    
    func rangeWinningSetup()
    {
        SingleTimeLabel.isHidden = true
        MaxTimeLabel.isHidden = false
        ToLabel.isHidden = false
        MinTimeLabel.isHidden = false
        DistributionLabel.isHidden = false
        DistributionImage.isHidden = false
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
             
            if let _ = Float(enteredTime)
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
            
            if let _ = Float(enteredTime)
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
    
    @IBAction func SingleTimeTouched(_ sender: Any) {
        let alert = UIAlertController(title: "Enter Target Time", message: "", preferredStyle: .alert)
        
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
            
            if let _ = Float(enteredTime)
            {
                self.SingleTimeLabel.setTitle(str, for: .normal) // set title to string version
                try! self.realm.write
                {
                    ViewController.mySession.singleTime = intTime
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

        var beforeDecimal = ""
        var afterDecimal = ""
        
        if(num < 1000)
        {
            beforeDecimal = "0"
        }
        
        if(stringNum.count >= 3)
        {
            beforeDecimal = String(stringNum.prefix(max(stringNum.count - 3, 0)))
        }
        else
        {
            afterDecimal = "0"
        }
        afterDecimal += String(stringNum.suffix(3))
        return beforeDecimal + "." + afterDecimal
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        for button in [MinTimeLabel, MaxTimeLabel, SingleTimeLabel, DistributionLabel]
        {
            button?.backgroundColor = .darkGray
        }
        DistributionImage.image = UIImage(named: "DarkModeGaussianCurve")
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.white
        }
        WinningTimeSetting.tintColor = ViewController.orangeColor()
        WinningTimeSetting.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    }
    
    func turnOffDarkMode()
    {
        DarkBackground.isHidden = true
        for button in [MinTimeLabel, MaxTimeLabel, SingleTimeLabel, DistributionLabel]
        {
            button?.backgroundColor = ViewController.darkBlueColor()
        }
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.black
        }
        DistributionImage.image = UIImage(named: "GaussianCurve")
        WinningTimeSetting.tintColor = .white
        WinningTimeSetting.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .normal)
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
