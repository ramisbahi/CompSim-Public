import UIKit



func getDrawArray(scramble: String) -> [String]
{
    var retArr: [String] = []
    let colors = ["G", "R", "B", "O", "W", "Y"]
    for i in 0..<6
    {
        for _ in 0..<9
        {
            retArr.append(colors[i])
        }
    }
    
    let moves = scramble.components(separatedBy: " ")
    
    for move in moves
    {
        doMove(arr: &retArr, move: move)
    }
    
    
    return retArr
}

func doMove(arr: inout [String], move: String)
{
    var numCycles = 3 // default for '
    var cycles: [[Int]] = []
    if move.contains("U")
    {
        cycles = [[36, 38, 44, 42], [37, 41, 43, 39], [1, 28, 19, 10], [0, 27, 18, 9], [2, 29, 20, 11]]
        
        if(move == "U")
        {
            numCycles = 1
        }
        else if(move == "U2")
        {
            numCycles = 2
        }
        // else (U') - 3 cycles
    }
    else if move.contains("D")
    {
        cycles = [[45, 47, 53, 51], [46, 50, 52, 48], [6, 15, 24, 33], [7, 16, 25, 34], [8, 17, 26, 35]]
        
        if(move == "D")
        {
            numCycles = 1
        }
        else if(move == "D2")
        {
            numCycles = 2
        }
        // else (D') - 3 cycles
    }
    else if move.contains("F")
    {
        cycles = [[0, 2, 8, 6], [1, 5, 7, 3], [42, 9, 47, 35], [43, 12, 46, 32], [44, 15, 45, 29]]
        
        if(move == "F")
        {
            numCycles = 1
        }
        else if(move == "F2")
        {
            numCycles = 2
        }
        // else (F') - 3 cycles
    }
    else if move.contains("B")
    {
        cycles = [[18, 20, 26, 24], [19, 23, 25, 21], [11, 36, 33, 53], [14, 37, 30, 52], [17, 38, 27, 51]]
        
        if(move == "B")
        {
            numCycles = 1
        }
        else if(move == "B2")
        {
            numCycles = 2
        }
        // else (B') - 3 cycles
    }
    else if move.contains("R")
    {
        cycles = [[9, 11, 17, 15], [10, 14, 16, 12], [2, 38, 24, 47], [5, 41, 21, 50], [8, 44, 18, 53]]
        
        if(move == "R")
        {
            numCycles = 1
        }
        else if(move == "R2")
        {
            numCycles = 2
        }
        // else (R') - 3 cycles
    }
    else if move.contains("L")
    {
        cycles = [[27, 29, 35, 33], [28, 32, 34, 30], [0, 45, 26, 36], [3, 48, 23, 39], [6, 51, 20, 42]]
        
        if(move == "L")
        {
            numCycles = 1
        }
        else if(move == "L2")
        {
            numCycles = 2
        }
        // else (R') - 3 cycles
    }
    
    performMove(&arr, cycles, numCycles)
}

func performMove(_ arr: inout [String], _ cycles: [[Int]], _ numCycles: Int)
{
    for _ in 0..<numCycles // perform numCycles times
    {
        for cycle in cycles // each cycle
        {
            let temp = arr[cycle[0]]
            arr[cycle[0]] = arr[cycle[3]]
            arr[cycle[3]] = arr[cycle[2]]
            arr[cycle[2]] = arr[cycle[1]]
            arr[cycle[1]] = temp
        }
    }
}

getDrawArray(scramble: "U' B2 R2 B' U2 B D2 U2 F' D2 F' D2 R2 U' R' D' B' U R' U2")
