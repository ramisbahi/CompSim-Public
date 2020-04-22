//
//  CubeState.swift
//  CompSim
//
//  Created by Rami Sbahi on 4/3/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
// GOOD.

import Foundation

class CubeState
{
    var cornersPermutation: [Int8] = []
    var edgesPermutation: [Int8] = []
    
    init(_ cornersPermutation: [Int8], _ edgesPermutation: [Int8])
    {
        self.cornersPermutation = cornersPermutation
        self.edgesPermutation = edgesPermutation
    }
    
    func multiply(move: CubeState) -> CubeState
    {
        var cornersPermutation: [Int8] = [Int8](repeating: 0, count: 8)
        var edgesPermutation: [Int8] = [Int8](repeating: 0, count: 8)
        
        for i in 0..<8
        {
            cornersPermutation[i] = self.cornersPermutation[Int(move.cornersPermutation[i])]
            edgesPermutation[i] = self.edgesPermutation[Int(move.edgesPermutation[i])]
        }
        return CubeState(cornersPermutation, edgesPermutation)
    }
}
