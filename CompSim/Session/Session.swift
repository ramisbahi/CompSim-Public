//
//  Session.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/10/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation

class Session
{
    var roundNumber = 1
    var currentIndex = 0
    
    var name: String
    
    var minTime = 100 // distributiona
    var maxTime = 200 // distribution
    
    var minIndex = 0
    var maxIndex = 1
    
    var times = [SolveTime]() // current times
    
    var myAverage: String = ""
    var myAverageInt: Int = 0
    
    var allAverages: [String] = [] // average strings stored here
    var averageTypes: [Int] = [] // 0 = avg5, 1 = mo3, 2 = bo3
    var winningAverages: [String] = []
    var usingWinningTime: [Bool] = [] // for each round, whether or not using winning time
    var allTimes: [[SolveTime]] = []
    var currentAverage: Int = -1 // keeps track of last average currently on (round - 2)
    var results: [Bool] = []
    let scrambler = ScrambleReader()
    
    init(name: String)
    {
        self.name = name
    }
    
    func reset()
    {
        currentIndex = 0
        times = []
        minIndex = 0
        maxIndex = 1
        myAverage = ""
    }
    
    func deleteSolve()
    {
        times.removeLast()
        currentIndex -= 1
        updateTimes()
    }
    
    func addSolve(time: String)
    {
        let myTime = SolveTime(enteredTime: time)
        times.append(myTime)
        currentIndex += 1
        updateTimes()
    }
    
    func addSolve(time: String, penalty: Int)
    {
        let myTime = SolveTime(enteredTime: time)
        if(penalty == 1)
        {
            myTime.setPlusTwo()
        }
        else if(penalty == 2)
        {
            myTime.setDNF()
        }
        times.append(myTime)
        currentIndex += 1
        updateTimes()
    }
    
    func changePenaltyStatus(index: Int, penalty: Int)
    {
        if(penalty == 0)
        {
            times[index].setNoPenalty()
        }
        else if(penalty == 1)
        {
            times[index].setPlusTwo()
        }
        else
        {
            times[index].setDNF()
        }
        updateTimes()
    }
    
    func updateTimes()
    {
        var total = 0
        if(currentIndex >= 3 && ViewController.ao5)
        {
            for i in 0..<currentIndex
            {
                if(times[i].intTime < times[minIndex].intTime)
                {
                    minIndex = i
                }
                else if(times[i].intTime > times[maxIndex].intTime)
                {
                    maxIndex = i
                }
            }
            
            for i in 0..<currentIndex
            {
                if(i == minIndex || i == maxIndex)
                {
                    times[i].updateString(minMax: true)
                }
                else
                {
                    times[i].updateString(minMax: false)
                    total += times[i].intTime // for calculating average (might do)
                }
            }
        }
        else // mo3 or bo3
        {
            for i in 0..<currentIndex
            {
                times[i].updateString(minMax: false)
                if(ViewController.mo3)
                {
                    total += times[i].intTime
                }
            }
        }
        
        if(currentIndex == 5 && ViewController.ao5 || currentIndex == 3 && (ViewController.mo3 || ViewController.bo3))
        {
            finishAverage(total: total)
        }
        
        
    }
    
    func finishAverage(total: Int) // give int total
    {
        if(currentIndex == 5 && ViewController.ao5) // done with avg5
        {
            averageTypes.append(0)
        }
        else if(currentIndex == 3 && (ViewController.mo3 || ViewController.bo3)) // done with mo3 / bo3
        {
            times.append(SolveTime(enteredTime: "0"))
            times.append(SolveTime(enteredTime: "0"))
            if(ViewController.mo3)
            {
                averageTypes.append(1)
            }
            else
            {
                averageTypes.append(2)
            }
        }
        allTimes.append(times)
        if(total > 950000) // has DNF
        {
            myAverage = "DNF"
            myAverageInt = 999999
        }
        else
        {
            let averageTime = (total + 1) / 3
            myAverageInt = averageTime
            myAverage = SolveTime.makeMyString(num: averageTime)
        }
        allAverages.append(myAverage)
        currentAverage += 1
    }
    
    
}
