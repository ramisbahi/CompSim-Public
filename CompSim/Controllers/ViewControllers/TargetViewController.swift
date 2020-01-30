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
    
    @IBOutlet var DistLabels: [UILabel]!
    
    
    @IBOutlet var BlackWhiteLabels: [UILabel]!
    
    @IBOutlet var BigView: UIView!
    
    let realm = try! Realm()
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
       
        MinTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.minTime), for: .normal) // set label to min
        MaxTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.maxTime), for: .normal) // set label to max
        SingleTimeLabel.setTitle(SolveTime.makeMyString(num: ViewController.mySession.singleTime), for: .normal)
        
        self.updateDistributionLabels()
        
        // set the selected segment correctly
        
        WinningTimeSetting.selectedSegmentIndex = ViewController.mySession.targetType
        setup(type: ViewController.mySession.targetType)
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
    }
    
    func setup(type: Int)
    {
        if(type == 0)
        {
            noWinningSetup()
        }
        else if(type == 1)
        {
            singleWinningSetup()
        }
        else
        {
            rangeWinningSetup()
        }
    }
    
    @IBAction func ValueChanged(_ sender: Any) // value changed on winning time setting
    {
        print("called")
        
        setup(type: WinningTimeSetting.selectedSegmentIndex)
        try! realm.write {
            ViewController.mySession.targetType = WinningTimeSetting.selectedSegmentIndex
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
        
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Time", usingPenalty: false, keyboardType: 0, myTitle: "Min Time",
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if ViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
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
                self.alertValidTime()
            }
        })
        
        self.present(alert, animated: true)
        
    }
    @IBAction func MaxTimeTouched(_ sender: Any) {
        
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Time", usingPenalty: false, keyboardType: 0, myTitle: "Max Time",
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if ViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
               let str = temp.myString
               let intTime = temp.intTime
               
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
                self.alertValidTime()
            }
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func SingleTimeTouched(_ sender: Any) {
        
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Time", usingPenalty: false, keyboardType: 0, myTitle: "Single Time",
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if ViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
               let str = temp.myString
               let intTime = temp.intTime
               
               self.SingleTimeLabel.setTitle(str, for: .normal) // set title to string version
               try! self.realm.write
               {
                   ViewController.mySession.singleTime = intTime
               }
               self.updateDistributionLabels()
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
        let alert = alertService.alert(myTitle: "Invalid Time")
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    override func viewDidLayoutSubviews() {
        let rangeFont = ViewController.fontToFitHeight(view: MinTimeLabel, multiplier: 0.9, name: "Futura")
        MinTimeLabel.titleLabel?.font = rangeFont
        MaxTimeLabel.titleLabel?.font = rangeFont
        
   
        WinningTimeSetting.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: ViewController.darkMode ? UIColor.white : UIColor.black, NSAttributedString.Key.font: ViewController.fontToFitHeight(view: WinningTimeSetting, multiplier: 0.6, name: "Futura")], for: .normal)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SingleTimeLabel.titleLabel?.adjustsFontSizeToFitWidth = true
        MinTimeLabel.titleLabel?.adjustsFontSizeToFitWidth = true
        MaxTimeLabel.titleLabel?.adjustsFontSizeToFitWidth = true
    
        
        
        updateHeights()
    }
    
    func updateHeights()
    {
        DistLabels.forEach{(label) in
            let textHeight = label.text?.size(withAttributes: [NSAttributedString.Key.font: UIFont(name: "Futura", size: label.font.pointSize)!]).height
            
            
            label.heightAnchor.constraint(equalToConstant: textHeight!).isActive = true
        }
    }
    
    
    func updateDistributionLabels()
    {
        let min = ViewController.mySession.minTime
        let max = ViewController.mySession.maxTime
        Dist1.text = SolveTime.makeMyString(num: min)
        Dist7.text = SolveTime.makeMyString(num: max)
        let std: Float = Float(max - min) / 6.0
        Dist2.text = SolveTime.makeMyString(num: Int(round(Float(min) + std)))
        Dist3.text = SolveTime.makeMyString(num: Int(round(Float(min) + 2*std)))
        Dist4.text = SolveTime.makeMyString(num: Int(round(Float(min) + 3*std)))
        Dist5.text = SolveTime.makeMyString(num: Int(round(Float(min) + 4*std)))
        Dist6.text = SolveTime.makeMyString(num: Int(round(Float(min) + 5*std)))
        updateHeights()
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

        BigView.backgroundColor = ViewController.darkModeColor()
        for button in [MinTimeLabel, MaxTimeLabel, SingleTimeLabel, DistributionLabel]
        {
            button?.backgroundColor = .darkGray
        }
        DistributionImage.image = UIImage(named: "DarkModeGaussianCurve")
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.white
        }
        WinningTimeSetting.tintColor = ViewController.orangeColor()
        WinningTimeSetting.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: ViewController.fontToFitHeight(view: WinningTimeSetting, multiplier: 0.6, name: "Futura")], for: .normal)
    }
    
    func turnOffDarkMode()
    {
        BigView.backgroundColor = .white
        for button in [MinTimeLabel, MaxTimeLabel, SingleTimeLabel, DistributionLabel]
        {
            button?.backgroundColor = ViewController.darkBlueColor()
        }
        BlackWhiteLabels.forEach { (label) in
            label.textColor? = UIColor.black
        }
        DistributionImage.image = UIImage(named: "GaussianCurve")
        WinningTimeSetting.tintColor = .white
        WinningTimeSetting.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: ViewController.fontToFitHeight(view: WinningTimeSetting, multiplier: 0.6, name: "Futura")], for: .normal)
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
