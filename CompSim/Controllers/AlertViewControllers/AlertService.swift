//
//  AlertService.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import UIKit

class AlertService
{
    var myVC = AddSolveAlertViewController()
    
    // keyboard: 0 = decimal, 1 = text
    func alert(keyboardType: Int, myTitle: String, completion: @escaping () -> Void) -> AddSolveAlertViewController
    {
        let storyboard = UIStoryboard(name: "AddSolveAlert", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "AddSolveAlertVC") as! AddSolveAlertViewController
        alertVC.enterAction = completion
        alertVC.myTitle = myTitle
        alertVC.keyboardType = keyboardType
        myVC = alertVC
        return alertVC
    }
}
