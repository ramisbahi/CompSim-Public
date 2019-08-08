//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/6/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class StatsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    static var myIndex = 0 // contains index of array hit
    
    // returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return ViewController.currentAverage + 1 // returns # items
    }
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "cell")
        print(ViewController.averages[indexPath.row])
        
        cell.textLabel?.text = ViewController.averages[indexPath.row] // set to average
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        cell.accessoryType = .disclosureIndicator // show little arrow thing on right side of each cell
        if(ViewController.results[indexPath.row]) // win
        {
            cell.textLabel?.textColor = UIColor.green
        }
        else // loss
        {
            cell.textLabel?.textColor = UIColor.red
        }
        
        var timeList: String = ""
        
        
        for i in 0..<4
        { timeList.append(ViewController.allTimes[indexPath.row][i])
            timeList.append(", ")
        }
        timeList.append(ViewController.allTimes[indexPath.row][4])
        
        cell.detailTextLabel?.text = timeList
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14.0)
        
        if(indexPath.row % 2 == 1) // make gray for every other cell
        {
            cell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        StatsViewController.myIndex = indexPath.row
        performSegue(withIdentifier: "segue", sender: self)
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
