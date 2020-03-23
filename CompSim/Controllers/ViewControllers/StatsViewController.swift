//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/6/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var DarkBackground: UIImageView!
    
    @IBOutlet weak var StatsTableView: UITableView!
    
    @IBOutlet weak var NewButton: UIButton!
    @IBOutlet weak var SessionButton: UIButton!
    
    var SessionCollection: [UIButton] = []
    
    static var myIndex = 0 // contains index of array hit
    
    @IBOutlet var SessionStackView: UIStackView!
    
    @IBOutlet weak var ResetButton: UIButton!
    @IBOutlet weak var DeleteButton: UIButton!
    
    
    @IBOutlet weak var BackgroundBar: UIView!
    @IBOutlet weak var WinningWidth: NSLayoutConstraint!
    @IBOutlet weak var LosingWidth: NSLayoutConstraint!
    @IBOutlet var BigView: UIView!
    
    let realm = try! Realm()
    
    @IBAction func newSession(_ sender: Any) {
        
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Name", usingPenalty: false, keyboardType: 1, myTitle: "New Session",
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
        let alert = alertService.alert(myTitle: "Reset \(ViewController.mySession.name) session?", completion: {
            self.resetSession()
        })
        
        self.present(alert, animated: true)
    }
    
    func updateBarWidth()
    {
        let view = BigView // change
        
        let numAverages = ViewController.mySession.results.count
        var losingCount = 0
        var winningCount = 0
        
        if(numAverages > 0)
        {
            for index in 0..<numAverages
            {
                if(ViewController.mySession.usingWinningTime[index]) // if was competing against winning time
                {
                    if ViewController.mySession.results[index] // win
                    {
                        winningCount += 1
                    }
                    else // lose
                    {
                        losingCount += 1
                    }
                }
            }
            
            WinningWidth.constant = view!.frame.size.width * CGFloat(winningCount) / CGFloat(numAverages)
            LosingWidth.constant = view!.frame.size.width * CGFloat(losingCount) / CGFloat(numAverages)
        }
        else
        {
            WinningWidth.constant = 0
            LosingWidth.constant = 0
        }
    }
    
    func resetSession()
    {
        let session = ViewController.mySession
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
        ViewController.sessionChanged = true
        StatsTableView.reloadData()
        updateBarWidth()
    }
    
    func createNewSession(name: String)
    {
        print("creating new session...")
        let newSession = Session(name: name, enteredEvent: 1)
        
        ViewController.mySession = newSession // now current session
        ViewController.allSessions.append(newSession)
//        ViewController.allSessions[name] = newSession // map with name
        
        try! realm.write {
            realm.add(newSession)
            smartEvent(name: newSession.name, session: newSession)
        }
        
        self.updateNewSessionStackView()
        StatsTableView.reloadData()
        ViewController.sessionChanged = true
        updateBarWidth()
    }
    
    func updateNewSessionStackView()
    {
        hideAll()
        DeleteButton.isEnabled = ViewController.allSessions.count > 1
        SessionButton.setTitle(ViewController.mySession.name, for: .normal)
        let newButton = createButton(name: ViewController.mySession.name)
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
        ViewController.mySession.solveType = 0
    }
    
    func doMean()
    {
        ViewController.mySession.solveType = 1
    }
    
    
    
    // called whenever something changed with sessions
    func setUpStackView()
    {
        DeleteButton.isEnabled = ViewController.allSessions.count > 1
        SessionButton.setTitle(ViewController.mySession.name, for: .normal)
        SessionCollection = []
        for session in ViewController.allSessions
        {
            let newButton = createButton(name: session.name)
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
        let retButton = UIButton(type: .system)
        retButton.setTitle(name, for: .normal)
        retButton.isHidden = true
        retButton.setTitleColor(.white, for: .normal)
        retButton.titleLabel?.font = UIFont(name: "Futura", size: 17)
        retButton.backgroundColor = ViewController.orangeColor()
        retButton.layer.cornerRadius = 18
        retButton.isUserInteractionEnabled = true
        retButton.addTarget(self, action: #selector(SessionSelected(_:)), for: UIControl.Event.touchUpInside)
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
        return ViewController.mySession.currentAverage + 1 // returns # items
    }
    
    @IBAction func SessionButtonClicked(_ sender: Any) {
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        print(SessionCollection[0])
    }
    
    @objc func SessionSelected(_ sender: UIButton) {
        SessionCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle else
        {
            return // doesn't have title
        }
        
        print(title)
        SessionButton.setTitle(title, for: .normal)
        if title != ViewController.mySession.name // exists,// not same - so switch session
        {
            ViewController.mySession = sessionNamed(title: title)!
            ViewController.mySession.updateScrambler()
            ViewController.sessionChanged = true
            StatsTableView.reloadData()
            updateBarWidth()
            print("changed session successfully")
        }
        
    }
    
    func sessionNamed(title: String) -> Session?
    {
        for session in ViewController.allSessions
        {
            if session.name == title
            {
                return session
            }
        }
        return nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        
        
        print("in this")
        DeleteButton.isEnabled = ViewController.allSessions.count > 1
        
        if(ViewController.darkMode)
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
    
    @objc func rename(sender: UIButton) {
        
        let alertService = AlertService()
        let alert = alertService.alert(placeholder: "Name", usingPenalty: false, keyboardType: 1, myTitle: "Rename Session",
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
        let alert = alertService.alert(myTitle: "Delete \(ViewController.mySession.name) session?", completion: {
            self.deleteSession()
        })
        
        self.present(alert, animated: true)
    }
    
    func deleteSession()
    {
        let sessionName: String = (SessionButton.titleLabel?.text)!
        
        
        
        let index = ViewController.allSessions.firstIndex(of: self.sessionNamed(title: sessionName)!)!
        
        let removedSession: Session = ViewController.allSessions.remove(at: index) // remove from array
    
        try! realm.write {
            realm.delete(removedSession)
        }
        
        ViewController.mySession = ViewController.allSessions[index % ViewController.allSessions.count]
        hideAll()
        setUpStackView()
        StatsTableView.reloadData()
        updateBarWidth()
    }
    
    
    func replaceSession(oldName: String, newName: String)
    {
        print("replacing session...")
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
        
        BackgroundBar.backgroundColor = .white
    }
    
    func turnOffDarkMode()
    {
        for button in [NewButton, SessionButton, ResetButton]
        {
            button?.backgroundColor = ViewController.darkBlueColor()
        }
        
        BackgroundBar.backgroundColor = .black
    }
    
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("table view")
        let currentIndex = ViewController.mySession.currentAverage - indexPath.row // reverse order
        
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = ViewController.mySession.allAverages[currentIndex] // set to average
        cell.textLabel?.font = UIFont(name: "Futura", size: 20)
        
        
        if(ViewController.darkMode)
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
        if(ViewController.mySession.usingWinningTime[currentIndex]) // if was competing against winning time
        {
            cell.textLabel?.textColor = ViewController.mySession.results[currentIndex] ? ViewController.greenColor() : UIColor.red
            
        }
        
        var timeList: String = ""
        
        let numSolves = ViewController.mySession.averageTypes[currentIndex] == 0 ? 5 : 3 // ao5 vs mo3/bo3
        for i in 0..<numSolves-1
        {
            print(ViewController.mySession.allTimes[currentIndex].list[i])
            print(ViewController.mySession.allTimes[currentIndex].list[i].myString)
            timeList.append(ViewController.mySession.allTimes[currentIndex].list[i].myString)
            timeList.append(", ")
        }
        timeList.append(ViewController.mySession.allTimes[currentIndex].list[numSolves-1].myString)
        
        cell.detailTextLabel?.text = timeList
        cell.detailTextLabel?.font = UIFont(name: "Futura", size: 14)
        
        if(indexPath.row % 2 == 1 && !ViewController.darkMode) // make gray for every other cell
        {
            cell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        else if(indexPath.row % 2 == 0 && ViewController.darkMode)
        {
            cell.backgroundColor = UIColor.darkGray
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let currentIndex = ViewController.mySession.currentAverage - indexPath.row // reverse order
        print("currentIndex: \(currentIndex)")
        if editingStyle == .delete {
            deleteAveragePressed(at: currentIndex, tableView, forRowAt: indexPath)
        }
    }
    
    func deleteAveragePressed(at index: Int, _ tableView: UITableView, forRowAt indexPath: IndexPath)
    {
        let alertService = SimpleAlertService()
        let alert = alertService.alert(myTitle: "Delete \(ViewController.mySession.allAverages[index]) average?", completion: {
            self.deleteAverage(at: index)
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        self.present(alert, animated: true)
    }
    
    func deleteAverage(at index: Int)
    {
        let session = ViewController.mySession
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
        StatsViewController.myIndex = ViewController.mySession.currentAverage - indexPath.row // bc reverse
        
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
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(true, animated: true)

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector (rename))
        doubleTapGesture.numberOfTapsRequired = 2
        SessionButton.addGestureRecognizer(doubleTapGesture)
        
        updateBarWidth()
        
        
        setUpStackView()
        
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
