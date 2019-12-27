//
//  TimerViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/8/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

class TimerViewController: UIViewController {
    
    let IDLE = 0
    let INSPECTION = 1
    let FROZEN = 2
    let READY = 3
    let TIMING = 4
    var timerPhase = 0
    var timerTime: Float = 0.00
    var inspectionTimer = Timer()
    var timer = Timer()
    let penalties = [2, 0, 1] // index of selector --> penalty (DNF, none, +2)
    
    
    static var longPress = UILongPressGestureRecognizer()
    
    @IBOutlet weak var DarkBackground: UIImageView!
    
    static var resultTime: Float = 0.00
    static var penalty = 0
    
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var SubmitButton: UIButton!

    @IBOutlet weak var TimerLabel: UILabel!
    @IBOutlet weak var CancelButton: UIButton!
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        if(ViewController.inspection)
        {
            startInspection()
        }
        else
        {
            startTimer()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.gestureSetup()
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        TimerLabel.textColor = .white
        SubmitButton.backgroundColor = .darkGray
        CancelButton.backgroundColor = .darkGray
    }
    
    func gestureSetup()
    {
        TimerViewController.longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        TimerViewController.longPress.allowableMovement = 50
        TimerViewController.longPress.minimumPressDuration = TimeInterval(ViewController.holdingTime)
        self.view.addGestureRecognizer(TimerViewController.longPress)
    }
    
    @IBAction func CancelPressed(_ sender: Any) {
        
        TimerViewController.resultTime = 0
        self.performSegue(withIdentifier: "goToViewController", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touches began")
        if timerPhase == INSPECTION && ViewController.holdingTime > 0.01
        {
            TimerLabel.textColor = UIColor.red
            timerPhase = FROZEN
        }
        else if timerPhase == TIMING
        {
            stopTimer()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) // released before minimum hold time
    {
        print("touches ended")
        if(ViewController.holdingTime > 0.01)
        {
            if (timerPhase == FROZEN)
            {
                cancel()
            }
        }
    }
    
    func startInspection()
    {
        timerPhase = INSPECTION
        var inspectionTime = 15
        TimerLabel.text = String(inspectionTime)
        inspectionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block:
            { (time) in
            if(self.timerPhase == self.INSPECTION || self.timerPhase == self.FROZEN || self.timerPhase == self.READY)
            {
                inspectionTime -= 1
                if(inspectionTime > 0) // stops at 0
                {
                    self.TimerLabel.text = String(inspectionTime)
                }
                else if(inspectionTime > -2)
                {
                    self.TimerLabel.text = "+2"
                    self.PenaltySelector.selectedSegmentIndex = 2
                    
                }
                else
                {
                    self.TimerLabel.text = "DNF"
                    self.PenaltySelector.selectedSegmentIndex = 0
                }
            }
            else
            {
                return
            }
        })
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) // time has been done
    {
        if(sender.state == .began && timerPhase == FROZEN || ViewController.holdingTime < 0.01 && timerPhase == INSPECTION) // skip from inspection to ready when 0.0
        {
            TimerLabel.textColor = .green
            timerPhase = READY
        }
        else if(ViewController.holdingTime < 0.01 && timerPhase == TIMING)
        {
            stopTimer()
        }
        else if(sender.state == .cancelled)
        {
            cancel()
        }
        else if(sender.state == .ended && timerPhase == READY) // actually released from screen
        {
            startTimer()
        }
    }
    
    func cancel()
    {
        if(ViewController.darkMode)
        {
            TimerLabel.textColor = UIColor.white
        }
        else
        {
            TimerLabel.textColor = UIColor.black
        }
        timerPhase = INSPECTION
    }
    
    func startTimer()
    {
        inspectionTimer.invalidate()
        timerTime = 0
        timerPhase = TIMING
        if(ViewController.darkMode)
        {
            TimerLabel.textColor = UIColor.white
        }
        else
        {
            TimerLabel.textColor = UIColor.black
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {_ in
            
            if(self.timerPhase == self.TIMING)
            {
                self.timerTime += 0.01
                if(self.timerTime < 60.00)
                {
                    print("ViewController.timerUpdate \(ViewController.timerUpdate)")
                    if(ViewController.timerUpdate == 0) // timer update
                    {
                        self.TimerLabel.text = String(format: "%.2f", self.timerTime)
                    }
                    else if(ViewController.timerUpdate == 1) // seconds update
                    {
                        self.TimerLabel.text = String(format: "%.0f", floor(self.timerTime))
                    }
                    else // no update
                    {
                        self.TimerLabel.text = "solve"
                    }
                }
                else
                {
                    self.TimerLabel.text = SolveTime.makeMyString(num: SolveTime.makeIntTime(num: self.timerTime))
                }
            }
            else
            {
                return
            }
        })
        
    }
    
    func stopTimer()
    {
        self.TimerLabel.text = String(format: "%.2f", self.timerTime)
        TimerViewController.resultTime = self.timerTime
        timer.invalidate()
        timerPhase = IDLE
        PenaltySelector.isHidden = false
        SubmitButton.isHidden = false
        if(ViewController.holdingTime < 0.01)
        {
            self.view.removeGestureRecognizer(TimerViewController.longPress)
        }
        CancelButton.isHidden = false
    }
    
    @IBAction func SubmitButton(_ sender: Any) {
        
        if(ViewController.mySession.currentIndex < 4 && ViewController.ao5 || ViewController.mySession.currentIndex < 2 && (ViewController.mo3 || ViewController.bo3))
        {
            self.performSegue(withIdentifier: "goToViewController", sender: self)
        }
        else // (ViewController.currentIndex == 4)
        {
            let realm = try! Realm()
            try! realm.write {
                ViewController.mySession.addSolve(time: String(TimerViewController.resultTime), penalty: penalties[PenaltySelector.selectedSegmentIndex])
            }
            self.performSegue(withIdentifier: "goToResultViewController", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(ViewController.mySession.currentIndex < 4)
        {
            TimerViewController.penalty = penalties[PenaltySelector.selectedSegmentIndex]
        }
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
