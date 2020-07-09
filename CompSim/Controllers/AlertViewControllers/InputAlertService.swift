//
//  AlertService.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import UIKit

class InputAlertService
{
    var myVC = InputAlertViewController()
    
    // keyboard: 0 = decimal, 1 = text
    func alert(placeholder: String, keyboardType: Int, myTitle: String, completion: @escaping () -> Void) -> InputAlertViewController
    {
        let storyboard = UIStoryboard(name: "InputAlert", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "InputAlertVC") as! InputAlertViewController
        alertVC.enterAction = completion
        alertVC.myTitle = myTitle
        alertVC.keyboardType = keyboardType
        alertVC.placeholder = placeholder
        myVC = alertVC
        return alertVC
    }
}
