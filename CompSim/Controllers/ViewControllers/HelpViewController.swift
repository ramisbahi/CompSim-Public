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
    @IBOutlet weak var BackButton: UIButton!
    @IBOutlet weak var ScrollView: UIScrollView!
    
    @IBOutlet weak var HelpLabel: UILabel!
    @IBOutlet weak var DescriptionLabel: UILabel!
    @IBOutlet weak var Step1Label: UILabel!
    @IBOutlet weak var Step1descLabel: UILabel!
    @IBOutlet weak var Step2Label: UILabel!
    @IBOutlet weak var Step2descLabel: UILabel!
    @IBOutlet weak var Step3Label: UILabel!
    @IBOutlet weak var Step3descLabel: UILabel!
    @IBOutlet weak var Step4Label: UILabel!
    @IBOutlet weak var Step4descLabel: UILabel!
    
    
    @IBOutlet var MyLabels: [UILabel]!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        HelpLabel.text = NSLocalizedString("Help", comment: "")
        DescriptionLabel.text = NSLocalizedString("CompSim Description", comment: "")
        Step1Label.text = NSLocalizedString("Step1", comment: "")
        Step1descLabel.text = NSLocalizedString("Step1desc", comment: "")
        Step2Label.text = NSLocalizedString("Step2", comment: "")
        Step2descLabel.text = NSLocalizedString("Step2desc", comment: "")
        Step3Label.text = NSLocalizedString("Step3", comment: "")
        Step3descLabel.text = NSLocalizedString("Step3desc", comment: "")
        Step4Label.text = NSLocalizedString("Step4", comment: "")
        Step4descLabel.text = NSLocalizedString("Step4desc", comment: "")
        BackButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        
        
        if(HomeViewController.darkMode)
        {
            BigView.backgroundColor = HomeViewController.darkModeColor()
            LittleView.backgroundColor = HomeViewController.darkModeColor()
            ScrollView.backgroundColor = HomeViewController.darkModeColor()
            BackButton.backgroundColor = .darkGray
            for label in MyLabels
            {
                label.textColor = .white
                //print(label.text!)
            }
        }

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
