//
//  EventViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/4/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {
    
    @IBOutlet weak var EventChooser: UISegmentedControl!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(false)
        if EventChooser.selectedSegmentIndex == 0
        {
            ViewController.scrambler.doEvent(event: true)
            
        }
        else
        {
            ViewController.scrambler.doEvent(event: false)
            
        }
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
