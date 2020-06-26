//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 6/26/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit
import Charts

class StatsViewController: UIViewController {

    @IBOutlet weak var lineChart: LineChartView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateGraph()
        
        updateLabels()
    }
    
    func updateGraph()
    {
        var lineChartEntries = [ChartDataEntry]()
        var i: Double = 1
        for averageString in HomeViewController.mySession.allAverages
        {
            if averageString != "DNF"
            {
                let average = averageString.toFloatTime()
                lineChartEntries.append(ChartDataEntry(x: i, y: Double(average)))
            }
            i += 1
        }
        
        let line = LineChartDataSet(entries: lineChartEntries, label: HomeViewController.mySession.name)
        line.colors = [NSUIColor.blue]
        line.drawCirclesEnabled = false
        
        let data = LineChartData()
        data.addDataSet(line)
        
        lineChart.data = data
        lineChart.setScaleEnabled(true)
        lineChart.noDataText = "No averages in this session yet!"
        
        
    }
    
    func updateLabels()
    {
        var minSolve: SolveTime? = nil
        for currList in HomeViewController.mySession.allTimes
        {
            let currMin: SolveTime = currList.list.min(by: {a, b in a.intTime < b.intTime})! // minimum solve of current average
            if minSolve == nil || currMin.intTime < minSolve!.intTime
            {
                minSolve = currMin
            }
        }
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
