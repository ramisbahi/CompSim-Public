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
    
    @IBOutlet weak var TextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TextField.becomeFirstResponder()

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
