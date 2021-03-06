//
//  NotificationAlertViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 1/9/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit




class NotificationAlertViewController: UIViewController
{
    @IBOutlet var NotifView: UIView!
    @IBOutlet var NotifTitle: UILabel!
    
    var myTitle = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotifTitle.text = myTitle
        if #available(iOS 11.0, *) {
            NotifView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        
        if(HomeViewController.darkMode)
        {
            NotifView.backgroundColor = HomeViewController.darkPurpleColor()
        }
    }

    @IBAction func OKPressed(_ sender: Any) {
        dismiss(animated: true)
    }
}
