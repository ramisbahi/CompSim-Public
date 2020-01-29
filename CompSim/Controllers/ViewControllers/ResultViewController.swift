//
//  ResultViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/16/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

import GameKit
import RealmSwift

class ResultViewController: UIViewController {

    @IBOutlet var BigView: UIView!
    @IBOutlet weak var BackgroundImage: UIImageView!
    @IBOutlet weak var DarkBackground: UIImageView!
    
    @IBOutlet weak var LogoImage: UIImageView!
    @IBOutlet weak var SecondTime1: UIButton!
    @IBOutlet weak var SecondTime2: UIButton!
    @IBOutlet weak var SecondTime3: UIButton!
    @IBOutlet weak var SecondTime4: UIButton!
    @IBOutlet weak var SecondTime5: UIButton!
    
    @IBOutlet weak var ImageConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var MyAverageLabel: UILabel!
    @IBOutlet weak var WinningAverageLabel: UILabel!
    
    @IBOutlet weak var TryAgainButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    let noWinning = 0
    let singleWinning = 1
    let rangeWinning = 2
    
    let realm = try! Realm()
    
    var labels = [UIButton]()
    
    var audioPlayer = AVAudioPlayer()
    
    let cubers = ["Bill", "Lucas", "Feliks", "Kian", "Rami", "Patrick", "Max", "Kevin"]
    
    var times: [SolveTime] = []
    
    // Additional setup after loading the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        try! realm.write {
            ViewController.mySession.finishAverage()
        }
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
        
        TimerViewController.resultTime = 0 // set to 0 - we done
        labels = [SecondTime1, SecondTime2, SecondTime3, SecondTime4, SecondTime5]
        
        
        var numTimes = 3
        if(ViewController.mySession.solveType == 0)
        {
            numTimes = 5
        }
        for i in 0..<numTimes
        {
            labels[i].setTitle(ViewController.mySession.times[i].myString, for: .normal)
            labels[i].isHidden = false
        }
        
        if(ViewController.mySession.solveType == 0)
        {
            MyAverageLabel.text = "= " + ViewController.mySession.myAverage + " Average!" // update my average label
        }
        else
        {
            SecondTime4.isHidden = true
            SecondTime5.isHidden = true
            if(ViewController.mySession.solveType == 1)
            {
                MyAverageLabel.text = "= " + ViewController.mySession.myAverage + " Mean!" // update my average label
            }
            else // best of 3
            {
                MyAverageLabel.text = "= " + ViewController.mySession.myAverage + " Single!" // update my average label
            }
        }
        
        MyAverageLabel.isHidden = false
        TryAgainButton.isHidden = false
        if(ViewController.mySession.targetType == noWinning) // no winning time
       {
            WinningAverageLabel.text = ""
            
            BackgroundImage.isHidden = true
            LogoImage.isHidden = false
            
            try! realm.write {
                ViewController.mySession.usingWinningTime.append(false)
        
                // instead of updateWinningAverage():
                ViewController.mySession.winningAverages.append("") // blank string for average
                ViewController.mySession.results.append(true) // win for winning (not used tho)
            }
       }
       else // winning time
       {
            WinningAverageLabel.isHidden = false
            BackgroundImage.isHidden = false
            try! realm.write {
                ViewController.mySession.usingWinningTime.append(true)
                     // update winning average label & win/lose
                }
            
            updateWinningAverage()
        }
        
        times = Array(ViewController.mySession.times)
        
        // last thing done - reset
        try! realm.write {
            ViewController.mySession.reset()
        }
    }
    
    func randomImage(happy: Bool) -> UIImage
    {
        let cuber = cubers.randomElement()
        if happy
        {
            return UIImage(named: "happy\(cuber!)")!
        }
        return UIImage(named: "sad\(cuber!)")!
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        WinningAverageLabel.textColor? = UIColor.white
        MyAverageLabel.textColor? = UIColor.white
        TryAgainButton.backgroundColor = .darkGray
        TimesCollection.forEach { (button) in
            button.setTitleColor(ViewController.orangeColor(), for: .normal)
        }
    }
    
    func updateWinningAverage() // calculate average and update label
    {
        var winningAverage: Int = ViewController.mySession.singleTime // for single time
        if(ViewController.mySession.targetType == rangeWinning)
        {
            let random = GKRandomSource()
            let winningTimeDistribution = GKGaussianDistribution(randomSource: random, lowestValue: ViewController.mySession.minTime, highestValue: ViewController.mySession.maxTime) // now using ints pays off. Distribution created easily
            winningAverage = winningTimeDistribution.nextInt()
        }
        
        if(ViewController.mySession.solveType == 0)
        {
            WinningAverageLabel.text = "Target: " + SolveTime.makeMyString(num: winningAverage) + " Average" // update label
        }
        else if(ViewController.mySession.solveType == 1)
        {
            WinningAverageLabel.text = "Target: " + SolveTime.makeMyString(num: winningAverage) + " Mean" // update label
        }
        else
        {
            WinningAverageLabel.text = "Target: " + SolveTime.makeMyString(num: winningAverage) + " Single" // update label
        }
        WinningAverageLabel.isHidden = false
        
        try! realm.write
        {
            ViewController.mySession.winningAverages.append(SolveTime.makeMyString(num: winningAverage))
        }
        
        if(ViewController.mySession.myAverageInt < winningAverage)
        {
            self.win()
        }
        else if(ViewController.mySession.myAverageInt == winningAverage) // 50% chance of winning in event of a tie
        {
            let rand = Int.random(in: 0...1)
            if(rand == 0)
            {
                self.win()
            }
            else // 1
            {
                self.lose()
            }
        }
        else
        {
            self.lose() // loss
        }
        
        
    }
    
    func lose()
    {
        try! realm.write {
            ViewController.mySession.results.append(false)
        }
        if(ViewController.cuber == "Random")
        {
            BackgroundImage.image = randomImage(happy: false)
        }
        else
        {
            BackgroundImage.image = UIImage(named: "sad\(ViewController.cuber)")
        }
        MyAverageLabel.textColor = .red
        MyAverageLabel.text = MyAverageLabel.text
    }
    
    func win()
    {
        try! realm.write {
            ViewController.mySession.results.append(true) // win
        }
        if(ViewController.cuber == "Random")
        {
            BackgroundImage.image = randomImage(happy: true)
        }
        else
        {
            BackgroundImage.image = UIImage(named: "happy\(ViewController.cuber)")
        }
        MyAverageLabel.textColor = ViewController.greenColor()
        MyAverageLabel.text = MyAverageLabel.text
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
        let myTitle = self.labels[num].titleLabel!.text
        let myScramble = times[num].myScramble
        
        let alertService = ViewSolveAlertService()
        let alert = alertService.alert(usingPenalty: false, title: myTitle!, scramble: myScramble, penalty: 0, completion:
        {})
        
        self.present(alert, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))

        BackgroundImage.addGestureRecognizer(tapGesture)
        BackgroundImage.isUserInteractionEnabled = true
        
        
        let newDevices = ["x86_64", "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", "iPhone12,1", "iPhone12,3", "iPhone12,5"] // have weird thing at top of screen
        
        if newDevices.contains(ViewController.deviceName)
        {
            ImageConstraint.isActive = false
            BackgroundImage.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
            WinningAverageLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.06, name: "Futura")
            MyAverageLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.075, name: "Futura")
        }
        else
        {
            WinningAverageLabel.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.07, name: "Futura")
            MyAverageLabel.font = ViewController.font!
        }
        
        timeConstraints()
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = ViewController.font!
        }
        MyAverageLabel.adjustsFontSizeToFitWidth = true
        WinningAverageLabel.adjustsFontSizeToFitWidth = true
        
        TryAgainButton.titleLabel?.font = ViewController.fontToFitHeight(view: BigView, multiplier: 0.06, name: "Futura")
    }
    
    func timeConstraints()
    {
        SecondTime1.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 45 + 0.25*BigView.frame.size.height).isActive = true
        SecondTime2.topAnchor.constraint(equalTo: SecondTime1.bottomAnchor).isActive = true
        SecondTime3.topAnchor.constraint(equalTo: SecondTime2.bottomAnchor).isActive = true
        SecondTime4.topAnchor.constraint(equalTo: SecondTime3.bottomAnchor).isActive = true
        SecondTime5.topAnchor.constraint(equalTo: SecondTime4.bottomAnchor).isActive = true
    }
    
    @objc func imageTapped()
    {
        print("image tapped")
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        if(ViewController.mySession.results.last!) // win
        {
            winningSound()
        }
        else
        {
            losingSound()
        }
    }
    
    func winningSound()
    {
        let pathToSound = Bundle.main.path(forResource: "cheer", ofType: "m4a")
        let url = URL(fileURLWithPath: pathToSound!)
        print(url)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        }
        catch{
            print("failed to play winning sound")
        }
    }
    
    func losingSound()
    {
        let pathToSound = Bundle.main.path(forResource: "Sad_Trombone", ofType: "mp3")
        let url = URL(fileURLWithPath: pathToSound!)
        print(url)
        
        do
        {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer.play()
        }
        catch{
            print("failed to play losing sound")
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
    

}
