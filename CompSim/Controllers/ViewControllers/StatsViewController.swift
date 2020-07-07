//
//  StatsViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 6/26/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit
import Charts

var bestSingleAverageIndex: Int?
var bestSingleSolveIndex: Int? // index in average
var bestSingleTransition = false

var bestAverageIndex: Int?
var bestAverageTransition = false

class StatsViewController: UIViewController {

    @IBOutlet weak var lineChart: LineChartView!
    
    @IBOutlet weak var BestSingleButton: UIButton!
    @IBOutlet weak var BestAverageButton: UIButton!
    @IBOutlet weak var MedianAverageButton: UIButton!
    @IBOutlet weak var CurrentMoButton: UIButton!
    @IBOutlet weak var BestMoButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BestSingleButton.titleLabel?.adjustsFontSizeToFitWidth = true
        MedianAverageButton.titleLabel?.adjustsFontSizeToFitWidth = true
        BestAverageButton.titleLabel?.adjustsFontSizeToFitWidth = true
        CurrentMoButton.titleLabel?.adjustsFontSizeToFitWidth = true
        BestMoButton.titleLabel?.adjustsFontSizeToFitWidth = true

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        let radius = BestMoButton.frame.height / 2.0
        BestMoButton.layer.cornerRadius = radius
        CurrentMoButton.layer.cornerRadius = radius
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("STATS VIEW WILL APPEAR")
        
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
        bestSingleAverageIndex = nil
        bestSingleSolveIndex = nil // index in average
        bestSingleTransition = false
        let allTimes = HomeViewController.mySession.allTimes
        for averageIndex in 0..<allTimes.count
        {
            let currList = allTimes[averageIndex].list
            for solveIndex in 0..<currList.count
            {
                if bestSingleSolveIndex == nil || currList[solveIndex].intTime < allTimes[bestSingleAverageIndex!].list[bestSingleSolveIndex!].intTime
                {
                    bestSingleSolveIndex = solveIndex
                    bestSingleAverageIndex = averageIndex
                }
            }
        }
        
        
        if bestSingleSolveIndex != nil
        {
            let minSolve = allTimes[bestSingleAverageIndex!].list[bestSingleSolveIndex!]
            var minString = minSolve.getMyString()
            let start = minString.index(minString.startIndex, offsetBy: 1)
            let end = minString.index(minString.endIndex, offsetBy: -1)
            if minString.contains("(")
            {
                minString = String(minString[start..<end])
            }
            
            
            let single = NSLocalizedString("Best single:  ", comment: "")
             let singleString = NSMutableAttributedString(string: "\(single)\(minString)", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
            singleString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.greenColor(), range: NSRange(location: single.count, length: singleString.length - single.count))
            BestSingleButton.setAttributedTitle(singleString, for: .normal)
        }
        else
        {
            BestSingleButton.setTitle("Best single:  ", for: .normal)
        }
    }
    
    func updateBestAverage()
    {
        bestAverageIndex = nil
        bestAverageTransition = false
        let allAverages = HomeViewController.mySession.allAverages
        for currIndex in 0..<allAverages.count
        {
            if bestAverageIndex == nil || allAverages[currIndex].toFloatTime() < allAverages[bestAverageIndex!].toFloatTime()
            {
                bestAverageIndex = currIndex
            }
        }
        
        if(bestAverageIndex != nil)
        {
            let minString = allAverages[bestAverageIndex!]
            let average = NSLocalizedString("Best average:  ", comment: "")
             let averageString = NSMutableAttributedString(string: "\(average)\(minString)", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
            averageString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.greenColor(), range: NSRange(location: average.count, length: averageString.length - average.count))
            BestAverageButton.setAttributedTitle(averageString, for: .normal)
        }
        else
        {
            BestAverageButton.setTitle("Best average:  ", for: .normal)
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
        var medianTimeString: String = ""
        if sorted.count % 2 != 0 {
            medianTimeString = sorted[sorted.count / 2]
        }
        else
        {
            let medianFloat: Float = (sorted[sorted.count / 2].toFloatTime() + sorted[sorted.count / 2 - 1].toFloatTime()) / 2.0
            let medianInt = SolveTime.makeIntTime(num: medianFloat)
            if medianInt > 99999 // DNF
            {
                medianTimeString = "DNF"
            }
            else
            {
                medianTimeString = SolveTime.makeMyString(num: medianInt)
            }
        }
        
        let median = NSLocalizedString("MEDIAN AVERAGE:  ", comment: "")
         let medianString = NSMutableAttributedString(string: "\(median)\(medianTimeString)", attributes: [NSAttributedString.Key.foregroundColor: HomeViewController.darkBlueColor()])
        medianString.addAttribute(NSAttributedString.Key.foregroundColor, value: HomeViewController.orangeColor(), range: NSRange(location: median.count, length: medianString.length - median.count))
        MedianAverageButton.setAttributedTitle(medianString, for: .normal)
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

    @IBAction func BestSingleClicked(_ sender: Any) {
        if bestSingleAverageIndex != nil
        {
            bestSingleTransition = true
            self.performSegue(withIdentifier: "SegueToSession", sender: self)
        }
    }
    
    @IBAction func BestAverageClicked(_ sender: Any) {
        if bestAverageIndex != nil
        {
            bestAverageTransition = true
            self.performSegue(withIdentifier: "SegueToSession", sender: self)
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
