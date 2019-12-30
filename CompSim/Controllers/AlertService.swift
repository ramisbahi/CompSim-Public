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
    
    func alert(completion: @escaping () -> Void) -> AddSolveAlertViewController
    {
        let storyboard = UIStoryboard(name: "AddSolveAlert", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "AddSolveAlertVC") as! AddSolveAlertViewController
        alertVC.enterAction = completion
        myVC = alertVC
        return alertVC
    }
}
