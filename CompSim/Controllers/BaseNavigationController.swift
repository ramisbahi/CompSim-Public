//
//  BaseNavigationController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/9/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

internal class BaseNavigationController: UINavigationController, UINavigationControllerDelegate, UIGestureRecognizerDelegate
{

    override func viewDidLoad() {
        super.viewDidLoad()
        print("this is called")
        interactivePopGestureRecognizer?.delegate = self
    }
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

