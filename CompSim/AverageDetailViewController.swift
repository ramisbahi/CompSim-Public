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
    
    @IBOutlet weak var AverageLabel: UILabel!
    @IBOutlet weak var WinningAverageLabel: UILabel!
    
    @IBAction func StatsButtonPressed(_ sender: Any) {
        AverageDetailViewController.justReturned = true
        performSegue(withIdentifier: "returnToStats", sender: self)
    }
    
    // returns number of rows
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 5
    }
    
    // performed for each cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let myCell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: "myCell")
        
        myCell.textLabel?.text = ViewController.allTimes[StatsViewController.myIndex][indexPath.row] // each time
        myCell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        myCell.detailTextLabel?.text = ViewController.scrambler.scrambles[StatsViewController.myIndex*5 + indexPath.row] // each scramble
        myCell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14.0)
        
        if(indexPath.row % 2 == 1) // make gray for every other cell
        {
            myCell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        
        return myCell
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        
        AverageLabel.text = ViewController.averages[StatsViewController.myIndex] + " Average"
    
        if(ViewController.usingWinningTime[StatsViewController.myIndex]) // was going against a winning time
        {
            if(ViewController.results[StatsViewController.myIndex]) // won
            {
                AverageLabel.textColor = UIColor.green
            }
            else // ost
            {
                AverageLabel.textColor = UIColor.red
            }
        }
        else // wasn't
        {
            WinningAverageLabel.isHidden = true
        }
        
        WinningAverageLabel.text = "Winning Average: " +  ViewController.winningAverages[StatsViewController.myIndex] + " Average"
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
