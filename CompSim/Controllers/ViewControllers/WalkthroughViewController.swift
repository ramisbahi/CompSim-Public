//
//  WalkthroughViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/20/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

// bubble up, x location proportion, y location proportion, width proportion, height proportion, mirrored

let bubbles: [[[Any]]] = [
                            [ // page 0
                                [true, 0.0555, 0.0444, 0.4, 0.16, false],
                                [true, 0.41, 0.048, 0.25, 0.14, false],
                                [true, 0.62, 0.0444, 0.34, 0.19, true],
                                [false, 0.55, 0.022, 0.4, 0.13, false],
                                [false, 0.56, 0.2, 0.4, 0.224, false],
                                [false, 0.15, 0.27, 0.4, 0.224, true],
                                [false, 0.55, 0.4, 0.35, 0.25, false],
                                [false, 0.15, 0.42 , 0.4, 0.224, true],
                                [false, 0.11, 0.53, 0.4, 0.224, false],
                                [false, 0.45, 0.68, 0.4, 0.15, true]
                            ],

                            [ // page 1
                                [true, 0.0555, 0.0444, 0.3, 0.16, false],
                                [true, 0.6, 0.0444, 0.34, 0.2, true],
                                [true, 0.45, 0.13, 0.25, 0.1, false],
                                [false, 0.15, 0.01, 0.3, 0.14, false],
                                [false, 0.55, 0.01, 0.3, 0.14, true],
                                [true, 0.4, 0.21, 0.4, 0.2, true],
                                [false, 0.3, 0.365, 0.4, 0.224, false],
                                [false, 0.56, 0.445, 0.42, 0.24, true]
                            ],
                            
                            [ // page 2
                                [false, 0.35, 0.005, 0.5, 0.1, false],
                                [false, 0.17, 0.09, 0.3, 0.12, false],
                                [false, 0.53, 0.09, 0.3, 0.12, true],
                                [false, 0.2, 0.365, 0.4, 0.224, true],
                                [false, 0.56, 0.5, 0.35, 0.13, false]
                            ],
                            
                            [ // page 3
                                [true, 0.5, 0.055, 0.3, 0.17, false],
                                [true, 0.19, 0.15, 0.4, 0.14, true],
                                [false, 0.39, 0.06, 0.4, 0.18, false],
                                [false, 0.05, 0.23, 0.27, 0.1, true],
                                [false, 0.35, 0.23, 0.27, 0.1, true],
                                [false, 0.65, 0.23, 0.27, 0.1, false],
                                [false, 0.15, 0.205, 0.32, 0.2, true],
                                [false, 0.57, 0.305, 0.4, 0.2, true],
                                [false, 0.57, 0.465, 0.4, 0.12, false],
                                [false, 0.57, 0.55, 0.4, 0.12, true],
                                [false, 0.57, 0.63, 0.4, 0.12, false],
                                [false, 0.16, 0.69, 0.3, 0.12, false],
                                [false, 0.54, 0.69, 0.3, 0.12, true]
                            ]
                        ]

// bubble up, x location proportion, y location proportion, width proportion, height proportion, mirrored

class WalkthroughViewController: UIViewController {

    @IBOutlet weak var ImageView: UIImageView!
    
    var index: Int = 0
    var bubbleIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ImageView.image = UIImage(named: "screen\(index)")
        // Do any additional setup after loading the view.
        ImageView.layer.borderColor = HomeViewController.darkMode ? UIColor.white.cgColor : HomeViewController.darkBlueColor().cgColor
        ImageView.layer.borderWidth = 1.0
        
        ImageView.isUserInteractionEnabled = true
        ImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(respondToTap)))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if bubbleIndex >= bubbles[index].count
        {
            bubbleIndex = 0
        }
    }
    
    @objc func respondToTap(_ recognizer: UITapGestureRecognizer)
    {
        for subView in self.view.subviews
        {
            if subView != ImageView
            {
                subView.removeFromSuperview()
            }
        }
        
        if bubbleIndex < bubbles[index].count
        {
            let attrText = NSLocalizedString("Help_\(index)_\(bubbleIndex)", comment: "")
            createBubbleAndText(bubbleUp: bubbles[index][bubbleIndex][0] as! Bool, xProp: CGFloat(bubbles[index][bubbleIndex][1] as! Double), yProp: CGFloat(bubbles[index][bubbleIndex][2] as! Double), widthProp: CGFloat(bubbles[index][bubbleIndex][3] as! Double), heightProp: CGFloat(bubbles[index][bubbleIndex][4] as! Double), text: attrText, mirrored: bubbles[index][bubbleIndex][5] as! Bool)
            bubbleIndex += 1
        }
    }
    
    
    func createBubbleAndText(bubbleUp: Bool, xProp: CGFloat, yProp: CGFloat, widthProp: CGFloat, heightProp: CGFloat, text: String, mirrored: Bool)
    {
        var bubble = UIImage(named: bubbleUp ? "bubble_up" : "bubble_down")
        if mirrored
        {
            bubble =  UIImage(cgImage: (bubble?.cgImage)!, scale: 1.0, orientation: .upMirrored)
        }
        let bubbleImageView = UIImageView(image: bubble!)

        let xStart = ImageView.frame.minX + ImageView.frame.size.width * xProp
        let yStart = ImageView.frame.minY + ImageView.frame.size.height * yProp
        let width = ImageView.frame.size.width * widthProp
        let height = ImageView.frame.size.height * heightProp
        bubbleImageView.frame = CGRect(x: xStart, y: yStart, width: width, height: height)
        
        let yStartCoeff: CGFloat = bubbleUp ? 0.285 : 0.04
        
        print("y start", yStartCoeff)
        
        let textXStart = xStart + width * 0.077
        let textYStart = yStart + height * yStartCoeff
        let textWidth = width * 0.846
        let textHeight = height * 0.666
        let label = UILabel(frame: CGRect(x: textXStart, y: textYStart, width: textWidth, height: textHeight))
        
        label.font = UIFont(name: "Lato-Black", size: 12.0)
        label.textColor = HomeViewController.darkBlueColor()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.text = text
        //label.backgroundColor = .orange
        
        view.addSubview(bubbleImageView)
        view.addSubview(label)
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
