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
    var count = 0
    
    @IBOutlet var BigView: UIView!
    @IBOutlet weak var TextField: UITextField!
    @IBOutlet weak var EnterButton: UIButton!
    @IBOutlet weak var AddSolveView: UIView!
    @IBOutlet weak var PenaltySelector: UISegmentedControl!
    @IBOutlet weak var PenaltyConstraint: NSLayoutConstraint!
    @IBOutlet weak var CancelButton: UIButton!
    
    @IBOutlet weak var AddSolveTitle: UILabel!
    @IBOutlet weak var AlertView: UIView!
    @IBOutlet weak var HeightConstraint: NSLayoutConstraint!
    
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
        
        /*if(ViewController.deviceName.contains("iPad") || ViewController.deviceName == "x86_64")
        {
            HeightConstraint.isActive = false
            
            let newHeight =
            AlertView.heightAnchor.constraint(equalTo: BigView.heightAnchor, multiplier: 0.35)
            newHeight.priority = UILayoutPriority(rawValue: 750)
            newHeight.isActive = true
        }*/
        
        
        TextField.adjustsFontSizeToFitWidth = true
        EnterButton.titleLabel?.adjustsFontSizeToFitWidth = true
        CancelButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidLayoutSubviews() {
        print("view did layout subviews")
        
        if(count < 2) // only need to do this "twice"
        {
            if count == 1 // do this only on second time this method is called
            {
                print("count \(count)")
                TextField.font = ViewController.fontToFitHeight(view: TextField, multiplier: 0.85, name: "Futura")
                TextField.adjustsFontSizeToFitWidth = true
                CancelButton.titleLabel?.font = ViewController.fontToFitHeight(view: CancelButton, multiplier: 1.0, name: "Futura")
                EnterButton.titleLabel?.font = ViewController.fontToFitHeight(view: EnterButton, multiplier: 1.0, name: "Futura")
                
                PenaltySelector.setTitleTextAttributes([NSAttributedString.Key.font: ViewController.fontToFitHeight(view: PenaltySelector, multiplier: 0.7, name: "Futura")], for: .normal)
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
