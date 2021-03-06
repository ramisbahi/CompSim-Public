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
    
    var cellHeight: CGFloat?
    
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
        myCell.textLabel?.font = HomeViewController.fontToFitHeight(view: UIView(frame: CGRect(x: 0, y: 0, width: 1, height: cellHeight!)), multiplier: 0.35, name: "Lato-Black")
        
        myCell.detailTextLabel?.text = currentTime.myScramble // each scramble
        myCell.detailTextLabel?.font = HomeViewController.fontToFitHeight(view: UIView(frame: CGRect(x: 0, y: 0, width: 1, height: cellHeight!)), multiplier: 0.2, name: "Lato-Regular")
        
        if(HomeViewController.darkMode)
        {
            myCell.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
            myCell.textLabel?.textColor = .white
            myCell.detailTextLabel?.textColor = .white
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight!
    }
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(UIResponderStandardEditActions.copy(_:))
    }
    
    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?)
    {
        UIPasteboard.general.string = clipboardSingleString(tableView: tableView, indexPath: indexPath)
    }
    
    func clipboardSingleString(tableView: UITableView, indexPath: IndexPath) -> String
    {
        let myTitle: String = (tableView.cellForRow(at: indexPath)?.textLabel?.text)!
        let myScramble: String = (tableView.cellForRow(at: indexPath)?.detailTextLabel?.text)!
        return "\(myTitle) \(myScramble)"
    }
    
    
    @IBAction func CopyButtonPressed(_ sender: Any) {
        if #available(iOS 13.0, *) {
            CopyButton.setTitleColor(HomeViewController.greenColor(), for: .normal)
            CopyButton.tintColor = HomeViewController.greenColor()
            CopyButton.setImage(UIImage(systemName: "checkmark.circle"), for: .normal)
            CopyButton.setTitle(NSLocalizedString("COPIED", comment: ""), for: .normal)
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
            
            ret += "\(i+1). \(currentTime.myString) \(currentTime.myScramble)\n"
        }
        
        return ret
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        
        
        
        if(HomeViewController.darkMode)
        {
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
        if(SolveTime.makeIntTime(num: HomeViewController.mySession.allAverages[SessionViewController.myIndex].toFloatTime()) < HomeViewController.mySession.singleTime) // win
        {
            AverageLabel.textColor = HomeViewController.greenColor()
        }
        else // lose
        {
            AverageLabel.textColor = HomeViewController.redColor()
        }
    }
    
    override func viewDidLayoutSubviews() {
        CopyButton.titleLabel?.font = HomeViewController.fontToFitWidth(text: NSLocalizedString("COPIED", comment: ""), view: CopyButton, multiplier: 0.6, name: "Lato-Black")
        if #available(iOS 13.0, *) {
            
            CopyButton.setPreferredSymbolConfiguration(UIImage.SymbolConfiguration(font: (CopyButton.titleLabel?.font)!), forImageIn: .normal)
        } else {
            // Fallback on earlier versions
        }
        AverageLabel.font = HomeViewController.fontToFitHeight(view: AverageLabel, multiplier: 0.98, name: "Lato-Black")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        cellHeight = max(self.view.frame.height * 0.1, 70.0)
        
        CopyButton.setTitle(NSLocalizedString("COPY", comment: ""), for: .normal)
        
        
        
    
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        
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
        
        
        
        let widthFont = HomeViewController.fontToFitWidth(text: AverageLabel.text!, view: AverageLabel, multiplier: 0.8, name: "Lato-Black")
        if widthFont.pointSize < AverageLabel.font.pointSize
        {
            AverageLabel.font = widthFont
        }
        
    
        // Do any additional setup after loading the view.
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        CopyButton.tintColor? = .white
        CopyButton.setTitleColor(.white, for: .normal)
        AverageLabel.textColor? = UIColor.white // may be changed to red/green afterwards - just changing default
        AverageTableView.backgroundColor = UIColor.init(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        BackButton.backgroundColor = HomeViewController.darkPurpleColor()
        self.tabBarController?.tabBar.barTintColor = HomeViewController.darkPurpleColor()
    }
    
    func turnOffDarkMode()
    {
        CopyButton.tintColor? = HomeViewController.darkBlueColor()
        CopyButton.setTitleColor(HomeViewController.darkBlueColor()
            , for: .normal)
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
