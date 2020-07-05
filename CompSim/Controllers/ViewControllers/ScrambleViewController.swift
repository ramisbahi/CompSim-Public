//
//  ScrambleViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/4/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

class ScrambleViewController: UIViewController {
    
    @IBOutlet weak var scrambleLabel: UILabel!
    var scrambleText: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrambleLabel.text = scrambleText

        // Do any additional setup after loading the view.
    }
    
    func updateScrambleLabel(scramble: String)
    {
        scrambleLabel.text = scramble
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
