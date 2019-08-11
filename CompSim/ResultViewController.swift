//
//  ResultViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/16/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

import GameKit

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
    
    
    var labels = [UIButton]()
    
    var myAverage: Int = 0
    
    
    
    // Additional setup after loading the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        labels = [SecondTime1, SecondTime2, SecondTime3, SecondTime4, SecondTime5]

        var total: Int = 0
        var timeStrings: [String] = []
        
        for i in 0..<5
        {
            let currentTime: Int = ViewController.times[i]
            let currentTimeString: String =  ViewController.hundredthString(num: currentTime)
            
            if(i == ViewController.minIndex || i == ViewController.maxIndex) // min/max time, so add parentheses
            {
                labels[i].setTitle("(" + currentTimeString + ")", for: .normal)
                timeStrings.append("(" + currentTimeString + ")")
            }
            else // calculated in average
            {
                labels[i].setTitle(currentTimeString, for: .normal)
                total += currentTime
                timeStrings.append(currentTimeString)
            }
            labels[i].isHidden = false
        }
        
        
        myAverage = (total + 1) / 3 // will end up doing average for ints
        let averageString: String = ViewController.hundredthString(num: myAverage)
        MyAverageLabel.text = "= " + averageString + " Average!" // update my average label
        MyAverageLabel.isHidden = false
        TryAgainButton.isHidden = false
        ViewController.currentAverage += 1
        ViewController.allTimes[ViewController.currentAverage] = timeStrings // add the strings for the times in average
        ViewController.averages.append(averageString) // add the actual average (i.e. "1.45")
        
        
        
       if(SettingsViewController.noWinning) // no winning time
       {
            ResultButton.isHidden = true
            WinningAverageLabel.isHidden = true
            BackgroundImage.isHidden = true
            ViewController.usingWinningTime.append(false)
        
        // instead of updateWinningAverage():
            ViewController.winningAverages.append("") // blank string for average
            ViewController.results.append(true) // win for winning (not used tho)
       }
       else // winning time
       {
            ResultButton.isHidden = false
            WinningAverageLabel.isHidden = false
            BackgroundImage.isHidden = false
            ViewController.usingWinningTime.append(true)
            updateWinningAverage() // update winning average label & win/lose
        }
        
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
        var winningAverage: Int = ViewController.maxTime // for single time
        if(SettingsViewController.rangeWinning)
        {
            let random = GKRandomSource()
            let winningTimeDistribution = GKGaussianDistribution(randomSource: random, lowestValue: ViewController.minTime, highestValue: ViewController.maxTime) // now using ints pays off. Distribution created easily
            winningAverage = winningTimeDistribution.nextInt()
        }
        
        WinningAverageLabel.text = "Winning Average: " + ViewController.hundredthString(num: winningAverage) // update label
        WinningAverageLabel.isHidden = false
        
        ViewController.winningAverages.append(ViewController.hundredthString(num: winningAverage))
        
        if(myAverage < winningAverage)
        {
            self.win()
        }
        else if(myAverage == winningAverage) // 50% chance of winning in event of a tie
        {
            let rand = Int.random(in: 0...1)
            if(rand == 0)
            {
                self.win()
            }
            else // 1
            {
                ViewController.results.append(false)
            }
        }
        else
        {
            ViewController.results.append(false) // loss
        }
        
        ResultButton.isHidden = false
        
    }
    
    func win()
    {
        ViewController.results.append(true) // win
        ResultButton.setTitleColor(UIColor.green, for: .normal)
        ResultButton.setTitle("You WIN!", for: .normal)
        BackgroundImage.image = UIImage(named: "background")
    }
    
    
    // prepare for going back to (compsim) viewcontroller
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        ViewController.roundNumber += 1
        ViewController.currentIndex = 0 // reset
        ViewController.times = [] // reset
        ViewController.minIndex = 0 // reset
        ViewController.maxIndex = 1 // reset
        
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
        
        let alert = UIAlertController(title: myText, message: ViewController.scrambler.getScramble(number: (ViewController.roundNumber - 2) * 5 + num), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
