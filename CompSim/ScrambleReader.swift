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
    var twoScrambler: TwoByTwoSolver
    var threeScrambler: TwoPhaseScrambler
    var myEvent: Int
    var megaScrambler: Megaminx
    var clockScrambler: Clock
    var pyraScrambler: Pyraminx
    var skewbScrambler: Skewb
    var sq1Scrambler: Sq1
    var bigCubeScrambler: BigCubeScrambler

    /*var doingTwo: Bool  // doing 2 or 3
    var importedScrambles: [String] = []
    var importedIndex: Int = 0*/
    
    init()
    {
        twoScrambler = TwoByTwoSolver()
        threeScrambler = TwoPhaseScrambler()
        megaScrambler = Megaminx()
        clockScrambler = Clock()
        pyraScrambler = Pyraminx()
        skewbScrambler = Skewb()
        sq1Scrambler = Sq1()
        bigCubeScrambler = BigCubeScrambler()
        
        myEvent = 1 // set to 3x3 by default
        
        /*let filePath = Bundle.main.path(forResource: "scrambles", ofType: "txt");
        let URL = NSURL.fileURL(withPath: filePath!)
        
        do {
            let string = try String.init(contentsOf: URL) // result
            self.importedScrambles = string.components(separatedBy: "\n") // add result to scrambles (separated by line)
        }
        catch  {
            print(error);
        }*/
    }
    
    
    func doEvent(event: Int)
    {
        myEvent = event
        scrambles.remove(at: scrambles.count - 1) // remove last scramble in array
        scrambles.append(genScramble())
    }
    
    func nextScramble() -> String
    {
        print("next scramble")
        if(currentScramble < scrambles.count - 1) // already generated that scramble
        {
            currentScramble += 1
            return scrambles[currentScramble] // return that element
        }
        else // currentScramble should equal scrambles.count now
        {
            scrambles.append(genScramble())
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
        return scrambles[currentScramble]
    }
    
    
    // 0 = 2x2
    // 1 = 3x3
    // 2 = 4x4
    // 3 = 5x5
    // 4 = 6x6
    // 5 = 7x7
    // 6 = pyra
    // 7 = mega
    // 8 = sq1
    // 9 = skewb
    // 10 = clock
    private func genScramble() -> String // generate and return scramble for current event
    {
        switch myEvent
        {
        case 0: // 2x2
            return twoScrambler.solveBounded(state: twoScrambler.randomState(), minLength: 9, maxLength: 11) ?? " "
        case 1: // 3x3
            return threeScrambler.scramble()
        case 2: // 4x4
            return bigCubeScrambler.getScrString(byType: 4)
        case 3: // 4x4
            return bigCubeScrambler.getScrString(byType: 5)
        case 4: // 4x4
            return bigCubeScrambler.getScrString(byType: 6)
        case 5: // 4x4
            return bigCubeScrambler.getScrString(byType: 7)
        case 6:
            return pyraScrambler.scrPyrm()
        case 7:
            return megaScrambler.scrMinx()
        case 8:
            return sq1Scrambler.sq1_scramble(0) // might have to fix
        case 9:
            return skewbScrambler.scrSkb()
        case 10:
            return clockScrambler.scramble()
        default:
                return ""
        }
    }
    
    
}
