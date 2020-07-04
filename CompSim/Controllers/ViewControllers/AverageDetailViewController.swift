//
//  AverageDetailViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/6/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class AverageDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    static var justReturned: Bool = false // don't do any viewdidload stuff if just returned, also  make tab bar controller on stats
    
    @IBOutlet weak var DarkBackground: UIImageView!
    
    @IBOutlet weak var AverageTableView: UITableView!
    @IBOutlet weak var AverageLabel: UILabel!
    @IBOutlet weak var CopyButton: UIButton!
    
    @IBOutlet weak var BackButton: UIButton!
    
    var averageType = 0
    
    @IBAction func StatsButtonPressed(_ sender: Any) {
        AverageDetailViewController.justReturned = true
        slideLeftSegue()
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        if(bestSingleTransition)
        {
            bestSingleTransition = false
            let path: IndexPath = IndexPath(row: bestSingleSolveIndex!, section: 0)
            //StatsTableView.scrollToRow(at: path, at: UITableView.ScrollPosition.top, animated: true)
            AverageTableView.selectRow(at: path, animated: true, scrollPosition: UITableView.ScrollPosition.none)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.tableView(self.AverageTableView, didSelectRowAt: path)
            }
        }
    }
    
    func slideLeftSegue()
    {
        let transition:CATransition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
    
    
        self.navigationController!.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.popViewController(animated: true)
    }
    
    // returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if(averageType == 0) // ao5
        {
            return 5
        }
        return 3 // otherwise - mo3 / bo3
    }
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "myCell")
        
        let currentTime = HomeViewController.mySession.allTimes[SessionViewController.myIndex].list[indexPath.row]
        
        myCell.textLabel?.text = currentTime.myString // each time
        myCell.textLabel?.font = UIFont.init(name: "Futura", size: 17.0)
        
        myCell.detailTextLabel?.text = currentTime.myScramble // each scramble
        myCell.detailTextLabel?.font = UIFont.systemFont(ofSize: 12.0)
        
        if(HomeViewController.darkMode)
        {
            myCell.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
            myCell.textLabel?.textColor = .white
            myCell.detailTextLabel?.textColor = .white
        }
        if(indexPath.row % 2 == 1 && !HomeViewController.darkMode) // make gray for every other cell
        {
            myCell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        else if(indexPath.row % 2 == 0 && HomeViewController.darkMode)
        {
            myCell.backgroundColor = .darkGray
        }
        
        return myCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.cellForRow(at: indexPath)?.isSelected = false
        
        let myTitle = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let myScramble = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
        
        let alertService = ViewSolveAlertService()
        let alert = alertService.alert(usingPenalty: false, delete: false, title: myTitle!, scramble: myScramble!, penalty: 0, completion:
        {})
        
        self.present(alert, animated: true)
    }
    
    @IBAction func CopyButtonPressed(_ sender: Any) {
        if #available(iOS 13.0, *) {
            CopyButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
        }
        
        UIPasteboard.general.string = clipboardAverageString()
    }
    
    func clipboardAverageString() -> String
    {
        let currentDate = Date()
        // US English Locale (en_US)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale.current
        let formattedDate = dateFormatter.string(from: currentDate)
        
        let solveTypes = ["Average of 5", "Mean of 3", "Best of 3"]
        let solveType = solveTypes[HomeViewController.mySession.averageTypes[SessionViewController.myIndex]]
        
        var ret = "Generated by CompSim on \(formattedDate)\n"
        ret += "\(HomeViewController.mySession.allAverages[SessionViewController.myIndex]) \(solveType)\n\n"
        
        
        
        for i in 0..<5
        {
            let currentTime = HomeViewController.mySession.allTimes[SessionViewController.myIndex].list[i]
            
            ret += "\(i+1). \(currentTime.myString)\t\(currentTime.myScramble)\n"
        }
        
        return ret
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        BackButton.titleLabel?.font = HomeViewController.fontToFitHeight(view: self.view, multiplier: 0.04, name: "Futura")
        let stringSize = BackButton.titleLabel?.intrinsicContentSize.width
        BackButton.widthAnchor.constraint(equalToConstant: stringSize! + 40).isActive = true
        
        averageType = HomeViewController.mySession.averageTypes[SessionViewController.myIndex] // set average type (0 = ao5, 1 = mo3, 2 = bo3)
        if(averageType == 0)
        {
            AverageLabel.text = HomeViewController.mySession.allAverages[SessionViewController.myIndex] + " " + NSLocalizedString("Average", comment: "")
        }
        else if(averageType == 1)
        {
            AverageLabel.text = HomeViewController.mySession.allAverages[SessionViewController.myIndex] + " " + NSLocalizedString("Mean", comment: "")
        }
        else
        {
            AverageLabel.text = HomeViewController.mySession.allAverages[SessionViewController.myIndex] + " Single"
        }
        
        if(HomeViewController.darkMode)
        {
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
        if(HomeViewController.mySession.usingWinningTime[SessionViewController.myIndex]) // was going against a winning time
        {
            if(HomeViewController.mySession.results[SessionViewController.myIndex]) // won
            {
                AverageLabel.textColor = HomeViewController.greenColor()
            }
            else // ost
            {
                AverageLabel.textColor = UIColor.red
            }
        }
        
        
    
        // Do any additional setup after loading the view.
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        CopyButton.tintColor? = .white
        AverageLabel.textColor? = UIColor.white // may be changed to red/green afterwards - just changing default
        AverageTableView.backgroundColor = UIColor.init(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        BackButton.backgroundColor = .darkGray
    }
    
    func turnOffDarkMode()
    {
        CopyButton.tintColor? = HomeViewController.darkBlueColor()
        DarkBackground.isHidden = true
        AverageLabel.textColor? = UIColor.black // may be changed to red/green afterwards - just changing default
        AverageTableView.backgroundColor = UIColor.white
        BackButton.backgroundColor = HomeViewController.darkBlueColor()
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
