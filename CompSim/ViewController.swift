//
//  ViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    

    
    @IBOutlet weak var Time1: UIButton!
    @IBOutlet weak var Time2: UIButton!
    @IBOutlet weak var Time3: UIButton!
    @IBOutlet weak var Time4: UIButton!
    @IBOutlet weak var Time5: UIButton!
    
    
    
    
    @IBOutlet weak var ScrambleLabel: UILabel!
    
    static let scrambler: ScrambleReader = ScrambleReader()
    
    static var roundNumber: Int = 1
    
    static var currentIndex: Int = 0
    
    // (roundNumber - 1) * 5 + currentIndex = total solve index (starts at 0)
    
    static var minTime: Int = 100
    static var maxTime: Int = 200
    
    static var minIndex: Int = 0 // index of minimum time in average
    static var maxIndex: Int = 1 // index of maximum time in average
    
    @IBOutlet weak var MinTimeLabel: UIButton!
    @IBOutlet weak var MaxTimeLabel: UIButton!
    
    var labels = [UIButton]()
    
    static var times = [Int]()
    static var averages: [String] = []
    static var winningAverages: [String] = []
    static var usingWinningTime: [Bool] = [] // for each round, whether or not using winning time
    static var allTimes: [[String]] = Array(repeating: Array(repeating: "", count: 5), count: 1000)
    static var currentAverage: Int = -1 // keeps track of last average currently on (round - 2)
    static var results: [Bool] = []
    
    
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.swipeSetup()
        self.labels = [Time1, Time2, Time3, Time4, Time5] // add labels to labels array - one time thing
        
        if(!AverageDetailViewController.justReturned)
        {
            self.reset() // only when actually starting new round
        }
        else // just returned
        {
            self.updateTimeLabels()
            AverageDetailViewController.justReturned = false
        }
        
    }
    
    
    func swipeSetup()
    {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipe(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeUp.direction = .up // ...when up swipe is done
        self.view.addGestureRecognizer(swipeUp) // allow view to recognize
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipe(gesture:))) // swipeUp is a gesture recognizer that will run respondToUpSwipe function and will be its parameter
        swipeDown.direction = .down // ...when down swipe is done
        self.view.addGestureRecognizer(swipeDown) // allow view to recognize
    }
    
    func reset()
    {
        ViewController.currentIndex = 0 // reset
        ViewController.times = [] // reset
        ViewController.minIndex = 0 // reset
        ViewController.maxIndex = 1 // reset
        ScrambleLabel.text = String(ViewController.scrambler.nextScramble()) // next scramble
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(false)
        ScrambleLabel.text = ViewController.scrambler.getCurrentScramble()
    }
    
    
    static func hundredthRound(num: Double) -> Int // convert to rounded int (i.e. 1.493 --> 149, 1.496 --> 150. Rounding is necessary when calculating averages)
    {
        return Int(num * 100 + 0.5)
    }
    
    static func hundredthString(num: Int) -> String // 149 --> 1.49
    {
        let stringNum: String = String(num)
        let beforeDecimal = String(stringNum.prefix(stringNum.count - 2))
        let afterDecimal = String(stringNum.suffix(2))
        return beforeDecimal + "." + afterDecimal
    }
    
   
    
    func alertValidTime(alertMessage: String)
    {
        let alert = UIAlertController(title: alertMessage, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    
    
    @objc func respondToSwipe(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer
        {
            switch(swipeGesture.direction)
            {
                case .up:
                    addSolve()
                case .down:
                    if(ViewController.times.count > 0)
                    {
                        deleteSolve()
                    }
                default:
                    break
            }
        }
    }
    
    func deleteSolve()
    {
        let alert = UIAlertController(title: "Delete last solve?", message: "", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .cancel, handler: {
            [weak alert] (_) in
            // Confirming deleted solve
            ViewController.times.removeLast()
            ViewController.currentIndex -= 1
            self.labels[ViewController.currentIndex].setTitle("", for: .normal)
            self.labels[ViewController.currentIndex].isHidden = true
            self.ScrambleLabel.text = ViewController.scrambler.previousScramble()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            [weak alert] (_) in
            
        })
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        self.present(alert, animated: true)
    }
    
    func addSolve()
    {
        let alert = UIAlertController(title: "Add Solve", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Time in seconds"
            textField.keyboardType = .decimalPad
        })
        
        
        
        let enterAction = UIAlertAction(title: "Enter", style: .cancel, handler: {
            
            // Everything in here is executed when a time is entered
            
            [weak alert] (_) in
            
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists. Let that textfield string storing your time
            let inputTime = textField.text!
            
            
            if let time = Double(inputTime)
            {
                self.updateTimes(enteredTime: time) // add time, show label, change parentheses
            }
            else
            {
                self.alertValidTime(alertMessage: "Please enter valid time")
            }
            
            
            
        }
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
            (action : UIAlertAction!) -> Void in
        }
        )
        
        alert.addAction(cancelAction)
        alert.addAction(enterAction)
        self.present(alert, animated: true)
    }
    
    // double is entered, converted to int for hundredth precision (i.e. 4.0 will become 400 now)
    // converted to string for proper representation (i.e. 4.0 will become 4.00 now)
    
    func updateTimes(enteredTime: Double)
    {
        let intTime = ViewController.hundredthRound(num: enteredTime) // now 1.49 --> 149
        ViewController.times.append(intTime) // add time to array
        
        ViewController.currentIndex += 1 // next index
        self.updateTimeLabels()
        
        if(ViewController.currentIndex < 5) // next scramble
        {
            print("in update times")
            ScrambleLabel.text = ViewController.scrambler.nextScramble() // change scramble
        }
        else // change view when 5 solves done
        {
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let resultViewController = storyBoard.instantiateViewController(withIdentifier: "ResultView") as! ResultViewController
            self.present(resultViewController, animated:false, completion:nil)
        }
    }
    
    func updateTimeLabels()
    {
        if(ViewController.currentIndex >= 3) // 3+ solves done - update min/maxes
        {
            for i in 0..<ViewController.currentIndex
            {
                if(ViewController.times[i] < ViewController.times[ViewController.minIndex])
                {
                    ViewController.minIndex = i
                }
                else if(ViewController.times[i] > ViewController.times[ViewController.maxIndex])
                {
                    ViewController.maxIndex = i
                }
            }
        }
        
        for i in 0..<ViewController.currentIndex
        {
            if(ViewController.currentIndex >= 3 && (i == ViewController.minIndex || i == ViewController.maxIndex)) // 3+ solves done, is max/min
            {
                self.labels[i].setTitle("(" + ViewController.hundredthString(num: ViewController.times[i]) + ")", for: .normal)
            }
            else
            {
                self.labels[i].setTitle( ViewController.hundredthString(num: ViewController.times[i]), for: .normal)
            }
            self.labels[i].isHidden = false
        }
        
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
        
        /*
        for scramble in ViewController.scrambler.scrambles
        {
            print(scramble)
        }*/
        let alert = UIAlertController(title: myText, message: ViewController.scrambler.getScramble(number: (ViewController.roundNumber - 1) * 5 + num), preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

