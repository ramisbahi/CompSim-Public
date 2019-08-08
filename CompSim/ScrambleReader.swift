//
//  ScrambleReader.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/17/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation

class ScrambleReader
{
    var currentScramble: Int = -1
    var scrambles: [String] = [] //  array of scrambles used
    var scrambler: TwoByTwoSolver
    var doingTwo: Bool  // doing 2 or 3
    var importedScrambles: [String] = []
    var importedIndex: Int = 0
    
    init(doingTwo: Bool)
    {
        scrambler = TwoByTwoSolver()
        self.doingTwo = doingTwo
        
        let filePath = Bundle.main.path(forResource: "scrambles", ofType: "txt");
        let URL = NSURL.fileURL(withPath: filePath!)
        
        do {
            let string = try String.init(contentsOf: URL) // result
            self.importedScrambles = string.components(separatedBy: "\n") // add result to scrambles (separated by line)
        }
        catch  {
            print(error);
        }
        
    }
    
    func doEvent(event: Bool) // true for 2x2, false for 3x3
    {
        if(doingTwo != event) // changed event, so change event then go to previous scramble then next
        {
            doingTwo = event
            scrambles.remove(at: scrambles.count - 1) // remove last scramble in array
            if(doingTwo) // doing 2x2, so add 2x2 scramble
            {
                scrambles.append(scrambler.solveBounded(state: scrambler.randomState(), minLength: 9, maxLength: 11) ?? " ")
            }
            else // doing imported, so add imported scramble
            {
                scrambles.append(importedScrambles[importedIndex])
                importedIndex += 1
            }
        }
        else
        {
            doingTwo = event
        }
    }
    
    func nextScramble() -> String
    {
        print("next scramble")
        if(doingTwo)
        {
            if(currentScramble < scrambles.count - 1) // already generated that scramble
            {
                
                currentScramble += 1
                return scrambles[currentScramble] // return that element
            }
            else // currentScramble should equal scrambles.count now
            {
                scrambles.append(scrambler.solveBounded(state: scrambler.randomState(), minLength: 9, maxLength: 11) ?? " ")
                currentScramble += 1
                return scrambles[currentScramble]
            }
        }
        else
        {
            scrambles.append(importedScrambles[importedIndex])
            importedIndex += 1
            currentScramble += 1
            return scrambles[currentScramble]
        }
    }
    
    func getCurrentScramble() -> String?
    {
        if(currentScramble < scrambles.count)
        {
            return scrambles[currentScramble]
        }
        else
        {
            return nil
        }
    }
    
    func getScramble(number: Int) -> String
    {
        return scrambles[number]
    }
    
    func previousScramble() -> String
    {
        currentScramble -= 1
        if(!doingTwo) // doing 3x3, so change importedindex
        {
            importedIndex -= 1
        }
        return scrambles[currentScramble]
        
    }
    
    
}
