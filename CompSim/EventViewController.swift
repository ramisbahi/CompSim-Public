//
//  EventViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 8/4/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit

class EventViewController: UIViewController {
    
    @IBOutlet var eventCollection: [UIButton]!
    
    @IBOutlet weak var ScrambleTypeButton: UIButton!
    
    @IBAction func handleSelection(_ sender: UIButton) // clicked select
    {
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        eventCollection.forEach { (button) in
            button.isHidden = true
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(false)
    }
    
    enum Events: String
    {
        case twoCube = "2x2x2"
        case threeCube = "3x3x3"
        case fourCube = "4x4x4"
        case fiveCube = "5x5x5"
        case sixCube = "6x6x6"
        case sevenCube = "7x7x7"
        case pyra = "Pyraminx"
        case mega = "Megaminx"
        case sq1 = "Square-1"
        case skewb = "Skewb"
        case clock = "Clock"
    }
    
    @IBAction func eventTapped(_ sender: UIButton) {
        
        eventCollection.forEach { (button) in
            UIView.animate(withDuration: 0.3, animations: {
                button.isHidden = !button.isHidden
                self.view.layoutIfNeeded()
            })
        }
        
        guard let title = sender.currentTitle, let event = Events(rawValue: title) else
        {
            return // doesn't have title
        }
        
        ScrambleTypeButton.setTitle("Scramble Type: \(title)", for: .normal)
        
        switch event
        {
        case .twoCube:
            ViewController.scrambler.doEvent(event: 0)
        case .threeCube:
            ViewController.scrambler.doEvent(event: 1)
        case .fourCube:
            ViewController.scrambler.doEvent(event: 2)
        case .fiveCube:
            ViewController.scrambler.doEvent(event: 3)
        case .sixCube:
            ViewController.scrambler.doEvent(event: 4)
        case .sevenCube:
            ViewController.scrambler.doEvent(event: 5)
        case .pyra:
            ViewController.scrambler.doEvent(event: 6)
        case .mega:
            ViewController.scrambler.doEvent(event: 7)
        case .sq1:
            ViewController.scrambler.doEvent(event: 8)
        case .skewb:
            ViewController.scrambler.doEvent(event: 9)
        case .clock:
            ViewController.scrambler.doEvent(event: 10)
        default:
            print("op")
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
