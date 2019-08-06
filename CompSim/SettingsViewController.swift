//
//  SettingsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/19/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    
    
    @IBOutlet weak var MinTimeLabel: UIButton!
    @IBOutlet weak var MaxTimeLabel: UIButton!
    
    @IBOutlet weak var Dist1: UILabel!
    @IBOutlet weak var Dist2: UILabel!
    @IBOutlet weak var Dist3: UILabel!
    @IBOutlet weak var Dist4: UILabel!
    @IBOutlet weak var Dist5: UILabel!
    @IBOutlet weak var Dist6: UILabel!
    @IBOutlet weak var Dist7: UILabel!
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated);
       
        MinTimeLabel.setTitle(ViewController.hundredthString(num: ViewController.minTime), for: .normal) // set label to min
        MaxTimeLabel.setTitle(ViewController.hundredthString(num: ViewController.maxTime), for: .normal) // set label to max
        self.updateDistributionLabels()
    }
    
    @IBAction func MinTimeTouched(_ sender: Any) {
        print("running")
        let alert = UIAlertController(title: "Enter Minimum Time", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        let confirmAction = UIAlertAction(title: "Enter", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            // Confirming deleted solve
            
            let textField = alert.textFields![0] // Force unwrapping because we know it exists. Let that textfield string storing your time
            let enteredTime = textField.text!
            
            if let doubleTime = Double(enteredTime)
            {
                let time = ViewController.hundredthRound(num: doubleTime) // convert to rounded int (i.e. 1.493 --> 149, 1.496 --> 150)
                if(time <= ViewController.maxTime)
                {
                    self.MinTimeLabel.setTitle(ViewController.hundredthString(num: time), for: .normal) //  set title to string version
                        ViewController.minTime = time
                        self.updateDistributionLabels()
                }
                else
                {
                    self.alertValidTime(alertMessage:"Please enter a time less than maximum")
                }
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
        
    }
    @IBAction func MaxTimeTouched(_ sender: Any) {
        
        let alert = UIAlertController(title: "Enter Maximum Time", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        let confirmAction = UIAlertAction(title: "Enter", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
            // Confirming deleted solve
            
            let textField = alert.textFields![0] // Force unwrapping because we know it exists. Let that textfield string storing your time
            let enteredTime = textField.text!
            
            if let doubleTime = Double(enteredTime)
            {
                let time = ViewController.hundredthRound(num: doubleTime) // // convert to rounded int (i.e. 1.493 --> 149, 1.496 --> 150)
                if(time >= ViewController.minTime)
                {
                    self.MaxTimeLabel.setTitle(ViewController.hundredthString(num: time), for: .normal) // set title to string version
                    ViewController.maxTime = time
                    self.updateDistributionLabels()
                }
                else
                {
                    self.alertValidTime(alertMessage:"Please enter a time greater than minimum")
                }
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
            
        })
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        
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
        let min: Double = Double(ViewController.minTime) / 100.0
        let max: Double = Double(ViewController.maxTime) / 100.0
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}