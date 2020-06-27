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
    
    @IBOutlet weak var BestSingleButton: UIButton!
    @IBOutlet weak var BestAverageButton: UIButton!
    @IBOutlet weak var MedianAverageButton: UIButton!
    @IBOutlet weak var CurrentMoButton: UIButton!
    @IBOutlet weak var BestMoButton: UIButton!
    
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
        updateBestSingle()
        updateBestAverage()
        updateMedianAverage()
        updateMo()
    }
    
    func updateBestSingle()
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
        
        if minSolve != nil
        {
            let minString = minSolve!.getMyString()
            let start = minString.index(minString.startIndex, offsetBy: 1)
            let end = minString.index(minString.endIndex, offsetBy: -1)
            let minSub = minString[start..<end]
            BestSingleButton.setTitle(String(minSub), for: .normal)
        }
    }
    
    func updateBestAverage()
    {
        let minAverage: String? =
        HomeViewController.mySession.allAverages.min(by: {
            a, b in
            a.toFloatTime() < b.toFloatTime()
        })
        
        if minAverage != nil
        {
            BestAverageButton.setTitle(minAverage!, for: .normal)
        }
    }
    
    func updateMedianAverage()
    {
        let sorted: [String] = HomeViewController.mySession.allAverages.sorted(by: {
            a, b in
            
            a.toFloatTime() < b.toFloatTime()
        })
        if sorted.count == 0
        {
            return
        }
        var median: String = ""
        if sorted.count % 2 != 0 {
            median = sorted[sorted.count / 2]
        }
        else
        {
            let medianFloat: Float = (sorted[sorted.count / 2].toFloatTime() + sorted[sorted.count / 2 - 1].toFloatTime()) / 2.0
            let medianInt = SolveTime.makeIntTime(num: medianFloat)
            if medianInt > 99999 // DNF
            {
                median = "DNF"
            }
            else
            {
                median = SolveTime.makeMyString(num: medianInt)
            }
        }
        MedianAverageButton.setTitle(median, for: .normal)
    }
    
    func updateMo()
    {
        let averages = HomeViewController.mySession.allAverages
        
        if averages.count >= 10
        {
            var bestMo: Float = 9999999.0
            
            var sum: Float = 0
            
            for i in 0..<10 // add first 10
            {
                sum += averages[i].toFloatTime()
            }
            
            if sum / 10.0 < bestMo
            {
                bestMo = sum / 10.0
            }
            
            for i in 10..<averages.count
            {
                sum -= averages[i - 10].toFloatTime()
                sum += averages[i].toFloatTime()
                
                if sum / 10.0 < bestMo
                {
                    bestMo = sum / 10.0
                }
            }
            
            // best mo10ao5s
            let bestMoInt = SolveTime.makeIntTime(num: bestMo)
            var bestMoString = "DNF"
            if bestMoInt <= 99999
            {
                bestMoString = SolveTime.makeMyString(num: bestMoInt)
            }
            BestMoButton.setTitle(bestMoString, for: .normal)
            
            // current mo10ao5s
            let currMoInt = SolveTime.makeIntTime(num: sum / 10.0)
            var currMoString = "DNF"
            if currMoInt <= 99999
            {
                currMoString = SolveTime.makeMyString(num: currMoInt)
            }
            CurrentMoButton.setTitle(currMoString, for: .normal)
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
