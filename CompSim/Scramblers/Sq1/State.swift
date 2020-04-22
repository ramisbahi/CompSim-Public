//
//  State.swift
//  CompSim
//
//  Created by Rami Sbahi on 4/3/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

// GOOD.

import Foundation

class State
{
    var permutation: [Int8] = []
    
    static let id = State(permutation: [0,  8,  1,  1,  9,  2,  2, 10,  3,  3, 11,  0,
    4, 12,  5,  5, 13,  6,  6, 14,  7,  7, 15,  4])

    init(permutation: [Int8])
    {
        self.permutation = permutation
    }
    
    func isTwistable() ->Bool
    {
        return self.permutation[1] != self.permutation[2] &&
        self.permutation[7] != self.permutation[8] &&
        self.permutation[13] != self.permutation[14] &&
        self.permutation[19] != self.permutation[20]
    }
    
    func multiply(move: State) -> State
    {
        var permutation: [Int8] = [Int8](repeating: 0, count: 24)
        
        for i in 0..<permutation.count
        {
            permutation[i] = self.permutation[Int(move.permutation[i])]
        }
        return State(permutation: permutation)
    }
        
    func getShapeIndex() -> Int
    {
        var cuts: [Int8] = [Int8](repeating: 0, count: 24)
        
        for i in 0..<12
        {
            let next = (i + 1) % 12
            if self.permutation[i] != self.permutation[next]
            {
                cuts[i] = 1
            }
        }
        
        for i in 0..<12
        {
            let next = (i + 1) % 12
            if self.permutation[12+i] != self.permutation[12+next]
            {
                cuts[12+i] = 1
            }
        }
        
        return IndexMapping.orientationToIndex(orientation: cuts, nValues: 2)
    }
    
    func getPiecesPermutation() -> [Int8]
    {
        var permutation: [Int8] = [Int8](repeating: 0, count: 16)
        var nextSlot = 0;

        for i in 0..<12
        {
            let next = (i + 1) % 12;
            if (self.permutation[i] != self.permutation[next]) {
                permutation[nextSlot] = self.permutation[i]
                nextSlot += 1
            }
        }
        
        for i in 0..<12
        {
            let next = 12 + (i + 1) % 12
            if (self.permutation[12+i] != self.permutation[next])
            {
                permutation[nextSlot] = self.permutation[12+i]
                nextSlot += 1
            }
        }

        return permutation
    }
    
    func toCubeState() -> CubeState
    {
        let cornerIndices: [Int] = [0, 3, 6, 9, 12, 15, 18, 21]
        
        var cornersPermutation: [Int8] = [Int8](repeating: 0, count: 8)
        
        for i in 0..<8
        {
            cornersPermutation[i] = self.permutation[cornerIndices[i]]
        }

        let edgeIndices: [Int] = [1, 4, 7, 10, 13, 16, 19, 22]

        var edgesPermutation: [Int8] = [Int8](repeating: 0, count: 8)
        
        for i in 0..<8
        {
            edgesPermutation[i] = Int8(self.permutation[edgeIndices[i]] - 8)
        }

        return CubeState(cornersPermutation, edgesPermutation)
    }

}


