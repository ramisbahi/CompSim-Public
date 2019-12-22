//
//  SolveTimeList.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/22/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import RealmSwift

class SolveTimeList: Object
{
    let list = List<SolveTime>()
    
    init(_ times: [SolveTime])
    {
        for time in times
        {
            list.append(time)
        }
    }
    
    required init() {
        for _ in 0..<5
        {
            list.append(SolveTime())
        }
    }
}
