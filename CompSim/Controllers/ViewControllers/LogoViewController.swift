//
//  LogoViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/31/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class LogoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(dismissSplashController), userInfo: nil, repeats: false)
        // Do any additional setup after loading the view.
    }
    
    @objc func dismissSplashController()
    {
        self.performSegue(withIdentifier: "FirstSegue", sender: self)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
