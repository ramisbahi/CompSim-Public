//
//  ScrambleReader.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/17/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import RealmSwift

class ScrambleReader
{
    var currentScramble: String = ""
    lazy var twoScrambler: TwoByTwoSolver = TwoByTwoSolver()
    lazy var threeScrambler: TwoPhaseScrambler = TwoPhaseScrambler()
    lazy var megaScrambler: Megaminx = Megaminx()
    lazy var clockScrambler: Clock = Clock()
    lazy var pyraScrambler: Pyraminx = Pyraminx()
    lazy var skewbScrambler: Skewb = Skewb()
    lazy var sq1Scrambler: Sq1 = Sq1()
    lazy var bigCubeScrambler: BigCubeScrambler = BigCubeScrambler()

    /*var doingTwo: Bool  // doing 2 or 3*/
    
    var myEvent: Int
    
    convenience init()
    {
        self.init(event: 1) // default to 3x3
    }
    
    init(event: Int)
    {
        myEvent = event
        genScramble()
    }
    
    
    func doEvent(event: Int)
    {
        if(myEvent != event)
        {
            myEvent = event
            genScramble()
        }
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
    public func genScramble()  // generate and return scramble for current event
    {
        
        switch myEvent
        {
        case 0: // 2x2
            currentScramble = twoScrambler.solveBounded(state: twoScrambler.randomState(), minLength: 8, maxLength: 11) ?? " "
        case 1: // 3x3
            currentScramble = threeScrambler.scramble()
        case 2: // 4x4
            currentScramble = bigCubeScrambler.getScrString(byType: 4)
        case 3: // 4x4
            currentScramble = bigCubeScrambler.getScrString(byType: 5)
        case 4: // 4x4
            currentScramble = bigCubeScrambler.getScrString(byType: 6)
        case 5: // 4x4
            currentScramble = bigCubeScrambler.getScrString(byType: 7)
        case 6:
            currentScramble = pyraScrambler.scrPyrm()
        case 7:
            currentScramble = megaScrambler.scrMinx()
        case 8:
            currentScramble = sq1Scrambler.sq1_scramble(1) // might have to fix
        case 9:
            currentScramble = skewbScrambler.scrSkb()
        case 10:
            currentScramble = clockScrambler.scramble()
        default:
            currentScramble = ""
        }
    }
    
    
}
