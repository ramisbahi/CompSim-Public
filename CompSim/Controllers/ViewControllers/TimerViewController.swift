//
//  TimerViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/8/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class TimerViewController: UIViewController {
    
    let IDLE = 0
    let INSPECTION = 1
    let TIMING = 2
    var timerPhase = 0 // 0 = idle, 1 = inspection, 2 = solving
    var timerTime: Double = 0.00
    var inspectionTimer = Timer()
    var timer = Timer()
    
    static var resultTime: Double = 0.00
    
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var SubmitButton: UIButton!
    
    @IBOutlet weak var TimerLabel: UILabel!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        startInspection()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.gestureSetup()
        
        
    }
    
    func gestureSetup()
    {
        let tap = UITapGestureRecognizer(target: self, action: #selector(respondToGesture(gesture:)))
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func respondToGesture(gesture: UIGestureRecognizer)
    {
        
        if(timerPhase == INSPECTION)
        {
            startTimer()
        }
        else if(timerPhase == TIMING)// TIMING
        {
            stopTimer()
        }
    }
    
    func startInspection()
    {
        timerPhase = INSPECTION
        var inspectionTime = 15
        TimerLabel.text = String(inspectionTime)
        inspectionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (time) in
            if(self.timerPhase == self.INSPECTION)
            {
                inspectionTime -= 1
                if(inspectionTime >= 0) // stops at 0
                {
                    self.TimerLabel.text = String(inspectionTime)
                }
            }
            else
            {
                return
            }
        })
    }
    
    func startTimer()
    {
        inspectionTimer.invalidate()
        timerTime = 0
        timerPhase = TIMING
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (blah) in
            if(self.timerPhase == self.TIMING)
            {
                self.timerTime += 0.01
                self.TimerLabel.text = String(format: "%.2f", self.timerTime)
            }
            else
            {
                return
            }
        })
        
    }
    
    func stopTimer()
    {
        TimerViewController.resultTime = self.timerTime
        timer.invalidate()
        timerPhase = IDLE
        PenaltySelector.isHidden = false
        SubmitButton.isHidden = false
    }
    
    @IBAction func SubmitButton(_ sender: Any) {
        
        if(ViewController.currentIndex < 4)
        {
            self.performSegue(withIdentifier: "goToViewController", sender: self)
        }
        else // (ViewController.currentIndex == 4)
        {
            print("result time = \(TimerViewController.resultTime)")
            let intTime = ViewController.hundredthRound(num: TimerViewController.resultTime)
            print("int time = \(intTime)")
            ViewController.times.append(intTime)
            ViewController.currentIndex += 1
            self.performSegue(withIdentifier: "goToResultViewController", sender: self)
        }
        
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
