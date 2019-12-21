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
    @IBOutlet weak var WinningAverageLabel: UILabel!
    
    var averageType = 0
    
    @IBAction func StatsButtonPressed(_ sender: Any) {
        AverageDetailViewController.justReturned = true
        performSegue(withIdentifier: "returnToStats", sender: self)
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
        
        myCell.textLabel?.text = ViewController.mySession.allTimes[StatsViewController.myIndex][indexPath.row].myString // each time
        myCell.textLabel?.font = UIFont.boldSystemFont(ofSize: 20.0)
        
        myCell.detailTextLabel?.text = ViewController.mySession.scrambler.scrambles[StatsViewController.myIndex*5 + indexPath.row] // each scramble
        myCell.detailTextLabel?.font = UIFont.systemFont(ofSize: 14.0)
        
        if(ViewController.darkMode)
        {
            myCell.backgroundColor = UIColor(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
            myCell.textLabel?.textColor = .white
            myCell.detailTextLabel?.textColor = .white
        }
        if(indexPath.row % 2 == 1 && !ViewController.darkMode) // make gray for every other cell
        {
            myCell.backgroundColor = UIColor(displayP3Red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
        }
        else if(indexPath.row % 2 == 0 && ViewController.darkMode)
        {
            myCell.backgroundColor = .darkGray
        }
        
        return myCell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let time = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let scramble = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text
        let alert = UIAlertController(title: time, message: scramble, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(true)
        averageType = ViewController.mySession.averageTypes[StatsViewController.myIndex] // set average type (0 = ao5, 1 = mo3, 2 = bo3)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(averageType == 0)
        {
            AverageLabel.text = ViewController.mySession.allAverages[StatsViewController.myIndex] + " Average"
        }
        else if(averageType == 1)
        {
            AverageLabel.text = ViewController.mySession.allAverages[StatsViewController.myIndex] + " Mean"
        }
        
        if(ViewController.darkMode)
        {
            makeDarkMode()
        }
        else
        {
            turnOffDarkMode()
        }
        
        if(ViewController.mySession.usingWinningTime[StatsViewController.myIndex]) // was going against a winning time
        {
            if(ViewController.mySession.results[StatsViewController.myIndex]) // won
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
        
        if(averageType == 0)
        {
            WinningAverageLabel.text = "Target: " +  ViewController.mySession.winningAverages[StatsViewController.myIndex] + " Average"
        }
        if(averageType == 1)
        {
            WinningAverageLabel.text = "Target: " +  ViewController.mySession.winningAverages[StatsViewController.myIndex] + " Mean"
        }
    
        // Do any additional setup after loading the view.
    }
    
    func makeDarkMode()
    {
        DarkBackground.isHidden = false
        WinningAverageLabel.textColor? = UIColor.white
        AverageLabel.textColor? = UIColor.white // may be changed to red/green afterwards - just changing default
        AverageTableView.backgroundColor = UIColor.init(displayP3Red: 29/255, green: 29/255, blue: 29/255, alpha: 1.0)
        
    }
    
    func turnOffDarkMode()
    {
        DarkBackground.isHidden = true
        WinningAverageLabel.textColor? = UIColor.black
        AverageLabel.textColor? = UIColor.black // may be changed to red/green afterwards - just changing default
        AverageTableView.backgroundColor = UIColor.white
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
