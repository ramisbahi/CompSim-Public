//
//  ChartValueFormatter.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/11/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import Foundation
import Charts

class ChartValueFormatter: NSObject, IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String{
        return (value + 0.001).format(allowsFractionalUnits: true)!
    }

}
