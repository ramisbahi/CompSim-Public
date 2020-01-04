//
//  AddSolveAlertViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class AddSolveAlertViewController: UIViewController {
    
    var enterAction: (() -> Void)?
    var myTitle = String()
    var keyboardType = 0 // keyboard: 0 = decimal, 1 = text
    var usingPenalty: Bool = true
    var placeholder = String()
    
    @IBOutlet weak var TextField: UITextField!
    @IBOutlet weak var EnterButton: UIButton!
    @IBOutlet weak var AddSolveView: UIView!
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var PenaltyConstraint: NSLayoutConstraint!
    @IBOutlet weak var CancelButton: UIButton!
    
    @IBOutlet weak var AddSolveTitle: UILabel!
    @IBOutlet weak var AlertView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TextField.becomeFirstResponder()
        
        AddSolveTitle.text = myTitle
        AddSolveView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        if(ViewController.darkMode)
        {
            AddSolveView.backgroundColor = .darkGray
        }
        
        if(keyboardType == 1)
        {
            TextField.keyboardType = .default
        }
        
        if(!usingPenalty)
        {
            PenaltySelector.isHidden = true
            PenaltyConstraint.isActive = false
            EnterButton.topAnchor.constraint(equalTo: TextField.bottomAnchor, constant: 10).isActive = true
        }
        
        TextField.placeholder = placeholder
        
        EnterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        CancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        PenaltySelector.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.init(name: "Futura", size: 14.0)!], for: .normal)
        // Do any additional setup after loading the view.
    }

    @IBAction func didTapCancel(_ sender: Any) {
        dismiss(animated: true)
    }
    @IBAction func didTapEnter(_ sender: Any) {
        dismiss(animated: true)
        enterAction?()
    }
}
