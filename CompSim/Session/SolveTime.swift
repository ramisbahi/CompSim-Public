//
//  SolveTime.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/10/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import RealmSwift

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
        
        var decimalTime = enteredTime.replacingOccurrences(of: ",", with: ".")
        
        myScramble = scramble
        var floatTime: Float = 0.0
        if(decimalTime.countInstances(of: ".") == 1 || decimalTime.count <= 2) // i.e. 67.01 --> 1:07.01
        {
            floatTime = Float(decimalTime)!
        }
    
        else // no decimal, more than 2 characters
        {
            if(decimalTime.count <= 4)
            {
                floatTime = Float(decimalTime)! / 100
            }
            else // 5+ characters, no decimal // example: 21965 (2:19.65)
            {
                let min = Int(String(decimalTime.prefix(decimalTime.count - 4)))! // 2
                let rest = Int(String(decimalTime.suffix(4)))! // 1965
                let minSec = min * 60
                let restSec: Float = Float(rest) / 100
                floatTime = Float(minSec) + restSec
            }
        }
        
        intTime = SolveTime.makeIntTime(num: floatTime)
        myString = SolveTime.makeMyString(num: intTime)
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
        let stringNum: String = String(num)
        var beforeDecimal = ""
        var afterDecimal = ""
        if(stringNum.count <= 2) // 4 --> 0.04, 40 --> 0.40
        {
            beforeDecimal = "0"
            if(stringNum.count == 1)
            {
                afterDecimal = "0" + stringNum
            }
            else // length 2
            {
                afterDecimal = stringNum
            }
        }
        else //
        {
            beforeDecimal = String(stringNum.prefix(stringNum.count - 2))
            if(num >= 6000) // longer than a minute
            {
                let beforeDecimalNum = Int(beforeDecimal)! // i.e. 157 for 2:37.65 --> 15765
                let beforeColon = String(beforeDecimalNum / 60)
                var afterColon = String(beforeDecimalNum % 60)
                if(afterColon.count == 1) // i.e. 2:3.79 --> 2:03.79
                {
                    afterColon = "0" + afterColon
                }
                beforeDecimal = beforeColon + ":" + afterColon
            }
            afterDecimal = String(stringNum.suffix(2))
        }
        
        let fullString = beforeDecimal + "." + afterDecimal
        
        let formatter = NumberFormatter()
        formatter.locale = NSLocale.current
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.usesGroupingSeparator = true
        let usingComma: Bool = formatter.string(from: 2.5)!.contains(",")
        print("using comma \(usingComma)")
        
        if(usingComma) // european style
        {
            return fullString.replacingOccurrences(of: ".", with: ",")
        }
        return fullString // normal
    }
}
