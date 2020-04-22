//
//  Square1Solver.swift
//  CompSim
//
//  Created by Rami Sbahi on 4/3/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import Foundation

class Square1Solver
{
    private var initialized: Bool

    // phase 1
    private var moves1: [State?] = [State?](repeating: nil, count: 23)
    private var shapes: [State] = []
    private var evenShapeDistance: [Int : Int] = [:]
    private var oddShapeDistance: [Int : Int] = [:]

    // phase 2
    let N_CORNERS_PERMUTATIONS = 40320
    let N_CORNERS_COMBINATIONS = 70
    let N_EDGES_PERMUTATIONS = 40320
    let N_EDGES_COMBINATIONS = 70

    private var moves2: [CubeState] = []
    private var cornersPermutationMove: [[Int]] = []
    private var cornersCombinationMove: [[Int]] = []
    private var edgesPermutationMove: [[Int]] = []
    private var edgesCombinationMove: [[Int]] = []
    private var cornersDistance: [[Int8]] = []
    private var edgesDistance: [[Int8]] = []
    
    init(){
        self.initialized = false
    }
    
    private func initialize()
    {
        // -- phase 1 --
        
        // moves
        
        let move10 = State(permutation: [11, 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10,
            12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23])

        var move = move10
        
        for i in 0..<11
        {
            self.moves1[i] = move
            move = move.multiply(move: move10)
        }
        
        let move01 = State(permutation: [0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11,
        13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 12])

        move = move01
        
        for i in 0..<11
        {
            self.moves1[11 + i] = move
            move = move.multiply(move: move01)
        }
        
        let moveTwist = State(permutation: [0,  1, 19, 18, 17, 16, 15, 14,  8,  9, 10, 11,
        12, 13,  7,  6,  5,  4,  3,  2, 20, 21, 22, 23])

        self.moves1[22] = moveTwist

        self.evenShapeDistance[State.id.getShapeIndex()] = 0
        
        print("line 72")
    
        var fringe: [State] = [State.id]

        var depth = 0
        while fringe.count > 0
        {
            print("here")
            var newFringe: [State] = []
            for state in fringe
            {
                if state.isTwistable()
                {
                    self.shapes.append(state)
                }

                for i in 0..<self.moves1.count
                {
                    if i == 22 && !state.isTwistable()
                    {
                        continue
                    }

                    let next: State = state.multiply(move: self.moves1[i]!)

                    if isEvenPermutation(permutation: next.getPiecesPermutation()) // even
                    {
                        if self.evenShapeDistance[next.getShapeIndex()] == nil
                        {
                            self.evenShapeDistance[next.getShapeIndex()] = depth + 1
                            newFringe.append(next)
                        }
                    }
                    else // odd
                    {
                        if self.oddShapeDistance[next.getShapeIndex()] == nil
                        {
                            self.oddShapeDistance[next.getShapeIndex()] = depth + 1
                            newFringe.append(next)
                        }
                    }
                }
            }

            fringe = newFringe
            depth += 1
        }
        
        print("108")

        // -- phase 2 --

        // moves
        let move30 = CubeState([3, 0, 1, 2, 4, 5, 6, 7], [3, 0, 1, 2, 4, 5, 6, 7])
        let move03 = CubeState([0, 1, 2, 3, 5, 6, 7, 4], [0, 1, 2, 3, 5, 6, 7, 4])
        let moveTwistTop = CubeState([0, 6, 5, 3, 4, 2, 1, 7], [6, 5, 2, 3, 4, 1, 0, 7])
        let moveTwistBottom = CubeState([0, 6, 5, 3, 4, 2, 1, 7], [0, 5, 4, 3, 2, 1, 6, 7 ])

        self.moves2 = [
            move30,
            move30.multiply(move: move30),
            move30.multiply(move: move30).multiply(move: move30),
            move03,
            move03.multiply(move: move03),
            move03.multiply(move: move03).multiply(move: move03),
            moveTwistTop,
            moveTwistBottom
        ]
        
        // move tables
        for _ in 0..<self.N_CORNERS_PERMUTATIONS // initialize to correct dimensions of all 0s
        {
            var subArray = [Int]()
            for _ in 0..<self.moves2.count {
                subArray.append(0)
            }
            self.cornersPermutationMove.append(subArray)
        }
        
        
        for i in 0..<self.cornersPermutationMove.count
        {
            let state = CubeState(IndexMapping.indexToPermutation(index: i, length: 8), [0, 0, 0, 0, 0, 0, 0, 0])
            for j in 0..<self.cornersPermutationMove[i].count
            {
                self.cornersPermutationMove[i][j] =
                    IndexMapping.permutationToIndex(
                        permutation: state.multiply(move: self.moves2[j]).cornersPermutation)
            }
        }
        
        // move tables
        for _ in 0..<self.N_CORNERS_COMBINATIONS // initialize to correct dimensions of all 0s
        {
            var subArray = [Int]()
            for _ in 0..<self.moves2.count {
                subArray.append(0)
            }
            self.cornersCombinationMove.append(subArray)
        }
        for i in 0..<self.cornersCombinationMove.count
        {
            let combination: [Bool] = IndexMapping.indexToCombination(index: i, k: 4, length: 8)
            
            var corners: [Int8] = [Int8](repeating: 0, count: 8)
            var nextTop: Int8 = 0
            var nextBottom: Int8 = 4

            for j in 0..<corners.count
            {
                if (combination[j])
                {
                    corners[j] = nextTop
                    nextTop += 1
                }
                else
                {
                    corners[j] = nextBottom
                    nextBottom += 1
                }
            }
            
            
            let state = CubeState(corners, [Int8](repeating: 0, count: 8))
            for j in 0..<self.cornersCombinationMove[i].count
            {
                let result = state.multiply(move: self.moves2[j])

                var isTopCorner = [Bool](repeating: false, count: 8)
                for k in 0..<isTopCorner.count
                {
                    isTopCorner[k] = result.cornersPermutation[k] < 4
                }

                self.cornersCombinationMove[i][j] = IndexMapping.combinationToIndex(combination: isTopCorner, k: 4)
            }
        }
        
        for _ in 0..<self.N_EDGES_PERMUTATIONS // initialize to correct dimensions of all 0s
        {
            var subArray = [Int]()
            for _ in 0..<self.moves2.count {
                subArray.append(0)
            }
            self.edgesPermutationMove.append(subArray)
        }

        for i in 0..<self.edgesPermutationMove.count
        {
            let state = CubeState([Int8](repeating: 0, count: 8), IndexMapping.indexToPermutation(index: i, length: 8));
            for j in 0..<self.edgesPermutationMove[i].count
            {
                self.edgesPermutationMove[i][j] =
                    IndexMapping.permutationToIndex(permutation: state.multiply(move: self.moves2[j]).edgesPermutation)
            }
        }

        for _ in 0..<self.N_EDGES_COMBINATIONS // initialize to correct dimensions of all 0s
        {
            var subArray = [Int]()
            for _ in 0..<self.moves2.count {
                subArray.append(0)
            }
            self.edgesCombinationMove.append(subArray)
        }
        
        for i in 0..<self.edgesCombinationMove.count
        {
            let combination: [Bool] = IndexMapping.indexToCombination(index: i, k: 4, length: 8)

            var edges = [Int8](repeating: 0, count: 8)
            var nextTop: Int8 = 0
            var nextBottom: Int8 = 4

            for j in 0..<edges.count
            {
                if (combination[j]) {
                    edges[j] = nextTop
                    nextTop += 1
                } else {
                    edges[j] = nextBottom
                    nextBottom += 1
                }
            }

            let state = CubeState([Int8](repeating: 0, count: 8), edges)
            for j in 0..<self.edgesCombinationMove[i].count
            {
                let result: CubeState = state.multiply(move: self.moves2[j])
                var isTopEdge = [Bool](repeating: false, count: 8)
                for k in 0..<isTopEdge.count
                {
                    isTopEdge[k] = result.edgesPermutation[k] < 4
                }
                self.edgesCombinationMove[i][j] = IndexMapping.combinationToIndex(combination: isTopEdge, k: 4)
            }
        }

        // prune tables
        
        for _ in 0..<self.N_CORNERS_PERMUTATIONS // initialize corners distance to correct dimensions of all 0s
        {
            var subArray = [Int8]()
            for _ in 0..<self.N_EDGES_COMBINATIONS
            {
                subArray.append(-1)
            }
            self.cornersDistance.append(subArray)
        }
        
        self.cornersDistance[0][0] = 0

        var nVisited = 0
        repeat {
            nVisited = 0

            for i in 0..<self.cornersDistance.count
            {
                for j in 0..<self.cornersDistance[i].count
                {
                    if (self.cornersDistance[i][j] == depth)
                    {
                        for k in 0..<self.moves2.count
                        {
                            let nextCornerPermutation = self.cornersPermutationMove[i][k]
                            let nextEdgeCombination = self.edgesCombinationMove[j][k]
                            if (self.cornersDistance[nextCornerPermutation][nextEdgeCombination] < 0)
                            {
                                self.cornersDistance[nextCornerPermutation][nextEdgeCombination] = Int8(depth + 1)
                                nVisited += 1
                            }
                        }
                    }
                }
            }

            depth += 1
        } while (nVisited > 0);

        
        for _ in 0..<self.N_EDGES_PERMUTATIONS // initialize corners distance to correct dimensions of all 0s
        {
            var subArray = [Int8]()
            for _ in 0..<self.N_CORNERS_COMBINATIONS
            {
                subArray.append(-1)
            }
            self.edgesDistance.append(subArray)
        }
        self.edgesDistance[0][0] = 0

        depth = 0
        repeat {
            nVisited = 0

            for i in 0..<self.edgesDistance.count
            {
                for j in 0..<self.edgesDistance[i].count
                {
                    if self.edgesDistance[i][j] == depth
                    {
                        for k in 0..<self.moves2.count
                        {
                            let nextEdgesPermutation = self.edgesPermutationMove[i][k];
                            let nextCornersCombination = self.cornersCombinationMove[j][k];
                            if (self.edgesDistance[nextEdgesPermutation][nextCornersCombination] < 0)
                            {
                                self.edgesDistance[nextEdgesPermutation][nextCornersCombination] = Int8(depth + 1)
                                nVisited += 1
                            }
                        }
                    }
                }
            }

            depth += 1
        } while (nVisited > 0);

        self.initialized = true
        print("initialized")
    }
    
    
    private func isEvenPermutation(permutation: [Int8]) -> Bool
    {
        var nInversions = 0
        for i in 0..<permutation.count
        {
            for j in (i + 1)..<permutation.count
            {
                if (permutation[i] > permutation[j]) {
                    nInversions += 1
                }
            }
        }
    
        return nInversions % 2 == 0
    }
    
    func generate(state: State) -> [String]
    {
        print("beginning generate")
        var sequence: [String] = []
        
        var top = 0
        var bottom = 0
        let sol = solution(state: state)
        
        let i = sol.count - 1
        
        while i >= 0
        {
            if (sol[i] < 11)
            {
                top += 12 - (sol[i] + 1);
                top %= 12;
            }
            else if (sol[i] < 22)
            {
                bottom += 12 - ((sol[i] - 11) + 1)
                bottom %= 12
            }
            else
            {
                if (top != 0 || bottom != 0)
                {
                    if (top > 6)
                    {
                        top = -(12 - top);
                    }

                    if (bottom > 6)
                    {
                        bottom = -(12 - bottom);
                    }

                    sequence.append("(\(top),\(bottom)")
                    top = 0
                    bottom = 0
                }

                sequence.append("/")
            }
        }

        if (top != 0 || bottom != 0) {
            if (top > 6) {
                top = -(12 - top);
            }

            if (bottom > 6) {
                bottom = -(12 - bottom);
            }

            sequence.append("(\(top),\(bottom)")
        }

        return sequence
    }
    
    public func getRandomState() -> State
    {
        print("getting random state")
        if(!self.initialized)
        {
            initialize()
        }
        
        return getRandomState(shape: self.shapes[Int.random(in: 0..<self.shapes.count)])
    }
    
    private func getRandomState(shape: State) -> State
    {
        let cornersPermutation: [Int8] = IndexMapping.indexToPermutation(index: Int.random(in: 0..<self.N_CORNERS_PERMUTATIONS), length: 8)
        let edgesPermutation: [Int8] = IndexMapping.indexToPermutation(index: Int.random(in: 0..<self.N_EDGES_PERMUTATIONS), length: 8)
        
        var permutation = [Int8](repeating: 0, count: shape.permutation.count)
        for i in 0..<permutation.count
        {
            if (shape.permutation[i] < 8)
            {
                permutation[i] = cornersPermutation[Int(shape.permutation[i])]
            }
            else
            {
                permutation[i] = Int8(8 + edgesPermutation[Int(shape.permutation[i]) - 8])
            }
        }
        
        return State(permutation: permutation)
    }
    
    func solution(state: State) -> [Int]
    {
        print("beginning solution")
        if (!self.initialized) {
            initialize()
        }
        
        var depth = 0
        while true
        {
            var solution1: [Int] = []
            var solution2: [Int] = []
            if (search(state: state, isEvenPermutationParam: isEvenPermutation(permutation: state.getPiecesPermutation()), depth: depth, solution1: &solution1, solution2: &solution2))
            {
                var sequence: [Int] = []

                for moveIndex in solution1
                {
                    sequence.append(moveIndex)
                }

                let phase2MoveMapping: [[Int]] =
                [
                    [ 2 ],
                    [ 5 ],
                    [ 8 ],
                    [ 13 ],
                    [ 16 ],
                    [ 19 ],
                    [ 0, 22, 10 ],
                    [ 21, 22, 11 ]
                ]

                for moveIndex in solution2
                {
                    for phase1MoveIndex in phase2MoveMapping[moveIndex]
                    {
                        sequence.append(phase1MoveIndex)
                    }
                }

                var sequenceArray: [Int] = []
                for i in 0..<sequence.count
                {
                    sequenceArray.append(sequence[i])
                }
                return sequenceArray
            }
            depth += 1
        }
        print("done with solution")
    }
    
    private func search(state: State, isEvenPermutationParam: Bool, depth: Int, solution1: inout [Int], solution2: inout [Int]) -> Bool
    {
        if (depth == 0)
        {
            if (isEvenPermutationParam && state.getShapeIndex() == State.id.getShapeIndex())
            {
                let sequence2 = doSolution2(state: state.toCubeState(), maxDepth: 17)
                if (sequence2 != nil)
                {
                    for m in sequence2!
                    {
                        solution2.append(m)
                    }

                    return true
                }
            }
            return false
        }

        let distance: Int = (isEvenPermutationParam ? self.evenShapeDistance[state.getShapeIndex()] : self.oddShapeDistance[state.getShapeIndex()])!
        if (distance <= depth)
        {
            for i in 0..<self.moves1.count
            {
                if (i == 22 && !state.isTwistable()) {
                    continue
                }

                let next = state.multiply(move: self.moves1[i]!)

                solution1.append(i)
                if (search(
                    state: next,
                    isEvenPermutationParam: isEvenPermutation(permutation: next.getPiecesPermutation()),
                    depth: depth - 1,
                    solution1: &solution1,
                    solution2: &solution2))
                {
                    return true
                }
                solution1.remove(at: solution1.count - 1)
            }
        }

        return false
    }
    
    private func doSolution2(state: CubeState, maxDepth: Int) -> [Int]?
    {
        let cornersPermutation = IndexMapping.permutationToIndex(permutation: state.cornersPermutation)

        var isTopCorner = [Bool](repeating: false, count: 8)
        for k in 0..<isTopCorner.count
        {
            isTopCorner[k] = state.cornersPermutation[k] < 4
        }
        
        let cornersCombination = IndexMapping.combinationToIndex(combination: isTopCorner, k: 4)
        let edgesPermutation = IndexMapping.permutationToIndex(permutation: state.edgesPermutation);

        var isTopEdge = [Bool](repeating: false, count: 8)
        for k in 0..<isTopEdge.count
        {
            isTopEdge[k] = state.edgesPermutation[k] < 4
        }

        let edgesCombination = IndexMapping.combinationToIndex(combination: isTopEdge, k: 4)

        for depth in 0...maxDepth
        {
            var solution = [Int](repeating: 0, count: depth)
            if (search2(cornersPermutation: cornersPermutation, cornersCombination: cornersCombination, edgesPermutation: edgesPermutation, edgesCombination: edgesCombination, depth: depth, solution: &solution)) {
                return solution
            }
        }

        return nil
    }
    
    private func search2(cornersPermutation: Int, cornersCombination: Int, edgesPermutation: Int, edgesCombination: Int, depth: Int, solution: inout [Int]) -> Bool
    {
        if (depth == 0) {
            return cornersPermutation == 0 && edgesPermutation == 0
        }

        if (self.cornersDistance[cornersPermutation][edgesCombination] <= depth &&
            self.edgesDistance[edgesPermutation][cornersCombination] <= depth)
        {
            for i in 0..<self.moves2.count
            {
                if (solution.count - depth - 1 >= 0 && solution[solution.count - depth - 1] / 3 == i / 3)
                {
                    continue
                }
                solution[solution.count - depth] = i
                if (search2(
                    cornersPermutation: self.cornersPermutationMove[cornersPermutation][i],
                    cornersCombination: self.cornersCombinationMove[cornersCombination][i],
                    edgesPermutation: self.edgesPermutationMove[edgesPermutation][i],
                    edgesCombination: self.edgesCombinationMove[edgesCombination][i],
                    depth: depth - 1,
                    solution: &solution))
                {
                    return true
                }
            }
        }

        return false
    }
}
