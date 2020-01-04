//
//  TimerViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/8/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import GameKit
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
    
    var audioPlayer = AVAudioPlayer()
    @IBOutlet var BigView: UIView!
    
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
        
        TimerLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Geeza Pro")
        SubmitButton.titleLabel?.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.07, name: "Futura")
        PenaltySelector.setTitleTextAttributes([NSAttributedString.Key.font: ViewController.fontToFitHeight(view: BigView, multiplier: 0.025, name: "Futura")], for: .normal)
        
        if(ViewController.inspection)
        {
            self.gestureSetup()
        }
        
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
        //PenaltySelector!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal) - later make white\
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
                    if(ViewController.inspectionSound)
                    {
                        if(inspectionTime == 7)
                        {
                            self.eightSecSound()
                        }
                        else if(inspectionTime == 3)
                        {
                            self.twelveSecSound()
                        }
                    }
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
    
    func eightSecSound()
    {
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        let pathToSound = Bundle.main.path(forResource: "8seconds", ofType: "mp3")
        let url = URL(fileURLWithPath: pathToSound!)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        }
        catch{
            print("failed to play eight sec sound")
        }
    }
    
    func twelveSecSound()
    {
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        let pathToSound = Bundle.main.path(forResource: "12seconds", ofType: "mp3")
        let url = URL(fileURLWithPath: pathToSound!)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        }
        catch{
            print("failed to play twelve sec sound")
        }
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) // time has been done
    {
        print("timer view controller handling long press")
        if(sender.state == .began && timerPhase == FROZEN || ViewController.holdingTime < 0.01 && timerPhase == INSPECTION) // skip from inspection to ready when 0.0
        {
            print("called this bitch")
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
    
    func doMakeReady()
    {
        TimerLabel.textColor = .green
        timerPhase = READY
    }
    
    func cancel()
    {
        TimerLabel.textColor = ViewController.darkMode ? .white : .black
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
                self.updateLabel()
            }
            else
            {
                return
            }
        })
        
    }
    
    func updateLabel()
    {
        if(ViewController.timerUpdate == 0) // timer update
        {
            self.TimerLabel.text = SolveTime.makeMyString(num: SolveTime.makeIntTime(num: self.timerTime))
        }
        else if(ViewController.timerUpdate == 1) // seconds update
        {
            let fullString = SolveTime.makeMyString(num: SolveTime.makeIntTime(num: self.timerTime))
            self.TimerLabel.text = self.truncate(fullString)
        }
        else // no update
        {
            self.TimerLabel.text = "solve"
        }
    }
    
    func truncate(_ str: String) -> String
    {
        let period = str.firstIndex(of: ".")!
        let sub = str[..<period]
        return String(sub)
    }
    
    func stopTimer()
    {
        self.TimerLabel.text = SolveTime.makeMyString(num: SolveTime.makeIntTime(num: self.timerTime))
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
