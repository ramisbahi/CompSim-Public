//
//  SolveTime.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/10/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import RealmSwift

extension String
{
    // time string (i.e. 2:45.89) to float (165.89)
    func toFloatTime() -> Float
    {
        var decimalTime = self.replacingOccurrences(of: ",", with: ".")
        if decimalTime.contains(":")
        {
            let removeable: Set<Character> = [":", "."]
            decimalTime.removeAll(where: {removeable.contains($0)})
        }
        
        if(decimalTime.countInstances(of: ".") == 1 || decimalTime.count <= 2) // i.e. 67.01 --> 1:07.01
        {
            return Float(decimalTime)!
        }
        // else - no decimal, more than 2 characters
        if(decimalTime.count <= 4)
        {
            return Float(decimalTime)! / 100
        }
        // else - 5+ characters, no decimal // example: 21965 (2:19.65)
        let min = Int(String(decimalTime.prefix(decimalTime.count - 4)))! // 2
        let rest = Int(String(decimalTime.suffix(4)))! // 1965
        let minSec = min * 60
        let restSec: Float = Float(rest) / 100
        return Float(minSec) + restSec
    }
}

class SolveTime: Object
{
    // new 
    @objc dynamic var intTime = 0
    @objc dynamic var originalIntTime = 0 // only use when switching to DNF
    @objc dynamic var isMinMax = false
    @objc dynamic var penalty = 0 // 0 = OK, 1 = +2, 2 = DNF
    
    @objc dynamic var myString: String = ""
    @objc dynamic var myScramble: String = ""

    
    
    // can be min:sec:decimal
    convenience init(enteredTime: String, scramble: String) {
        self.init()
        print(enteredTime)
        myScramble = scramble
        
        let floatTime = enteredTime.toFloatTime()
        
        print("float \(floatTime)")
        intTime = SolveTime.makeIntTime(num: floatTime)
        myString = SolveTime.makeMyString(num: intTime)
        print("int \(intTime)")
        print("string \(myString)")
    }
    
    static func makeIntTime(num: Float) -> Int // convert to rounded int (i.e. 1.493 --> 149, 1.496 --> 150. Rounding is necessary when calculating averages)
    {
        return Int(num * 100 + 0.5)
    }
    
    func getMyString() -> String
    {
        return myString
    }
    
    func setNoPenalty()
    {
        if(penalty == 0) // nothing to do
        {
            return
        }
        if(penalty == 1)
        {
            intTime -= 200
        }
        else if(penalty == 2)
        {
            intTime = originalIntTime
        }
        penalty = 0
    }
    
    func setPlusTwo()
    {
        if(penalty == 1) // already +2
        {
            return
        }
        if(penalty == 2)
        {
            intTime = originalIntTime
        }
        intTime += 200
        penalty = 1
    }
    
    func setDNF()
    {
        if(penalty == 2) // already DNF
        {
            return
        }
        if(penalty == 1)
        {
            intTime -= 200
        }
        originalIntTime = intTime
        intTime = 999999
        penalty = 2
    }
    
    func updateString(minMax: Bool)
    {
        var final = SolveTime.makeMyString(num: intTime)
        
        if(penalty == 1) // +2
        {
            final += "+"
        }
        else if(penalty == 2) // DNF
        {
            final = "DNF"
        }
        
        if(minMax) // minMax
        {
            final = "(" + final + ")"
            isMinMax = true
        }
        else
        {
            isMinMax = false
        }
        
        myString = final
    }

    // does NOT take into account penalties
    static func makeMyString(num: Int) -> String // 149 --> 1.49
    {
        let interval: TimeInterval = (Double(num) + 0.1) / 100.0 // bc going to round down, so make 149 --> 149.1 --> 1.491, which will always get formatted correctly
        return interval.format(allowsFractionalUnits: true)!
    }
}
