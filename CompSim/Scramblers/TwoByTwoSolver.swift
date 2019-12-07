//
//  TwoByTwoSolver.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/28/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation

class TwoByTwoSolver
{
    init()
    {
        print("2x2 initializing")
        initMoves()
        initPrun()
    
    }
    
    let N_PERM = 5040
    let N_ORIENT = 729
    let N_MOVES = 9
    let MAX_LENGTH = 20
    let moveToString = ["U", "U2", "U'", "R", "R2", "R'", "F", "F2", "F'"]
    
    let fact = [1, 1, 2, 6, 24, 120, 720]
    
   
    /**
     * Converts the list of cubies into a number representing the permutation of the cubies.
     * @param cubies   cubies representation (ori << 3 + perm)
     * @return         an integer between 0 and 5039 representing the permutation of 7 elements
     */  // {1,0 , 2, 3, 4, 5, 6}
    // holy shit turns out first 2 digits of binary rep of cubie represent orientation (00, 10, 01 - never 11 b/c % 24 is done) and last 3 are perm (0 thru 7, but 7 never used)
    // i.e. 10101 is (10) and (101) separate, so it's 16 + 5 (two ccw turns needed to orient, corner 5 in this spot)
    func packPerm(cubies: [Int]) -> Int
    {
        var idx = 0
        var val = 0x6543210
        for i in 0..<6
        {
            let v: Int = (cubies[i] & 0x7) << 2  // just last three digits of current cubie, shift left two (10101 --> 101 --> 10100)
            idx = (7 - i) * idx + ((val >> v) & 0x7) //
            val -= 0x1111110 << v
        }
        return idx
    }
    
    /*
     * Converts an integer representing a permutation of 7 elements into a list of cubies.
     * @param perm     an integer between 0 and 5039 representing the permutation of 7 elements
     * @param cubies   cubies representation (ori << 3 + perm)
     */
    func unpackPerm(myPerm: Int, cubies: inout [Int]) // inout means parameter can be mutated
    {
        var perm: Int = myPerm
        var val: Int =  0x6543210
        for i in 0..<6
        {
            let p = fact[6-i] // 720, 120, 24, 6, 2, 1
            var v: Int = perm / p
            perm -= v*p
            v <<= 2 // val /= 4
            cubies[i] = (val >> v) & 0x7 // (val shifted v times to right) & 0111
            let m: Int = (1 << v) - 1
            val = (val & m) + ((val >> 4) & ~m)
        }
        cubies[6] = val
    }
    
    /*
     * Converts the list of cubies into a number representing the orientation of the cubies.
     * @param cubies   cubies representation (ori << 3 + perm)
     * @return         an integer between 0 and 728 representing the orientation of 6 elements (the 7th is fixed)
     */
    func packOrient(cubies: [Int]) -> Int
    {
        var ori = 0
        for i in 0..<6
        {
            ori = 3 * ori + (cubies[i] >> 3)
        }
        return ori
    }
    
    /*
    * Converts an integer representing the orientation of 6 elements into a list of cubies.
    * @param ori      an integer between 0 and 728 representing the orientation of 6 elements (the 7th is fixed)
    * @param cubies   cubies representation (ori << 3 + perm)
    */
    func unpackOrient(myOri: Int, cubies: inout [Int])
    {
        var ori = myOri
        var sum_ori = 0
        for i in (0...5).reversed()
        {
            cubies[i] = (ori % 3) << 3
            sum_ori += ori % 3
            ori /= 3
        }
        cubies[6] = ((18 - sum_ori) % 3) << 3
    }
    
    // cycles four elements of array
    private func cycle(_ cubies: inout [Int], _ a: Int, _ b: Int, _ c: Int, _ d: Int, _ times: Int)
    {
        let temp = cubies[d]
        cubies[d] = cubies[c]
        cubies[c] = cubies[b]
        cubies[b] = cubies[a]
        cubies[a] = temp
        if(times > 1)
        {
            cycle(&cubies, a, b, c, d, times - 1)
        }
    }
    
    private func cycleAndOrient(_ cubies: inout [Int], _ a: Int, _ b: Int, _ c: Int, _ d: Int, _ times: Int)
    {
        let temp = cubies[d]
        cubies[d] = (cubies[c] + 8) % 24
        cubies[c] = (cubies[b] + 16) % 24
        cubies[b] = (cubies[a] + 8) % 24
        cubies[a] = (temp + 16) % 24
        if(times > 1)
        {
            cycleAndOrient(&cubies, a, b, c, d, times - 1)
        }
    }
    
    private func moveCubies(cubies: inout [Int], move: Int)
    {
        let face = move / 3
        let times = (move % 3) + 1
        switch face {
        case 0: // U face
            cycle(&cubies, 1, 3, 2, 0, times) // starting UFL, clockwise around U face
            break
        case 1: // R face
            cycleAndOrient(&cubies, 0, 2, 6, 4, times) // starting UFR, clockwise around R face
            break
        case 2: // F face
            cycleAndOrient(&cubies, 1, 0, 4, 5, times) // starting UFL, clockwise around F face
            break
        default:
            TwoByTwoSolver.azzert(expr: false)
            break
        }
    }
    
    static func azzert(expr: Bool) {
        if(!expr) {
            print("assertion error")
        }
    }
    
    var movePerm: [[Int]] = Array(repeating: Array(repeating: -1, count: 9), count: 5040) // [5040][9]
    var moveOrient: [[Int]] = Array(repeating: Array(repeating: -1, count: 9), count: 729) // [5040][9] // [729][9]
    
    private func initMoves()
    {
        var cubies1: [Int] = Array(repeating:0, count: 7) // original perm
        var cubies2: [Int] = Array(repeating: 0, count: 7) // perm with each move done on it
    
        // fills array with permutation resulting from each move for each perm
        for perm in 0..<N_PERM
        {
            unpackPerm(myPerm: perm, cubies: &cubies1)
            for move in 0..<N_MOVES
            {
                cubies2[0...6] = cubies1[0...6] // copies the 7 components of cubies1
                                                // (original perm -- fresh) to cubies2
                moveCubies(cubies: &cubies2, move: move) // makes turn on cubies 2 for resulting permutation
                let newPerm = packPerm(cubies: cubies2) // new permutation (number representation)
                movePerm[perm][move] = newPerm
            }
        }
        
        // same for orientations
        for orient in 0..<N_ORIENT
        {
            unpackOrient(myOri: orient, cubies: &cubies1)
            for move in 0..<N_MOVES
            {
                cubies2[0...6] = cubies1[0...6] // copies the 7 components of cubies1
                // (original perm -- fresh) to cubies2
                moveCubies(cubies: &cubies2, move: move) // makes turn on cubies 2 for resulting permutation
                let newOrient = packOrient(cubies: cubies2) // new permutation (number representation)
                moveOrient[orient][move] = newOrient
            }
        }
        
        // Pruning tables
        
        
        
    
    }
    
    private var prunPerm: [Int] = Array(repeating: -1, count: 5040) // [5040]
    private var prunOrient: [Int] = Array(repeating: -1, count: 729) // [729]
    
    private func initPrun()
    {
        prunPerm[0] = 0
    
        var done = 1
        var length = 0
        
        
        while done < N_PERM // until permutations done
        {
            for perm in 0..<N_PERM
            {
                if(prunPerm[perm] == length) // this position is this length away
                {
                    for move in 0..<N_MOVES // perform each move on this position
                    {
                        let newPerm = movePerm[perm][move]
                        if(prunPerm[newPerm] == -1) // has not been accessed yet
                        {
                            prunPerm[newPerm] = length + 1; // hasnt been accessed before, so distance is +1
                            done += 1 // incremented each time new permutation added (will be 5040)
                        }
                    }
                }
            }
            length += 1 // next length
        }
        
        
        // do same for orientations
        
        prunOrient[0] = 0
        
        done = 1
        length = 0
        
        while done < N_ORIENT // until orientations done
        {
            for orient in 0..<N_ORIENT
            {
                if(prunOrient[orient] == length) // this position is this length away
                {
                    for move in 0..<N_MOVES // perform each move on this position
                    {
                        let newOrient = moveOrient[orient][move]
                        if(prunOrient[newOrient] == -1) // has not been accessed yet
                        {
                            prunOrient[newOrient] = length + 1; // hasnt been accessed before, so distance to solved is + 1
                            done += 1 // incremented each time new permutation added (will be 5040)
                        }
                    }
                }
            }
            length += 1 // next length
        }
        
    }
    
    struct TwoByTwoState // double check on this
    {
        var permutation, orientation: Int
    }
    
    func randomState() -> TwoByTwoState
    {
        let state = TwoByTwoState(permutation: Int.random(in: 0..<N_PERM), orientation: Int.random(in: 0..<N_ORIENT))
        return state
    }
    
    // solves in maximum length amt of moves
    func solveMax(state: TwoByTwoState, length: Int) -> String?
    {
        return solve(state: state, desiredLength: length, exactLength: false)
    }
    
    func generateExactly(state: TwoByTwoState, length: Int) -> String?
    {
        return solve(state: state, desiredLength: length, exactLength: true)
    }
    
    
    // between min and max
    func solveBounded(state: TwoByTwoState, minLength: Int, maxLength: Int) -> String?
    {
        var solution: [Int] = Array(repeating: 0, count: MAX_LENGTH) // 20 (MAX_LENGTH)
        var best_solution: [Int] = Array(repeating: 0, count: MAX_LENGTH + 1) // 21 (MAX_LENGTH + 1)
        var foundSolution: Bool = false
        var length = minLength
        
        while length <= maxLength
        {
            best_solution[length] = 42424242
            if(search(perm: state.permutation, orient: state.orientation, depth:0, length: length, last_move:42, solution: &solution, best_solution: &best_solution)) // stuff
            {
                foundSolution = true
                break
            }
            length += 1
        }
        
        if(!foundSolution)
        {
            return nil
        }
        if length == 0
        {
            return ""
        }
        
        var scramble: String = ""
        scramble.append(moveToString[best_solution[0]])
        for l in 1..<length
        {
            scramble.append(" ")
            scramble.append(moveToString[best_solution[l]])
        }
        
        return scramble
    }
    
    // solves in maximum desiredLength amount of moves if not exact, or exactly if exact
    private func solve(state: TwoByTwoState, desiredLength: Int, exactLength: Bool) -> String?
    {
        var solution: [Int] = Array(repeating: 0, count: MAX_LENGTH) // 20 (MAX_LENGTH)
        var best_solution: [Int] = Array(repeating: 0, count: MAX_LENGTH + 1) // 21 (MAX_LENGTH + 1)
        var foundSolution: Bool = false
        var length = exactLength ? desiredLength : 0
        
        while length <= desiredLength
        {
            best_solution[length] = 42424242
            if(search(perm: state.permutation, orient: state.orientation, depth:0, length: length, last_move:42, solution: &solution, best_solution: &best_solution)) // stuff
            {
                foundSolution = true
                break
            }
            length += 1
        }
        
        if(!foundSolution)
        {
            return nil
        }
        if length == 0
        {
             return ""
        }
        
        var scramble: String = ""
        scramble.append(moveToString[best_solution[0]])
        for l in 1..<length
        {
            scramble.append(" ")
            scramble.append(moveToString[best_solution[l]])
        }
        
        return scramble
    }
    
    private func search(perm: Int, orient: Int, depth: Int, length: Int, last_move: Int, solution: inout [Int], best_solution: inout [Int]) -> Bool
    {
        /* If there are no moves left to try (length=0), check if the current position is solved */
        if(length == 0) {
            if ((perm == 0) && (orient == 0))
            {
                // Solution found! Compute the cost of applying the reverse solution.
                let cost = computeCost(solution: solution, index: depth, current_cost: 0, grip: 0)
                
                // We found a better solution, storing it.
                if cost < best_solution[depth]
                {
                    best_solution[0..<depth] = solution[0..<depth]
                    best_solution[depth] = cost
                }
                return true
            }
            return false
        }
        
        /* Check if we might be able to solve the permutation or the orientation of the position
         * given the remaining number of moves ('length' parameter), using the pruning tables.
         * If not, there is no point keeping searching for a solution, just stop.
         * If either of them is too many moves from solved, give up
         */
        if((prunPerm[perm] > length) || (prunOrient[orient] > length))
        {
            return false;
        }
        
        /* The recursive part of the search function.
         * Try every move from the current position, and call the search function with the new position
         * and the updated parameters (depth -> depth+1; length -> length-1; last_move -> move)
         * We don't need to try a move of the same face as the last move.
         */
        var solutionFound = false
        for move in 0..<N_MOVES
        {
            
            // Check if the tested move is of the same face as the previous move (last_move).
            if((move / 3) == (last_move / 3))
            {
                continue;
            }
            
            // Apply the move
            let newPerm: Int = movePerm[perm][move]
            let newOrient: Int = moveOrient[orient][move]
            
            // Store the moves
            solution[depth] = move
            
            // Call the recursive function
            
            solutionFound = search(perm: newPerm, orient: newOrient, depth: depth+1, length: length-1, last_move: move, solution: &solution, best_solution: &best_solution) || solutionFound
            // search always done
            
            /*if(solutionFound == true)// Rami added to see it being built
             {
             StringBuilder scramble = new StringBuilder(MAX_LENGTH*3);
             scramble.append(moveToString[best_solution[0]]);
             for(int l=1; l<length; l++)
             {
             scramble.append(" ").append(moveToString[best_solution[l]]);
             }
             System.out.println(scramble.toString());
             
             }*/
        }
        return solutionFound
    }
    
    static let cost_U = 8
    static let cost_U_low = 20 // when grip = -1
    static let cost_U2 = 10
    static let cost_U3 = 7
    static let cost_R = 6
    static let cost_R2 = 10
    static let cost_R3 = 6
    static let cost_F = 20 // originally 10
    static let cost_F_front = 25 // thumb in front (bad)
    static let cost_F2 = 60 // originally 30
    static let cost_F3 = 38 // originally 19
    static let cost_regrip = 40 // originally 20
    
    /*
     * Try to evaluate the cost of applying a scramble - recursive
     * @param solution      the solution found by the solver, we need to read it backward and inverting the moves
     * @param index         current position of reading. Starts at the length-1 of the solution, and decrease by 1 every call
     * @param current_cost  current cost of the sequence that has been already read
     * @param grip          state of the grip of the right hand. -1: thumb on D, 0: thumb on F, 1: thumb on U
     * @return              returns the cost of the whole sequence
     */
    
    private func computeCost(solution: [Int], index: Int, current_cost: Int, grip: Int) -> Int
    {
        if(index < 0)
        {
            return current_cost
        }
        switch solution[index] {
        case 0: // U
            if grip == 0
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_U, grip: 0)
            }
            else if(grip == -1)
            {
                return min(computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_regrip + TwoByTwoSolver.cost_U, grip: 0), computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_U_low, grip: grip))
                // recursive - will see if better to regrip and do U (w/ thumb front) or do U in bad position (thumb bottom, even after move)
            }
        case 1: // U2
            return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_U2, grip: grip)
        case 2: // U'
            return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_U3, grip: grip)
        case 3: // R
            if(grip < 1) // thumb not on top (good)
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R, grip: grip + 1)
            }
            else
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R + TwoByTwoSolver.cost_R, grip: 1)
            }
        case 4: // R2
            if(grip != 0) // top or bottom (good)
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R2, grip: -grip) // thumb top --> bottom or bottom --> top
            }
            else
            {
                return min(computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R2 + TwoByTwoSolver.cost_regrip, grip: 1), computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R2 + TwoByTwoSolver.cost_regrip, grip: -1))
            }
        case 5: // R'
            if(grip > -1) // thumb not on bottom (good)
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R3, grip: grip - 1)
            }
            else // rami changed - can end up thumb bottom (i.e. R' U' R) or front (i.e. R' U R)
            {
                return min(computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R3 + TwoByTwoSolver.cost_regrip, grip: -1), computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_R3 + TwoByTwoSolver.cost_regrip, grip: 0))
            }
        case 6: // F
            if(grip == -1)
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F, grip: -1)
            }
            else if(grip == 0)
            {
                return min(computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F + TwoByTwoSolver.cost_regrip, grip: -1), computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F_front, grip: 0)) // keep thumb on front
            }
            else // thumb on top
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F + TwoByTwoSolver.cost_regrip, grip: -1)
            }
        case 7: // F2
            if(grip == -1)
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F2, grip: -1)
            }
            else
            {
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F2 + TwoByTwoSolver.cost_regrip, grip: -1)
            }
        case 8: // F' - never really need regrip
                return computeCost(solution: solution, index: index-1, current_cost: current_cost + TwoByTwoSolver.cost_F3, grip: grip)
        default:
            TwoByTwoSolver.azzert(expr: false)
            break
        }
        return -1
    }
    
    

}
