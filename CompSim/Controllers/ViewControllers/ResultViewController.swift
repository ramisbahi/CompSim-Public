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

    @IBOutlet weak var BackgroundImage: UIImageView!
    @IBOutlet weak var DarkBackground: UIImageView!
    
    @IBOutlet weak var SecondTime1: UIButton!
    @IBOutlet weak var SecondTime2: UIButton!
    @IBOutlet weak var SecondTime3: UIButton!
    @IBOutlet weak var SecondTime4: UIButton!
    @IBOutlet weak var SecondTime5: UIButton!
    
    
    @IBOutlet weak var MyAverageLabel: UILabel!
    @IBOutlet weak var WinningAverageLabel: UILabel!
    
    @IBOutlet weak var ResultButton: UIButton!
    @IBOutlet weak var TryAgainButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    let realm = try! Realm()
    
    var labels = [UIButton]()
    
    // Additional setup after loading the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        TimerViewController.resultTime = 0 // set to 0 - we done
        labels = [SecondTime1, SecondTime2, SecondTime3, SecondTime4, SecondTime5]
        
        print("ao5: \(ViewController.ao5)")
        print("mo3: \(ViewController.mo3)")
        
        var numTimes = 3
        if(ViewController.ao5)
        {
            numTimes = 5
        }
        for i in 0..<numTimes
        {
            labels[i].setTitle(ViewController.mySession.times[i].myString, for: .normal)
            labels[i].isHidden = false
        }
        
        if(ViewController.ao5)
        {
            MyAverageLabel.text = "= " + ViewController.mySession.myAverage + " Average!" // update my average label
        }
        else if(ViewController.mo3)
        {
            MyAverageLabel.text = "= " + ViewController.mySession.myAverage + " Mean!" // update my average label
        }
        
        MyAverageLabel.isHidden = false
        TryAgainButton.isHidden = false
       if(TargetViewController.noWinning) // no winning time
       {
            ResultButton.isHidden = true
            WinningAverageLabel.isHidden = true
            BackgroundImage.isHidden = true
            
            try! realm.write {
                ViewController.mySession.usingWinningTime.append(false)
        
                // instead of updateWinningAverage():
                ViewController.mySession.winningAverages.append("") // blank string for average
                ViewController.mySession.results.append(true) // win for winning (not used tho)
            }
       }
       else // winning time
       {
            ResultButton.isHidden = false
            WinningAverageLabel.isHidden = false
            BackgroundImage.isHidden = false
            try! realm.write {
                ViewController.mySession.usingWinningTime.append(true)
                     // update winning average label & win/lose
                }
            }
        updateWinningAverage()
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        WinningAverageLabel.textColor? = UIColor.white
        MyAverageLabel.textColor? = UIColor.white
        TryAgainButton.setTitleColor(ViewController.orangeColor(), for: .normal)
        TimesCollection.forEach { (button) in
            button.setTitleColor(ViewController.orangeColor(), for: .normal)
        }
    }
    
    func updateWinningAverage() // calculate average and update label
    {
        var winningAverage: Int = ViewController.mySession.maxTime // for single time
        if(TargetViewController.rangeWinning)
        {
            let random = GKRandomSource()
            let winningTimeDistribution = GKGaussianDistribution(randomSource: random, lowestValue: ViewController.mySession.minTime, highestValue: ViewController.mySession.maxTime) // now using ints pays off. Distribution created easily
            winningAverage = winningTimeDistribution.nextInt()
        }
        
        if(ViewController.ao5)
        {
            WinningAverageLabel.text = "Target Average: " + SolveTime.makeMyString(num: winningAverage) // update label
        }
        else if(ViewController.mo3)
        {
            WinningAverageLabel.text = "Target Mean: " + SolveTime.makeMyString(num: winningAverage) // update label
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
        
        ResultButton.isHidden = false
        
    }
    
    func lose()
    {
        try! realm.write {
            ViewController.mySession.results.append(false)
        }
        BackgroundImage.image = UIImage(named: "sad\(ViewController.cuber)")
    }
    
    func win()
    {
        try! realm.write {
            ViewController.mySession.results.append(true) // win
        }
        ResultButton.setTitleColor(UIColor.green, for: .normal)
        ResultButton.setTitle("You WIN!", for: .normal)
        BackgroundImage.image = UIImage(named: "happy\(ViewController.cuber)")
    }
    
    
    // prepare for going back to (compsim) viewcontroller
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        try! realm.write {
            ViewController.mySession.roundNumber += 1
            ViewController.mySession.reset()
        }
        // Do any additional setup after loading the view.
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
        let myText = self.labels[num].titleLabel!.text
        
        let alert = UIAlertController(title: myText, message: ViewController.mySession.scrambler.getScramble(number: (ViewController.mySession.roundNumber - 2) * 5 + num), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
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
