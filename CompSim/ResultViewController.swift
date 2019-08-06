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
    
    @IBOutlet weak var SecondTime1: UIButton!
    @IBOutlet weak var SecondTime2: UIButton!
    @IBOutlet weak var SecondTime3: UIButton!
    @IBOutlet weak var SecondTime4: UIButton!
    @IBOutlet weak var SecondTime5: UIButton!
    
    
    @IBOutlet weak var MyAverageLabel: UILabel!
    @IBOutlet weak var WinningAverageLabel: UILabel!
    @IBOutlet weak var ResultLabel: UILabel!
    
    @IBOutlet weak var TryAgainButton: UIButton!
    
    var labels = [UIButton]()
    
    var myAverage: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        labels = [SecondTime1, SecondTime2, SecondTime3, SecondTime4, SecondTime5]

        var total: Int = 0
        
        for i in 0..<5
        {
            let currentTime = ViewController.times[i]
            
            if(i == ViewController.minIndex || i == ViewController.maxIndex)
            {
                labels[i].setTitle("(" + ViewController.hundredthString(num: currentTime) + ")", for: .normal)
            }
            else // calculated in average
            {
                labels[i].setTitle(ViewController.hundredthString(num: currentTime), for: .normal)
                total += ViewController.times[i]
            }
            labels[i].isHidden = false
        }
        
        myAverage = (total + 1) / 3 // will end up doing average for ints
        MyAverageLabel.text = "= " + ViewController.hundredthString(num: myAverage) + " Average!" // update my average label
        MyAverageLabel.isHidden = false
        
        updateWinningAverage() // update winning average label & win/lose
        
        TryAgainButton.isHidden = false
        
        
        
        // Do any additional setup after loading the view.
    }
    
    func updateWinningAverage() // calculate average and update label
    {
        let random = GKRandomSource()
        let winningTimeDistribution = GKGaussianDistribution(randomSource: random, lowestValue: ViewController.minTime, highestValue: ViewController.maxTime) // now using ints pays off. Distribution created easily
        let winningAverage: Int = winningTimeDistribution.nextInt()
        WinningAverageLabel.text = "Winning Average: " + ViewController.hundredthString(num: winningAverage) // update label
        WinningAverageLabel.isHidden = false
        
        if(myAverage <= winningAverage)
        {
            ResultLabel.textColor = UIColor.green
            ResultLabel.text = "You WIN!"
            BackgroundImage.image = UIImage(named: "background")
        }
        ResultLabel.isHidden = false
        
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
