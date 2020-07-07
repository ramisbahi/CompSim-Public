//
//  ViewSolveAlertViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class ViewSolveAlertViewController: UIViewController {
    
    
    // below 4 are all entered
    var enterAction: (() -> Void)?
    var deleteAction: (() -> Void)?
    var myTitle = String()
    var myScramble = String()
    var penalty: Int = 0 // 0 = OK, 1 = +2, 2 = DNF
    var delete: Bool = true
    
    var penalties = [1, 2, 0]
    var usingPenalty: Bool = true

    @IBOutlet weak var PenaltyConstraint: NSLayoutConstraint!
    @IBOutlet weak var TitleLabel: UILabel!
    @IBOutlet weak var ScrambleLabel: UILabel!
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var ViewSolveView: UIView!
    @IBOutlet weak var DoneButton: UIButton!
    @IBOutlet weak var DeleteButton: UIButton!
    @IBOutlet weak var DoneCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet var BigView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 11.0, *) {
            ViewSolveView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        
        if(HomeViewController.darkMode)
        {
            ViewSolveView.backgroundColor = .darkGray
        }
        
        TitleLabel.text = myTitle
        ScrambleLabel.text = myScramble
        
        if(usingPenalty)
        {
            PenaltySelector.selectedSegmentIndex = penalties[penalty]
        }
        else
        {
            PenaltySelector.isHidden = true
            PenaltyConstraint.isActive = false
            ScrambleLabel.bottomAnchor.constraint(equalTo: DoneButton.topAnchor, constant: -5).isActive = true
        }
        
        if(delete)
        {
            DeleteButton.isHidden = false
            DoneCenterConstraint.isActive = false
        }
        
        ScrambleLabel.font = HomeViewController.fontToFitHeight(view: BigView, multiplier: 0.04, name: "Lato-Regular")
        
        PenaltySelector.setTitleTextAttributes([NSAttributedString.Key.font: HomeViewController.fontToFitHeight(view: PenaltySelector, multiplier: 0.7, name: "Lato-Black"), NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
    }
    
    @IBAction func DonePressed(_ sender: Any) {
        dismiss(animated: true)
        enterAction?()
    }
    
    @IBAction func DeletePressed(_ sender: Any) {
        dismiss(animated: true)
        deleteAction?()
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

