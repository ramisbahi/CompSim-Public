//
//  SimpleAlertService.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import Foundation
import UIKit

class SimpleAlertService
{
    var myVC = SimpleAlertViewController()
    
    // keyboard: 0 = decimal, 1 = text
    func alert(myTitle: String, completion: @escaping () -> Void) -> SimpleAlertViewController
    {
        let storyboard = UIStoryboard(name: "SimpleAlertViewController", bundle: .main)
        let alertVC = storyboard.instantiateViewController(withIdentifier: "SimpleAlertVC") as! SimpleAlertViewController
        alertVC.enterAction = completion
        alertVC.myTitle = myTitle
        myVC = alertVC
        return alertVC
    }
}
