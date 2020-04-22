//
//  Square1.swift
//  CompSim
//
//  Created by Rami Sbahi on 4/3/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import Foundation
class Square1
{
    var solver = Square1Solver()
    
    init()
    {
        
    }
    
    func getScramble() -> String
    {
        print("getting scramble")
        return solver.generate(state: solver.getRandomState()).joined(separator: " ")
    }
}
