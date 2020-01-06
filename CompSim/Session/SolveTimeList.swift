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
    
    convenience init(_ times: [SolveTime]) {
        self.init()
        for time in times
        {
            list.append(time)
        }
    }
    
    
}
