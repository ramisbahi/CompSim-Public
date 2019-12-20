//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/6/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var DarkBackground: UIImageView!
    @IBOutlet weak var StatsTitle: UILabel!
    
    @IBOutlet weak var StatsTableView: UITableView!
    
    static var myIndex = 0 // contains index of array hit
    
    // returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return ViewController.mySession.currentAverage + 1 // returns # items
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        if(ViewController.darkMode)
        {
            DarkBackground.isHidden = false
            StatsTitle.textColor = UIColor.white
            StatsTableView.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        }
        else
        {
            DarkBackground.isHidden = true
            StatsTitle.textColor = UIColor.black
            StatsTableView.backgroundColor = UIColor.white
        }
        
        StatsTableView.reloadData()
    }
    
    
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("table view")
        let currentIndex = ViewController.mySession.currentAverage - indexPath.row // reverse order
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        print(ViewController.mySession.allAverages[currentIndex])
        
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
            if(ViewController.mySession.results[currentIndex]) // win
            {
                cell.textLabel?.textColor = UIColor.green
            }
            else // loss
            {
                cell.textLabel?.textColor = UIColor.red
            }
        }
        
        var timeList: String = ""
        
        print(ViewController.mySession.allTimes)
        print(ViewController.mySession.currentIndex)
        
        if ViewController.mySession.averageTypes[currentIndex] == 0 // ao5
        {
            for i in 0..<4
            {
            timeList.append(ViewController.mySession.allTimes[currentIndex][i].myString)
                timeList.append(", ")
            }
            timeList.append(ViewController.mySession.allTimes[currentIndex][4].myString)
        }
        else // mo3 or bo3
        {
            for i in 0..<2
            {
            timeList.append(ViewController.mySession.allTimes[currentIndex][i].myString)
                timeList.append(", ")
            }
            timeList.append(ViewController.mySession.allTimes[currentIndex][2].myString)
        }
        
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StatsViewController.myIndex = ViewController.mySession.currentAverage - indexPath.row // bc reverse
        performSegue(withIdentifier: "segue", sender: self)
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
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
