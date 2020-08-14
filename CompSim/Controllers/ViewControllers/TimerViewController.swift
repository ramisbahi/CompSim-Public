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
import Foundation
import CoreBluetooth

class TimerViewController: UIViewController {
    
    let IDLE = 0
    let INSPECTION = 1
    let FROZEN = 2
    let READY = 3
    let TIMING = 4
    var timerPhase = 0
    var timerTime: TimeInterval = 0.00
    var inspectionTimer = Timer()
    var timer = Timer()
    let penalties = [2, 0, 1] // index of selector --> penalty (DNF, none, +2)
    
    var startTime: UInt64 = 0
    
    static var longPress = UILongPressGestureRecognizer()
    
    @IBOutlet weak var DarkBackground: UIImageView!
    
    static var resultTime: TimeInterval = 0.0
    static var penalty = 0
    
    var audioPlayer = AVAudioPlayer()
    @IBOutlet var BigView: UIView!
    
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var SubmitButton: UIButton!

    @IBOutlet weak var TimerLabel: UILabel!
    @IBOutlet weak var CancelButton: UIButton!
    
    static let fractionFormatter = NumberFormatter()
    static let timeFormatter = DateComponentsFormatter()
    
    var peripheralManager: CBPeripheralManager?
    
    var observer: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(false)
        if(HomeViewController.inspection && HomeViewController.timing != 2) // for now, not doing inspection with stackmat
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
        
        TimerLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.22, name: "Lato-Regular")
        SubmitButton.titleLabel?.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.065, name: "Lato-Black")
        let widthFont = HomeViewController.fontToFitWidth(text: "SUBMIT", view: SubmitButton, multiplier: 0.87, name: "Lato-Black")
        if widthFont.pointSize < (SubmitButton.titleLabel?.font.pointSize)!
        {
            SubmitButton.titleLabel?.font = widthFont
        }
        
        if(HomeViewController.inspection)
        {
            self.gestureSetup()
        }
        
        if(HomeViewController.darkMode)
        {
            makeDarkMode()
        }
        CancelButton.titleLabel?.font = HomeViewController.fontToFitHeight(view: CancelButton, multiplier: 0.75, name: "Lato-Black")
        let stringSize = CancelButton.titleLabel?.intrinsicContentSize.width
        CancelButton.widthAnchor.constraint(equalToConstant: stringSize! + 45).isActive = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    override func viewDidLayoutSubviews() {
        let unselectedColor: UIColor = HomeViewController.darkMode ? HomeViewController.darkModeColor() : .white
        PenaltySelector!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: unselectedColor, NSAttributedString.Key.font: HomeViewController.fontToFitHeight(view: PenaltySelector, multiplier: 0.7, name: "Lato-Black")], for: .normal) //- later make white
        PenaltySelector!.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white]   , for: .selected) //- later make white
    }
    
    static func initializeFormatters()
    {
        TimerViewController.timeFormatter.allowedUnits = [.hour, .minute, .second]
        TimerViewController.timeFormatter.unitsStyle = .positional
        TimerViewController.timeFormatter.zeroFormattingBehavior = .dropLeading
        
        TimerViewController.fractionFormatter.maximumIntegerDigits = 0
        TimerViewController.fractionFormatter.minimumFractionDigits = 2
        TimerViewController.fractionFormatter.maximumFractionDigits = 2
        TimerViewController.fractionFormatter.roundingMode = .down
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        TimerLabel.textColor = .white
        SubmitButton.backgroundColor = HomeViewController.darkPurpleColor()
        CancelButton.backgroundColor = HomeViewController.darkPurpleColor()
        
    }
    
    func gestureSetup()
    {
        TimerViewController.longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        TimerViewController.longPress.allowableMovement = 50
        TimerViewController.longPress.minimumPressDuration = TimeInterval(HomeViewController.holdingTime)
        
        self.view.addGestureRecognizer(TimerViewController.longPress)
    }
    
    @IBAction func CancelPressed(_ sender: Any) {
        
        TimerViewController.resultTime = 0
        
        self.performSegue(withIdentifier: "goToViewController", sender: self)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if timerPhase == INSPECTION && HomeViewController.holdingTime > 0.01
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
        if(HomeViewController.holdingTime > 0.01)
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
        let eightPlayer = setUpEightSecSound()
        let twelvePlayer = setUpTwelveSecSound()
        inspectionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block:
            { (time) in
            if(self.timerPhase == self.INSPECTION || self.timerPhase == self.FROZEN || self.timerPhase == self.READY)
            {
                inspectionTime -= 1
                if(inspectionTime > 0) // stops at 0
                {
                    self.TimerLabel.text = String(inspectionTime)
                    if(HomeViewController.inspectionSound)
                    {
                        if(inspectionTime == 8)
                        {
                            DispatchQueue.global(qos: .utility).async
                            {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) // call 0.3 sec early
                                {
                                    if(self.timerPhase == self.INSPECTION || self.timerPhase == self.FROZEN || self.timerPhase == self.READY)
                                    {
                                        eightPlayer?.play()
                                    }
                                }
                            }
                            
                        }
                        else if(inspectionTime == 4)
                        {
                            DispatchQueue.global(qos: .utility).async
                            {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) // call 0.3 sec early
                                {
                                    if(self.timerPhase == self.INSPECTION || self.timerPhase == self.FROZEN || self.timerPhase == self.READY)
                                    {
                                        twelvePlayer?.play()
                                    }
                                }
                            }
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
    
    func setUpEightSecSound() -> AVAudioPlayer?
    {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch(let error) {
            print(error.localizedDescription)
            return nil
        }
        let pathToSound = Bundle.main.path(forResource: "8seconds", ofType: "mp3")
        let url = URL(fileURLWithPath: pathToSound!)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            return audioPlayer
        }
        catch{
            return nil
        }
    }
    
    func setUpTwelveSecSound() -> AVAudioPlayer?
    {
        do {
           try AVAudioSession.sharedInstance().setCategory(.ambient)
        } catch(let error) {
            print(error.localizedDescription)
            return nil
        }
        let pathToSound = Bundle.main.path(forResource: "12seconds", ofType: "mp3")
        let url = URL(fileURLWithPath: pathToSound!)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.prepareToPlay()
            return audioPlayer
        }
        catch{
            return nil
        }
    }
    
    @objc func handleLongPress(sender: UILongPressGestureRecognizer) // time has been done
    {
        if(sender.state == .began && timerPhase == FROZEN || HomeViewController.holdingTime < 0.01 && timerPhase == INSPECTION) // skip from inspection to ready when 0.0
        {
            TimerLabel.textColor = .green
            timerPhase = READY
        }
        else if(HomeViewController.holdingTime < 0.01 && timerPhase == TIMING)
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
        TimerLabel.textColor = HomeViewController.darkMode ? .white : .black
        timerPhase = INSPECTION
    }
    
    func startTimer()
    {
        inspectionTimer.invalidate()
        timerPhase = TIMING
        
        TimerLabel.textColor = HomeViewController.darkMode ? .white : .black
        
        self.startTime = mach_absolute_time()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: {_ in
            
            if(self.timerPhase == self.TIMING)
            {
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
        if(HomeViewController.timerUpdate == 0) // timer update
        {
            setTimerTime()
            self.TimerLabel.text = self.timerTime.format(allowsFractionalUnits: true)
        }
        else if(HomeViewController.timerUpdate == 1) {// seconds update
            setTimerTime()
            self.TimerLabel.text = self.timerTime.format(allowsFractionalUnits: false)
        }
        else // no update
        {
            self.TimerLabel.text = "solve"
        }
    }
    
    func setTimerTime()
    {
        var info = mach_timebase_info()
        guard mach_timebase_info(&info) == KERN_SUCCESS else { return }
        let currentTime = mach_absolute_time()
        let nano = UInt64(currentTime - self.startTime) * UInt64(info.numer) / UInt64(info.denom)
        self.timerTime =  TimeInterval(nano) / 1000000000.0 
    }
    
    func stopTimer()
    {
        setTimerTime()
        self.TimerLabel.text = self.timerTime.format(allowsFractionalUnits: true)
        TimerViewController.resultTime = self.timerTime
        timer.invalidate()
        timerPhase = IDLE
        PenaltySelector.isHidden = false
        SubmitButton.isHidden = false
        if(HomeViewController.holdingTime < 0.01)
        {
            self.view.removeGestureRecognizer(TimerViewController.longPress)
        }
        CancelButton.isHidden = false
    }
    
    @IBAction func SubmitButton(_ sender: Any) {
        
        if(HomeViewController.mySession.currentIndex < 4 && HomeViewController.mySession.solveType == 0 || HomeViewController.mySession.currentIndex < 2 && (HomeViewController.mySession.solveType > 0))
        {
            self.performSegue(withIdentifier: "goToViewController", sender: self)
        }
        else // (HomeViewController.currentIndex == 4)
        {
            let realm = try! Realm()
            try! realm.write {
                HomeViewController.mySession.addSolve(time: self.timerTime.format(allowsFractionalUnits: true)!, penalty: penalties[PenaltySelector.selectedSegmentIndex])
            }
            self.performSegue(withIdentifier: "goToResultViewController", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(HomeViewController.mySession.currentIndex < 4)
        {
            TimerViewController.penalty = penalties[PenaltySelector.selectedSegmentIndex]
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        if HomeViewController.darkMode
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

extension TimeInterval {
    func format(allowsFractionalUnits: Bool) -> String?
    {
        var fractionString = ""
        if allowsFractionalUnits
        {
            let fractionalPart = NSNumber(value: self.truncatingRemainder(dividingBy: 1))
            fractionString = TimerViewController.fractionFormatter.string(from: fractionalPart) ?? ""
        }
         
        if var beforeDecimal = TimerViewController.timeFormatter.string(from: self)
        {
            // temporary solution to leading zeros which still can randomly appear 
            if self < 10 && self >= 1 && beforeDecimal[beforeDecimal.startIndex] == "0" || self < 1 && beforeDecimal == "00"
            {
                beforeDecimal = String(beforeDecimal.suffix(beforeDecimal.count - 1))
            }
            return beforeDecimal + fractionString
        }
        else
        {
            return nil
        }
        
    }
}
