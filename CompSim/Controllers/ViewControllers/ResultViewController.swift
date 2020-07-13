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
import StoreKit
import SAConfettiView

extension String {

    /// Generates a `UIImage` instance from this string using a specified
    /// attributes and size.
    ///
    /// - Parameters:
    ///     - attributes: to draw this string with. Default is `nil`.
    ///     - size: of the image to return.
    /// - Returns: a `UIImage` instance from this string using a specified
    /// attributes and size, or `nil` if the operation fails.
    func image(withAttributes attributes: [NSAttributedString.Key: Any]? = nil, size: CGSize? = nil) -> UIImage? {
        let size = size ?? (self as NSString).size(withAttributes: attributes)
        return UIGraphicsImageRenderer(size: size).image { _ in
            (self as NSString).draw(in: CGRect(origin: .zero, size: size),
                                    withAttributes: attributes)
        }
    }

}


class ResultViewController: UIViewController {

    @IBOutlet var BigView: UIView!
    @IBOutlet weak var BackgroundImage: UIImageView!
    
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
    
    var confettiView: SAConfettiView?
    
    // Additional setup after loading the view
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        try! realm.write {
            HomeViewController.mySession.finishAverage()
        }
        
        
        HomeViewController.totalAverages += 1 // add 1 to dat
        
        let ratings = [3, 10, 50, 200, 500, 1000, 1500, 2000, 2500, 3000]
        
        if(ratings.contains(HomeViewController.totalAverages))
        {
            if #available(iOS 10.3,*)
            {
                SKStoreReviewController.requestReview()
            }
        }
        
        if(HomeViewController.darkMode)
        {
            makeDarkMode()
        }
        
        TimerViewController.resultTime = 0 // set to 0 - we done
        labels = [SecondTime1, SecondTime2, SecondTime3, SecondTime4, SecondTime5]
        
        
        var numTimes = 3
        if(HomeViewController.mySession.solveType == 0)
        {
            numTimes = 5
        }
        for i in 0..<numTimes
        {
            labels[i].isEnabled = false
            labels[i].setTitle(HomeViewController.mySession.times[i].myString, for: .normal)
            labels[i].isHidden = false
        }
        
        if(HomeViewController.mySession.solveType == 0)
        {
            MyAverageLabel.text = "AVERAGE: \(HomeViewController.mySession.myAverage)" // update my average label
        }
        else
        {
            SecondTime4.isHidden = true
            SecondTime5.isHidden = true
            if(HomeViewController.mySession.solveType == 1)
            {
                MyAverageLabel.text = "MEAN: \(HomeViewController.mySession.myAverage)" // update my average label
            }
            else // best of 3
            {
                MyAverageLabel.text = "BEST: \(HomeViewController.mySession.myAverage)" // update my average label
            }
        }
        
        MyAverageLabel.isHidden = false
        TryAgainButton.isHidden = false
        
        BackgroundImage.isHidden = false
        try! realm.write
        {
            HomeViewController.mySession.usingWinningTime.append(true)
                 // update winning average label & win/lose
        }
        
        updateWinningAverage()
        
        times = Array(HomeViewController.mySession.times)
        
        // last thing done - reset
        try! realm.write
        {
            HomeViewController.mySession.reset()
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
        WinningAverageLabel.textColor? = UIColor.white
        MyAverageLabel.textColor? = UIColor.white
        TryAgainButton.backgroundColor = HomeViewController.darkPurpleColor()
        TimesCollection.forEach { (button) in
            button.setTitleColor(.white, for: .normal)
        }
        
        BigView.backgroundColor = HomeViewController.darkModeColor()
    }
    
    func updateWinningAverage() // calculate average and update label
    {
        let winningAverage: Int = HomeViewController.mySession.singleTime // for single time
        
        let target = NSLocalizedString("TARGET:  ", comment: "")
        let targetString = NSMutableAttributedString(string: "\(target)\(SolveTime.makeMyString(num: winningAverage))", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
       targetString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: target.count, length: targetString.length - target.count))
        WinningAverageLabel.attributedText = targetString
        WinningAverageLabel.isHidden = false
        
        try! realm.write
        {
            HomeViewController.mySession.winningAverages.append(SolveTime.makeMyString(num: winningAverage))
        }
        
        if(HomeViewController.mySession.myAverageInt < winningAverage)
        {
            self.win()
        } // no more ties
        else
        {
            self.lose() // loss
        }
        
        
    }
    
    func lose()
    {
        try! realm.write {
            HomeViewController.mySession.results.append(false)
        }
        if HomeViewController.cuber == NSLocalizedString("Random", comment: "")
        {
            BackgroundImage.image = randomImage(happy: false)
        }
        else
        {
            BackgroundImage.image = UIImage(named: "sad\(HomeViewController.cuber)")
        }
        MyAverageLabel.textColor = .red
        MyAverageLabel.text = MyAverageLabel.text
        
        sadConfetti()
        
    }
    
    func win()
    {
        try! realm.write {
            HomeViewController.mySession.results.append(true) // win
        }
        if(HomeViewController.cuber == NSLocalizedString("Random", comment: ""))
        {
            BackgroundImage.image = randomImage(happy: true)
        }
        else
        {
            BackgroundImage.image = UIImage(named: "happy\(HomeViewController.cuber)")
        }
        MyAverageLabel.textColor = HomeViewController.greenColor()
        MyAverageLabel.text = MyAverageLabel.text
        
        happyConfetti()
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
        let alert = alertService.alert(usingPenalty: false, delete: false, title: myTitle!, scramble: myScramble, penalty: 0, completion:
        {})
        
        self.present(alert, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        WinningAverageLabel.font = WinningAverageLabel.font.withSize(min(HomeViewController.fontToFitWidth(text: WinningAverageLabel.text!, view: WinningAverageLabel, multiplier: 0.9, name: "Lato-Black").pointSize, HomeViewController.fontToFitHeight(view: WinningAverageLabel, multiplier: 0.9, name: "Lato-Black").pointSize))
        MyAverageLabel.font = MyAverageLabel.font.withSize(min(HomeViewController.fontToFitWidth(text: MyAverageLabel.text!, view: BigView, multiplier: 0.9, name: "Lato-Black").pointSize, HomeViewController.fontToFitHeight(view: MyAverageLabel, multiplier: 0.9, name: "Lato-Black").pointSize))
    }
    
    func sadConfetti()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65)
        {
            self.confettiView!.colors = [.white, .white, .white, .white, .white]
            self.confettiView!.type = .image(UIImage(named: "crying")!)
            self.confettiView!.startConfetti()
        }
    }
    
    func happyConfetti()
    {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65)
        {
            self.confettiView?.startConfetti()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        confettiView = SAConfettiView(frame: self.view.bounds)
        self.view.addSubview(confettiView!)
        self.view.sendSubviewToBack(confettiView!)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))

        BackgroundImage.addGestureRecognizer(tapGesture)
        BackgroundImage.isUserInteractionEnabled = true
        
        
        let newDevices = ["x86_64", "iPhone10,3", "iPhone10,6", "iPhone11,2", "iPhone11,4", "iPhone11,6", "iPhone11,8", "iPhone12,1", "iPhone12,3", "iPhone12,5"] // have weird thing at top of screen
        
        if newDevices.contains(HomeViewController.deviceName)
        {
            ImageConstraint.isActive = false
            BackgroundImage.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        }
        
        timeConstraints()
        TimesCollection.forEach{(button) in
            button.titleLabel?.font = HomeViewController.font!
        }
        
       
        
        TryAgainButton.titleLabel?.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.05, name: "Lato-Black")
        let stringSize = TryAgainButton.titleLabel?.intrinsicContentSize.width
        TryAgainButton.widthAnchor.constraint(equalToConstant: stringSize! + 30).isActive = true
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
        do {
           try AVAudioSession.sharedInstance().setCategory(.playback)
        } catch(let error) {
            print(error.localizedDescription)
        }
        if(HomeViewController.mySession.results.last!) // win
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
        if HomeViewController.darkMode
        {
            return .lightContent
        }
        return .default
    }
    

}
