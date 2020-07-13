//
//  AddSolveAlertViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 12/30/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class InputAlertViewController: UIViewController {
    
    var enterAction: (() -> Void)?
    var myTitle = String()
    var keyboardType = 0 // keyboard: 0 = decimal, 1 = text
    var placeholder = String()
    var count = 0
    
    @IBOutlet var BigView: UIView!
    @IBOutlet weak var TextField: UITextField!
    @IBOutlet weak var EnterButton: UIButton!
    @IBOutlet weak var AddSolveView: UIView!
    @IBOutlet weak var CancelButton: UIButton!
    
    @IBOutlet weak var AddSolveTitle: UILabel!
    @IBOutlet weak var AlertView: UIView!
    @IBOutlet weak var HeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TextField.becomeFirstResponder()
        
        AddSolveTitle.text = myTitle
        if #available(iOS 11.0, *) {
            AddSolveView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        } else {
            // Fallback on earlier versions
        }
        
    
        if(HomeViewController.darkMode)
        {
            AddSolveView.backgroundColor = HomeViewController.darkPurpleColor()
        }
        
        if(keyboardType == 1)
        {
            TextField.keyboardType = .default
        }
        
        EnterButton.topAnchor.constraint(equalTo: TextField.bottomAnchor, constant: 10).isActive = true
        
        TextField.placeholder = placeholder
        
        TextField.adjustsFontSizeToFitWidth = true
        EnterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        CancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        
        if(count < 2) // only need to do this "twice"
        {
            if count == 1 // do this only on second time this method is called
            {
                TextField.font = HomeViewController.fontToFitHeight(view: TextField, multiplier: 0.85, name: "Lato-Black")
                TextField.adjustsFontSizeToFitWidth = true
                EnterButton.titleLabel?.font = HomeViewController.fontToFitHeight(view: EnterButton, multiplier: 1.0, name: "Lato-Black")
            }
            count += 1
        }
    }

    @IBAction func didTapCancel(_ sender: Any) {
        dismiss(animated: true)
    }
    @IBAction func didTapEnter(_ sender: Any) {
        dismiss(animated: true)
        enterAction?()
    }
}
