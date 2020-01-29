//
//  HelpViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 1/26/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {

    @IBOutlet var BigView: UIView!
    @IBOutlet weak var LittleView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("hi")

        // Do any additional setup after loading the view.
    }
    
    @IBAction func BackToCompSimPressed(_ sender: Any) {
        
        let transition:CATransition = CATransition()
            transition.duration = 0.3
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            transition.type = CATransitionType.push
            transition.subtype = CATransitionSubtype.fromLeft
        
        
            self.navigationController!.view.layer.add(transition, forKey: kCATransition)
            self.navigationController?.popViewController(animated: true)
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
