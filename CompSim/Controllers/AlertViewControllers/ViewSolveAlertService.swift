//
//  ViewSolveAlertService.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

//var enterAction: (() -> Void)?
//var myTitle = String()
//var myScramble = String()
//var penalty: Int = 0 // 0 = OK, 1 = +2, 2 = DNF

import Foundation
import UIKit

class ViewSolveAlertService
{
    var myVC = ViewSolveAlertViewController()
    
    // keyboard: 0 = decimal, 1 = text
    func alert(usingPenalty: Bool, title: String, scramble: String, penalty: Int, completion: @escaping () -> Void) -> ViewSolveAlertViewController
    {
        let storyboard = UIStoryboard(name: "ViewSolveAlert", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "ViewSolveAlertVC") as! ViewSolveAlertViewController
        
        alertVC.enterAction = completion
        alertVC.myTitle = title
        alertVC.myScramble = scramble
        alertVC.penalty = penalty
        alertVC.usingPenalty = usingPenalty
        
        myVC = alertVC
        return alertVC
    }
}
