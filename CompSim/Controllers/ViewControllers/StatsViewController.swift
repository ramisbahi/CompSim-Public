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
    @IBOutlet weak var StatsTitle: UILabel!
    
    @IBOutlet weak var StatsTableView: UITableView!
    
    @IBOutlet weak var NewButton: UIButton!
    @IBOutlet weak var SessionButton: UIButton!
    
    var SessionCollection: [UIButton] = []
    
    static var myIndex = 0 // contains index of array hit
    
    @IBOutlet var SessionStackView: UIStackView!
    
    @IBOutlet weak var DeleteButton: UIButton!
    
    let realm = try! Realm()
    
    @IBAction func newSession(_ sender: Any) {
        let alert = UIAlertController(title: "New Session", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Name"
            textField.autocapitalizationType = .words
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        }
        )
        
        let enterAction = UIAlertAction(title: "Enter", style: .default, handler: {
            
            // Everything in here is executed when a time is entered
            
            [weak alert] (_) in
            
            let textField = alert!.textFields![0] // your time
            let input = textField.text!
            
            let maxCharacters = 20
            
            if(input.count < maxCharacters && ViewController.allSessions[input] == nil) // creating new session
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
            
        }
        )
        
        alert.addAction(cancelAction)
        alert.addAction(enterAction)
        alert.preferredAction = enterAction
        
        self.present(alert, animated: true)
    }
    
    func createNewSession(name: String)
    {
        print("creating new session...")
        let newSession = Session(name: name, enteredEvent: 1)
        
        
        try! realm.write {
            realm.add(newSession)
            smartEvent(name: newSession.name, session: newSession)
        }
        
        ViewController.mySession = newSession // now current session
        ViewController.allSessions[name] = newSession // map with name
        self.updateNewSessionStackView()
        StatsTableView.reloadData()
        ViewController.sessionChanged = true
    }
    
    func smartEvent(name: String, session: Session)
    {
        switch name.lowercased()
        {
        case "2x2x2", "2x2":
            session.doEvent(enteredEvent: 0)
        case "3x3x3", "3x3":
            session.doEvent(enteredEvent: 1)
        case "4x4x4", "4x4":
            session.doEvent(enteredEvent: 2)
        case "5x5x5", "5x5":
            session.doEvent(enteredEvent: 3)
        case "6x6x6", "6x6":
            session.doEvent(enteredEvent: 4)
        case "7x7x7", "7x7":
            session.doEvent(enteredEvent: 5)
        case "pyra", "pyraminx":
            session.doEvent(enteredEvent: 6)
        case "mega", "megaminx":
            session.doEvent(enteredEvent: 7)
        case "sq-1", "sq1", "square1", "square-1":
            session.doEvent(enteredEvent: 8)
        case "skewb", "skoob":
            session.doEvent(enteredEvent: 9)
        case "clock":
            session.doEvent(enteredEvent: 10)
        default:
            break
        }
    }
    
    func updateNewSessionStackView()
    {
        hideAll()
        DeleteButton.isEnabled = ViewController.allSessions.count > 1
        SessionButton.setTitle(ViewController.mySession.name, for: .normal)
        let newButton = createButton(name: ViewController.mySession.name)
        SessionCollection.append(newButton)
        SessionStackView.addArrangedSubview(newButton)
        
    }
    
    // called whenever something changed with sessions
    func setUpStackView()
    {
        DeleteButton.isEnabled = ViewController.allSessions.count > 1
        SessionButton.setTitle(ViewController.mySession.name, for: .normal)
        SessionCollection = []
        for (sessionName, _) in ViewController.allSessions
        {
            if(ViewController.allSessions[sessionName] != nil)
            {
                let newButton = createButton(name: sessionName)
                SessionCollection.append(newButton)
                SessionStackView.addArrangedSubview(newButton)
            }
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
        retButton.layer.cornerRadius = 20
        retButton.isUserInteractionEnabled = true
        retButton.addTarget(self, action: #selector(SessionSelected(_:)), for: UIControl.Event.touchUpInside)
        return retButton
    }
    
    func alertInvalid(alertMessage: String)
    {
        let alert = UIAlertController(title: alertMessage, message: "", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
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
    
    @objc @IBAction func SessionSelected(_ sender: UIButton) {
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
        if ViewController.allSessions[title] != nil && title != ViewController.mySession.name // exists, not same
        {
            ViewController.mySession = ViewController.allSessions[title]!
            ViewController.mySession.updateScrambler()
            ViewController.sessionChanged = true
            StatsTableView.reloadData()
            print("changed session successfully")
        }
        
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        
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
        
        let alert = UIAlertController(title: "Rename Session", message: "", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Name"
            textField.autocapitalizationType = .words
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (action : UIAlertAction!) -> Void in
        }
        )
        
        let enterAction = UIAlertAction(title: "Enter", style: .default, handler: {
            
            // Everything in here is executed when a time is entered
            
            [weak alert] (_) in
            
            let textField = alert!.textFields![0] // your time
            let input = textField.text!
            
            let maxCharacters = 20
            
            if(input.count < maxCharacters && ViewController.allSessions[input] == nil) // creating new session
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
            
        }
        )
        
        alert.addAction(cancelAction)
        alert.addAction(enterAction)
        alert.preferredAction = enterAction
        
        self.present(alert, animated: true)
    }
    
    
    
    @IBAction func deletePressed(_ sender: Any) {
        
        let alert = UIAlertController(title: "Delete \(ViewController.mySession.name) session?", message: "", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .default, handler: {
            (_) in
            // Confirming deleted solve
            self.deleteSession()
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (_) in
            
        })
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        
        self.present(alert, animated: true)
    }
    
    func deleteSession()
    {
        let sessionName: String = (SessionButton.titleLabel?.text)!
        
        try! realm.write {
            realm.delete(ViewController.allSessions[sessionName]!)
        }
        ViewController.allSessions[sessionName] = nil // map with name
        var iterator = ViewController.allSessions.values.makeIterator()
        ViewController.mySession = iterator.next()!
        hideAll()
        setUpStackView()
        StatsTableView.reloadData()
    }
    
    
    func replaceSession(oldName: String, newName: String)
    {
        print("replacing session...")
        let session = ViewController.allSessions[oldName]
        try! realm.write
        {
            session?.name = newName
        }
        ViewController.allSessions[oldName] = nil // map with name
        ViewController.allSessions[newName] = session
        hideAll()
        setUpStackView()
    }
    
    func makeDarkMode()
    {
        for button in [NewButton, SessionButton, DeleteButton]
        {
            button?.backgroundColor = .darkGray
        }
    }
    
    func turnOffDarkMode()
    {
        for button in [NewButton, SessionButton, DeleteButton]
        {
            button?.backgroundColor = ViewController.darkBlueColor()
        }
    }
    
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("table view")
        let currentIndex = ViewController.mySession.currentAverage - indexPath.row // reverse order
        
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        
        cell.textLabel?.text = ViewController.mySession.allAverages[currentIndex] // set to average
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        
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
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14.0)
        
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
        let alert = UIAlertController(title: "Delete \(ViewController.mySession.allAverages[index]) average?", message: "", preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "Yes", style: .default, handler: {
            (_) in
            // Confirming deleted solve
            self.deleteAverage(at: index)
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: {
            (_) in
        })
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        alert.preferredAction = confirmAction
        
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
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StatsViewController.myIndex = ViewController.mySession.currentAverage - indexPath.row // bc reverse
        
        slideRightSegue()
    }
    
    func slideRightSegue()
    {
        let obj = (self.storyboard?.instantiateViewController(identifier: "AverageDetailViewController"))!

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

        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector (rename))
        doubleTapGesture.numberOfTapsRequired = 2
        SessionButton.addGestureRecognizer(doubleTapGesture)
        
        
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
