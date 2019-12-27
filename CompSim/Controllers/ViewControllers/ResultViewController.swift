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
    
    @IBOutlet weak var TryAgainButton: UIButton!
    
    @IBOutlet var TimesCollection: [UIButton]!
    
    let realm = try! Realm()
    
    var labels = [UIButton]()
    
    // Additional setup after loading the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
        
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
        print(TargetViewController.noWinning)
       if(TargetViewController.noWinning) // no winning time
       {
            WinningAverageLabel.text = ""
            BackgroundImage.image = UIImage(named: "happy\(ViewController.cuber)")
            
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
        if(TargetViewController.rangeWinning)
        {
            let random = GKRandomSource()
            let winningTimeDistribution = GKGaussianDistribution(randomSource: random, lowestValue: ViewController.mySession.minTime, highestValue: ViewController.mySession.maxTime) // now using ints pays off. Distribution created easily
            winningAverage = winningTimeDistribution.nextInt()
        }
        
        if(ViewController.ao5)
        {
            WinningAverageLabel.text = "Target: " + SolveTime.makeMyString(num: winningAverage) + " Average" // update label
        }
        else if(ViewController.mo3)
        {
            WinningAverageLabel.text = "Target: " + SolveTime.makeMyString(num: winningAverage) + " Mean" // update label
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
        BackgroundImage.image = UIImage(named: "sad\(ViewController.cuber)")
        MyAverageLabel.textColor = .red
        MyAverageLabel.text = MyAverageLabel.text
    }
    
    func win()
    {
        try! realm.write {
            ViewController.mySession.results.append(true) // win
        }
        BackgroundImage.image = UIImage(named: "happy\(ViewController.cuber)")
        MyAverageLabel.textColor = .green
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
        let myText = self.labels[num].titleLabel!.text
        /*print(ViewController.mySession.times)
        print(ViewController.mySession.currentAverage)
        print((ViewController.mySession.currentAverage + 1) * 5 + num)*/
        let scramble = ViewController.mySession.times[num].myScramble
        
        let alert = UIAlertController(title: myText, message: scramble, preferredStyle: .alert)
        
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
    
    // MARK: - Navigation

//     In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("called prepare")
        try! realm.write {
            ViewController.mySession.reset()
        }
    }
    

}
