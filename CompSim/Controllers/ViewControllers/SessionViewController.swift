//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/6/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

var bestPressed = false

class SessionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var DarkBackground: UIImageView!
    
    @IBOutlet weak var StatsTableView: UITableView!
    
    @IBOutlet weak var NewButton: UIButton!
    @IBOutlet weak var SessionButton: UIButton!
    
    var SessionCollection: [UIButton] = []
    
    static var myIndex = 0 // contains index of array hit
    
    @IBOutlet var SessionStackView: UIStackView!
    
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var DeleteButton: UIButton!
    
    @IBOutlet weak var BestSingleButton: UIButton!
    @IBOutlet weak var BestAverageButton: UIButton!
    
    @IBOutlet weak var WinningView: UIView!
    @IBOutlet weak var LosingView: UIView!
    
    @IBOutlet weak var WinningWidth: NSLayoutConstraint!
    @IBOutlet weak var LosingWidth: NSLayoutConstraint!
    @IBOutlet var BigView: UIView!
    
    @IBOutlet weak var TargetButton: UIButton!
    
    let realm = try! Realm()
    
    @IBAction func newSession(_ sender: Any) {
        
        let alertService = InputAlertService()
        let alert = alertService.alert(placeholder: "Name", keyboardType: 1, myTitle: "New Session",
                                       completion: {
            
            let input = alertService.myVC.TextField.text!
            
            let maxCharacters = 20
            
            if(input.count < maxCharacters && self.sessionNamed(title: input) == nil) // creating new session
            {
                self.createNewSession(name: input)
            }
            else if input.count >= maxCharacters
            {
                self.alertInvalid(alertMessage: "Session name too long!")
            }
            else // already used name
            {
                self.alertInvalid(alertMessage: "Session name already in use!")
            }
        })
        
        self.present(alert, animated: true)
    }
    
    @IBAction func resetPressed(_ sender: Any) {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: "Reset \(HomeViewController.mySession.name) session?", completion: {
            self.resetSession()
        })
        
        self.present(alert, animated: true)
    }
    
    func updateBarWidth()
    {
        let view = BigView // change
        
        let numAverages = HomeViewController.mySession.results.count
        var losingCount = 0
        var winningCount = 0
        
        if(numAverages > 0)
        {
            for index in 0..<numAverages
            {
                if SolveTime.makeIntTime(num: HomeViewController.mySession.allAverages[index].toFloatTime()) < HomeViewController.mySession.singleTime // win
                {
                    winningCount += 1
                }
                else // lose
                {
                    losingCount += 1
                }
            }
            
            WinningView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            LosingView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner]
            
            if winningCount == 0
            {
                LosingView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
            }
            else if losingCount == 0
            {
                WinningView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
            }
            
            WinningWidth.constant = (view!.frame.size.width - 30) * CGFloat(winningCount) / CGFloat(numAverages)
            LosingWidth.constant = (view!.frame.size.width - 30) * CGFloat(losingCount) / CGFloat(numAverages)
        }
        else
        {
            WinningWidth.constant = 0
            LosingWidth.constant = 0
        }
    }
    
    func resetSession()
    {
        let session = HomeViewController.mySession
        try! realm.write
        {
            session.allAverages.removeAll()
            session.averageTypes.removeAll()
            session.winningAverages.removeAll()
            session.usingWinningTime.removeAll()
            session.results.removeAll()
            session.allTimes.removeAll()
            session.currentAverage = -1
            session.reset()
        }
        HomeViewController.sessionChanged = true
        updateTargetButton()
        updateBestButtons()
        StatsTableView.reloadData()
        updateBarWidth()
    }
    
    func createNewSession(name: String)
    {
        let newSession = Session(name: name, enteredEvent: 1)
        
        HomeViewController.mySession = newSession // now current session
        HomeViewController.allSessions.append(newSession)
//        HomeViewController.allSessions[name] = newSession // map with name
        
        try! realm.write {
            realm.add(newSession)
            smartEvent(name: newSession.name, session: newSession)
        }
        
        self.updateNewSessionStackView()
        updateTargetButton()
        updateBestButtons()
        StatsTableView.reloadData()
        HomeViewController.sessionChanged = true
        updateBarWidth()
    }
    
    // called when creating new session
    func updateNewSessionStackView()
    {
        hideAll()
        let newButton = createButton(name: HomeViewController.mySession.name)
        SessionCollection.append(newButton)
        SessionStackView.addArrangedSubview(newButton)
        setUpStackView()
    }
    
    func smartEvent(name: String, session: Session)
    {
        switch name.lowercased()
        {
        case "2x2x2", "2x2":
            session.doEvent(enteredEvent: 0)
            //session.solveType = 0 - default anyway
        case "3x3x3", "3x3":
            session.doEvent(enteredEvent: 1)
            //session.solveType = 0
        case "4x4x4", "4x4":
            session.doEvent(enteredEvent: 2)
            //session.solveType = 0
        case "5x5x5", "5x5":
            session.doEvent(enteredEvent: 3)
            //session.solveType = 0
        case "6x6x6", "6x6":
            session.doEvent(enteredEvent: 4)
            session.solveType = 1
        case "7x7x7", "7x7":
            session.doEvent(enteredEvent: 5)
            session.solveType = 1
        case "pyra", "pyraminx":
            session.doEvent(enteredEvent: 6)
            //session.solveType = 0
        case "mega", "megaminx":
            session.doEvent(enteredEvent: 7)
            //session.solveType = 0
        case "sq-1", "sq1", "square1", "square-1":
            session.doEvent(enteredEvent: 8)
            //session.solveType = 0
        case "skewb", "skoob":
            session.doEvent(enteredEvent: 9)
            //session.solveType = 0
        case "clock":
            session.doEvent(enteredEvent: 10)
            //session.solveType = 0
        case "bld", "3bld", "blindfolded", "3x3 bld", "3x3 blindfolded":
            session.doEvent(enteredEvent: 11)
            session.solveType = 2
        default:
            break
        }
    }
    
    func doAvg()
    {
        HomeViewController.mySession.solveType = 0
    }
    
    func doMean()
    {
        HomeViewController.mySession.solveType = 1
    }
    
    
    
    // called whenever something changed with sessions
    func setUpStackView()
    {
        SessionButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMinXMinYCorner]
        DeleteButton.isEnabled = HomeViewController.allSessions.count > 1
        SessionButton.setTitle(HomeViewController.mySession.name, for: .normal)
        SessionCollection = []
        for session in HomeViewController.allSessions
        {
            let newButton = createButton(name: session.name)
            if session.name == HomeViewController.mySession.name
            {
                newButton.setTitleColor(HomeViewController.orangeColor(), for: .normal)
            }
            SessionCollection.append(newButton)
            SessionStackView.addArrangedSubview(newButton)
        }
    }
    
    func hideAll()
    {
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = true
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func createButton(name: String) -> UIButton
    {
        SessionCollection.forEach({button in
            button.layer.cornerRadius = 0.0
        })
        
        let retButton = UIButton(type: .system)
        retButton.setTitle(name, for: .normal)
        retButton.isHidden = true
        retButton.setTitleColor(.white, for: .normal)
        retButton.titleLabel?.font = UIFont(name: "Lato-Black", size: 17)
        retButton.backgroundColor = HomeViewController.darkBlueColor()
        retButton.isUserInteractionEnabled = true
        retButton.addTarget(self, action: #selector(SessionSelected(_:)), for: UIControl.Event.touchUpInside)
        retButton.layer.cornerRadius = 6.0
        retButton.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        return retButton
    }
    
    func alertInvalid(alertMessage: String)
    {
        let alertService = NotificationAlertService()
        let alert = alertService.alert(myTitle: alertMessage)
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    // returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return HomeViewController.mySession.currentAverage + 1 // returns # items
    }
    
    @IBAction func SessionButtonClicked(_ sender: Any) {
        
        if SessionCollection.count > 0
        {
            if SessionCollection[0].isHidden
            {
                SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
            }
            else
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
                {
                    self.SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
                }
            }
        }
        
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func SessionSelected(_ sender: UIButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3)
        {
            self.SessionButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        }
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
            button.setTitleColor(.white, for: .normal)
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        SessionButton.setTitle(title, for: .normal)
        sender.setTitleColor(HomeViewController.orangeColor(), for: .normal)
        
        if title != HomeViewController.mySession.name // exists,// not same - so switch session
        {
            HomeViewController.mySession = sessionNamed(title: title)!
            HomeViewController.mySession.updateScrambler()
            HomeViewController.sessionChanged = true
            updateTargetButton()
            updateBestButtons()
            StatsTableView.reloadData()
            updateBarWidth()
        }
        
    }
    
    func sessionNamed(title: String) -> Session?
    {
        for session in HomeViewController.allSessions
        {
            if session.name == title
            {
                return session
            }
        }
        return nil
    }
    
    @IBAction func TargetButtonPressed(_ sender: Any) {
        let alertService = InputAlertService()
        let alert = alertService.alert(placeholder: NSLocalizedString("Time", comment: ""),  keyboardType: 0, myTitle: NSLocalizedString("Target Time", comment: ""),
                                       completion: {
            
            let inputTime = alertService.myVC.TextField.text!
            
            if HomeViewController.validEntryTime(time: inputTime)
            {
               let temp = SolveTime(enteredTime: inputTime, scramble: "")
               let intTime = temp.intTime
               
               try! self.realm.write
               {
                   HomeViewController.mySession.singleTime = intTime
               }
                
               self.updateTargetButton()
               self.updateBarWidth()
               self.StatsTableView.reloadData()
            }
            else
            {
                self.alertValidTime()
            }
        })
        if !bestPressed // needs fixing
        {
            self.present(alert, animated: true)
        }
        else
        {
            bestPressed = false
        }
    }
    
    @IBAction func BestAveragePressed(_ sender: Any) {
        bestPressed = true
        let path: IndexPath = IndexPath(row: HomeViewController.mySession.currentAverage - bestAverageIndex!, section: 0)
        StatsTableView.selectRow(at: path, animated: true, scrollPosition: UITableView.ScrollPosition.top)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView(self.StatsTableView, didSelectRowAt: path)
        }
    }
    
    @IBAction func BestSinglePressed(_ sender: Any) {
        bestPressed = true
        let path: IndexPath = IndexPath(row: HomeViewController.mySession.currentAverage - bestSingleAverageIndex!, section: 0)
        //StatsTableView.scrollToRow(at: path, at: UITableView.ScrollPosition.top, animated: true)
        StatsTableView.selectRow(at: path, animated: true, scrollPosition: UITableView.ScrollPosition.top)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.tableView(self.StatsTableView, didSelectRowAt: path)
            bestSingleTransition = true
        }
    }
    
    
    func alertValidTime()
    {
        let alertService = NotificationAlertService()
        let alert = alertService.alert(myTitle: NSLocalizedString("Invalid Time", comment: ""))
        self.present(alert, animated: true, completion: nil)
        // ask again - no input
    }
    
    func updateTargetButton()
    {
        let winningAverage: Int = HomeViewController.mySession.singleTime // for single time
        
        let target = NSLocalizedString("TARGET:  ", comment: "")
         let targetString = NSMutableAttributedString(string: "\(target)\(SolveTime.makeMyString(num: winningAverage))", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
        targetString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: target.count, length: targetString.length - target.count))
        TargetButton.setAttributedTitle(targetString, for: .normal)
    }
    
    func updateBestButtons()
    {
        updateBestSingle()
        updateBestAverage()
    }
    
    func updateBestSingle()
    {
        bestSingleAverageIndex = nil
        bestSingleSolveIndex = nil // index in average
        let allTimes = HomeViewController.mySession.allTimes
        for averageIndex in 0..<allTimes.count
        {
            let currList = allTimes[averageIndex].list
            for solveIndex in 0..<currList.count
            {
                if bestSingleSolveIndex == nil || currList[solveIndex].intTime < allTimes[bestSingleAverageIndex!].list[bestSingleSolveIndex!].intTime
                {
                    bestSingleSolveIndex = solveIndex
                    bestSingleAverageIndex = averageIndex
                }
            }
        }
        
        if bestSingleSolveIndex != nil
        {
            let minSolve = allTimes[bestSingleAverageIndex!].list[bestSingleSolveIndex!]
            var minString = minSolve.getMyString()
            let start = minString.index(minString.startIndex, offsetBy: 1)
            let end = minString.index(minString.endIndex, offsetBy: -1)
            if minString.contains("(")
            {
                minString = String(minString[start..<end])
            }
            
            
            let single = NSLocalizedString("Best single:  ", comment: "")
             let singleString = NSMutableAttributedString(string: "\(single)\(minString)", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
            singleString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.greenColor(), range: NSRange(location: single.count, length: singleString.length - single.count))
            BestSingleButton.setAttributedTitle(singleString, for: .normal)
        }
        else
        {
            BestSingleButton.setTitle("Best single:  ", for: .normal)
        }
        
        //updateBestFonts()
    }
    
    func updateBestAverage()
    {
        bestAverageIndex = nil
        let allAverages = HomeViewController.mySession.allAverages
        for currIndex in 0..<allAverages.count
        {
            if bestAverageIndex == nil || allAverages[currIndex].toFloatTime() < allAverages[bestAverageIndex!].toFloatTime()
            {
                bestAverageIndex = currIndex
            }
        }
        
        if(bestAverageIndex != nil)
        {
            let minString = allAverages[bestAverageIndex!]
            let average = NSLocalizedString("Best average:  ", comment: "")
             let averageString = NSMutableAttributedString(string: "\(average)\(minString)", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
            averageString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.greenColor(), range: NSRange(location: average.count, length: averageString.length - average.count))
            BestAverageButton.setAttributedTitle(averageString, for: .normal)
        }
        else
        {
            BestAverageButton.setTitle("Best average:  ", for: .normal)
        }
        
        //updateBestFonts()
    }
    
    override func viewWillLayoutSubviews() {
        let stringSize = ResetButton.titleLabel?.intrinsicContentSize.width
        ResetButton.widthAnchor.constraint(equalToConstant: stringSize! + 10).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateTargetButton()
        updateBestButtons()
        setUpStackView()
        updateBarWidth()
        
        DeleteButton.isEnabled = HomeViewController.allSessions.count > 1
        
        if(HomeViewController.darkMode)
        {
            makeDarkMode()
            DarkBackground.isHidden = false
            StatsTableView.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        }
        else
        {
            turnOffDarkMode()
            DarkBackground.isHidden = true
            StatsTableView.backgroundColor = UIColor.white
        }
        
        StatsTableView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        closeStack()
        
        super.viewWillDisappear(animated)
        
        
    }
    
    func closeStack()
    {
        for button in SessionStackView.subviews
        {
            if button != SessionButton
            {
                button.isHidden = true
            }
        }
    }
    
    @objc func rename(sender: UIButton) {
        
        let alertService = InputAlertService()
        let alert = alertService.alert(placeholder: "Name", keyboardType: 1, myTitle: "Rename Session",
                                       completion: {
            
            let input = alertService.myVC.TextField.text!
            let maxCharacters = 20
            
            if(input.count < maxCharacters && self.sessionNamed(title: input) == nil) // creating new session
            {
                self.replaceSession(oldName: self.SessionButton.titleLabel?.text! ?? "", newName: input)
            }
            else if input.count >= maxCharacters
            {
                self.alertInvalid(alertMessage: "Session name too long!")
            }
            else // already used name
            {
                self.alertInvalid(alertMessage: "Session name already in use!")
            }
        })
        
        self.present(alert, animated: true)
    }
    
    
    
    @IBAction func deletePressed(_ sender: Any) {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: "Delete \(HomeViewController.mySession.name) session?", completion: {
            self.deleteSession()
        })
        
        self.present(alert, animated: true)
    }
    
    func deleteSession()
    {
        let sessionName: String = (SessionButton.titleLabel?.text)!
        
        
        
        let index = HomeViewController.allSessions.firstIndex(of: self.sessionNamed(title: sessionName)!)!
        
        let removedSession: Session = HomeViewController.allSessions.remove(at: index) // remove from array
    
        try! realm.write {
            realm.delete(removedSession)
        }
        
        HomeViewController.mySession = HomeViewController.allSessions[index % HomeViewController.allSessions.count]
        hideAll()
        setUpStackView()
        updateTargetButton()
        updateBestButtons()
        StatsTableView.reloadData()
        updateBarWidth()
    }
    
    
    func replaceSession(oldName: String, newName: String)
    {
        let session = sessionNamed(title: oldName)!
        try! realm.write
        {
            session.name = newName
        }
        hideAll()
        setUpStackView()
    }
    
    func makeDarkMode()
    {
        for button in [NewButton, SessionButton, ResetButton]
        {
            button?.backgroundColor = .darkGray
        }
        
    }
    
    func turnOffDarkMode()
    {
        for button in [NewButton, SessionButton, ResetButton]
        {
            button?.backgroundColor = HomeViewController.darkBlueColor()
        }

    }
    
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentIndex = HomeViewController.mySession.currentAverage - indexPath.row // reverse order
        
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = HomeViewController.mySession.allAverages[currentIndex] // set to average
        cell.textLabel?.font = UIFont(name: "Lato-Black", size: 20)
        
        
        if(HomeViewController.darkMode)
        {
            cell.textLabel?.textColor? = UIColor.white
            cell.detailTextLabel?.textColor? = UIColor.white
            cell.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        }
        else
        {
            cell.textLabel?.textColor? = UIColor.black
            cell.detailTextLabel?.textColor? = UIColor.black
            cell.backgroundColor = UIColor.white
        }
        cell.accessoryType = .disclosureIndicator // show little arrow thing on right side of each cell
        if(HomeViewController.mySession.usingWinningTime[currentIndex]) // if was competing against winning time
        {
            cell.textLabel?.textColor = SolveTime.makeIntTime(num: HomeViewController.mySession.allAverages[currentIndex].toFloatTime())  < HomeViewController.mySession.singleTime ? HomeViewController.greenColor() : HomeViewController.redColor() // get int time
            
        }
        
        var timeList: String = ""
        
        let numSolves = HomeViewController.mySession.averageTypes[currentIndex] == 0 ? 5 : 3 // ao5 vs mo3/bo3
        for i in 0..<numSolves-1
        {
            timeList.append(HomeViewController.mySession.allTimes[currentIndex].list[i].myString)
            timeList.append(", ")
        }
        timeList.append(HomeViewController.mySession.allTimes[currentIndex].list[numSolves-1].myString)
        
        cell.detailTextLabel?.text = timeList
        cell.detailTextLabel?.font = UIFont(name: "Lato-Black", size: 14)
        
        if(indexPath.row % 2 == 1 && !HomeViewController.darkMode) // make gray for every other cell
        {
            cell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        else if(indexPath.row % 2 == 0 && HomeViewController.darkMode)
        {
            cell.backgroundColor = UIColor.darkGray
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let currentIndex = HomeViewController.mySession.currentAverage - indexPath.row // reverse order
        if editingStyle == .delete {
            deleteAveragePressed(at: currentIndex, tableView, forRowAt: indexPath)
        }
    }
    
    func deleteAveragePressed(at index: Int, _ tableView: UITableView, forRowAt indexPath: IndexPath)
    {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: "Delete \(HomeViewController.mySession.allAverages[index]) average?", completion: {
            self.deleteAverage(at: index)
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        self.present(alert, animated: true)
    }
    
    func deleteAverage(at index: Int)
    {
        let session = HomeViewController.mySession
        try! realm.write
        {
            session.allAverages.remove(at: index)
            session.averageTypes.remove(at: index)
            session.winningAverages.remove(at: index)
            session.usingWinningTime.remove(at: index)
            session.results.remove(at: index)
            session.allTimes.remove(at: index)
            session.currentAverage -= 1
        }
        updateBarWidth()
    }
    
    // average pressed
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SessionViewController.myIndex = HomeViewController.mySession.currentAverage - indexPath.row // bc reverse
        
        slideRightSegue()
    }
    
    func slideRightSegue()
    {
        let obj = (self.storyboard?.instantiateViewController(withIdentifier: "AverageDetailViewController"))!

            let transition:CATransition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = .push
            transition.subtype = .fromRight
        
        
            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
            self.navigationController?.pushViewController(obj, animated: true)
    }
    
    func updateBestFonts()
    {
        let minSingleFont =  BestSingleButton.titleLabel?.font.withSize(min(HomeViewController.fontToFitWidth(text: (BestSingleButton.titleLabel?.text!)!, view: BestSingleButton, multiplier: 0.9, name: "Lato-Black").pointSize, HomeViewController.fontToFitHeight(view: BestSingleButton, multiplier: 0.9, name: "Lato-Black").pointSize))
        
        let minAverageFont = BestAverageButton.titleLabel?.font.withSize(min(HomeViewController.fontToFitWidth(text: (BestAverageButton.titleLabel?.text!)!, view: BestAverageButton, multiplier: 0.9, name: "Lato-Black").pointSize, HomeViewController.fontToFitHeight(view: BestAverageButton, multiplier: 0.9, name: "Lato-Black").pointSize))
        
        let minFont = Float(minSingleFont!.pointSize) < Float(minAverageFont!.pointSize) ? minSingleFont : minAverageFont
        
        BestSingleButton.titleLabel?.font = minFont
        BestAverageButton.titleLabel?.font = minFont
        

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("this boi got called")
        TargetButton.titleLabel?.font = TargetButton.titleLabel?.font.withSize(min(HomeViewController.fontToFitWidth(text: (TargetButton.titleLabel?.text!)!, view: TargetButton, multiplier: 1.0, name: "Lato-Black").pointSize, HomeViewController.fontToFitHeight(view: TargetButton, multiplier: 1.0, name: "Lato-Black").pointSize))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector (rename))
        doubleTapGesture.numberOfTapsRequired = 2
        SessionButton.addGestureRecognizer(doubleTapGesture)
        
        BestSingleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        TargetButton.titleLabel?.adjustsFontSizeToFitWidth = true
        BestAverageButton.titleLabel?.adjustsFontSizeToFitWidth = true
    
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if bestSingleTransition
        {
            bestSingleTransition = false
            let path: IndexPath = IndexPath(row: HomeViewController.mySession.currentAverage - bestSingleAverageIndex!, section: 0)
            //StatsTableView.scrollToRow(at: path, at: UITableView.ScrollPosition.top, animated: true)
            StatsTableView.selectRow(at: path, animated: true, scrollPosition: UITableView.ScrollPosition.top)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.tableView(self.StatsTableView, didSelectRowAt: path)
                bestSingleTransition = true
            }
        }
        else if bestAverageTransition
        {
            bestAverageTransition = false
            let path: IndexPath = IndexPath(row: HomeViewController.mySession.currentAverage - bestAverageIndex!, section: 0)
            StatsTableView.selectRow(at: path, animated: true, scrollPosition: UITableView.ScrollPosition.top)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.tableView(self.StatsTableView, didSelectRowAt: path)
            }
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
