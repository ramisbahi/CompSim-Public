//
//  WalkthroughViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/20/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

class InsetLabel: UILabel
{
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets.init(top: 0, left: 10, bottom: 0, right: 10)
        super.drawText(in: rect.inset(by: insets))
    }
}

// bubble up, x location proportion, y location proportion, width proportion, height proportion, mirrored

let bubbles: [[[Any]]] = [
                            [ // page 0
                                [false, 0.35, 0.565, 0.5, 0.25, true],
                                [false, 0.55, 0.022, 0.4, 0.13, false], // these
                                [false, 0.05, 0.43, 0.46, 0.324, false], // two
                                [false, 0.45, 0.3, 0.45, 0.35, false],
                                [false, 0.15, 0.42 , 0.4, 0.224, true],
                                [false, 0.17, 0.18, 0.4, 0.224, true],// these
                                [true, 0.47, 0.542, 0.4, 0.25, false], // two
                                [true, 0.05, 0.0444, 0.4, 0.23, false],
                                [true, 0.41, 0.048, 0.28, 0.2, false],
                                [true, 0.62, 0.0444, 0.34, 0.1, true]
                            ],

                            [ // page 1
                                [false, 0.03, 0.23, 0.4, 0.324, false],
                                [false, 0.56, 0.445, 0.42, 0.24, true],
                                [true, 0.45, 0.13, 0.3, 0.12, false],
                                [true, 0.35, 0.21, 0.45, 0.25, true],
                                [true, 0.15, 0.168, 0.3, 0.24, false], // these
                                [true, 0.55, 0.168, 0.3, 0.24, true], // two
                                [true, 0.0555, 0.0444, 0.28, 0.16, false],
                                [true, 0.6, 0.0444, 0.34, 0.2, true]
                            ],
                            
                            [ // page 2
                                [true, 0.35, 0.125, 0.4, 0.3, false],
                                [false, 0.17, 0.05, 0.3, 0.21, false],
                                [false, 0.53, 0.05, 0.3, 0.21, true],
                                [false, 0.15, 0.305, 0.45, 0.284, true],
                                [false, 0.56, 0.5, 0.35, 0.13, false]
                            ],
                            
                            [ // page 3
                                [true, 0.5, 0.055, 0.3, 0.2, false],
                                [true, 0.19, 0.15, 0.4, 0.18, true],
                                [false, 0.05, 0.01, 0.35, 0.18, false],
                                [false, 0.05, 0.165, 0.275, 0.17, true],
                                [false, 0.34, 0.165, 0.275, 0.17, true],
                                [false, 0.67, 0.165, 0.275, 0.17, false],
                                [false, 0.05, 0.12, 0.42, 0.29, true],
                                [false, 0.5, 0.213, 0.47, 0.3, true],
                                [false, 0.52, 0.335, 0.47, 0.25, false],
                                [false, 0.34, 0.405, 0.47, 0.25, true],
                                [false, 0.55, 0.56, 0.44, 0.17, false],
                                [false, 0.06, 0.628, 0.39, 0.18, false],
                                [false, 0.55, 0.628, 0.39, 0.18, true]
                            ]
                        ]

// bubble up, x location proportion, y location proportion, width proportion, height proportion, mirrored

class WalkthroughViewController: UIViewController {

    @IBOutlet weak var ImageView: UIImageView!
    
    var index: Int = 0
    var bubbleIndex: Int = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ImageView.backgroundColor = .red
        ImageView.tintColor = .red
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
            bubbleIndex = -1
        }
        
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if bubbleIndex == -1
        {
            addTint()
            addPrompt()
        }
    }
    
    func addTint()
    {
        let tintView = UIView(frame: CGRect(x: ImageView.frame.minX, y: ImageView.frame.minY, width: ImageView.frame.width, height: ImageView.frame.height))
        tintView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(respondToTap)))
        tintView.backgroundColor = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
        self.view.addSubview(tintView)
    }
    
    func addPrompt()
    {
        let widthProp: CGFloat = 0.9
        let heightProp: CGFloat = 0.15
        
        let promptLabel = InsetLabel(frame: CGRect(x: ImageView.frame.minX + ImageView.frame.width * (1-widthProp) / 2.0, y: ImageView.frame.minY + ImageView.frame.height * (1-heightProp) / 2.0, width: ImageView.frame.width * widthProp, height: ImageView.frame.height*heightProp))
        
        if bubbleIndex >= bubbles[index].count
        {
            promptLabel.text = index == 3 ? "Walkthrough complete!" : "Swipe to continue. →"
        }
        else
        {
            promptLabel.text = index == 0 ? "Tap to begin." : "Tap to continue."
        }
        
        promptLabel.font = UIFont(name: "Lato-Black", size: 100.0)
        promptLabel.baselineAdjustment = .alignCenters
        promptLabel.textColor = HomeViewController.darkBlueColor()
        promptLabel.textAlignment = .center
        promptLabel.adjustsFontSizeToFitWidth = true
        promptLabel.tintColor = UIColor(displayP3Red: 247, green: 218, blue: 149, alpha: 1.0)
        promptLabel.backgroundColor = UIColor(displayP3Red: 247/255, green: 218/255, blue: 149/255, alpha: 1.0)
        promptLabel.layer.cornerRadius = 6.0
        promptLabel.layer.masksToBounds = true
        self.view.addSubview(promptLabel)
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
        
        
        bubbleIndex += 1
        if bubbleIndex >= bubbles[index].count
        {
            addTint()
            addPrompt()
        }
        else // if bubbleIndex < bubbles[index].count
        {
            showBubble()
            
            if index == 0 && (bubbleIndex == 1 || bubbleIndex == 5) || index == 1 && bubbleIndex == 4 || index == 2 && bubbleIndex == 1 || index == 3 && (bubbleIndex == 3 || bubbleIndex == 11)
            {
                bubbleIndex += 1
                showBubble()
                if index == 3 && bubbleIndex == 4
                {
                    bubbleIndex += 1
                    showBubble()
                }
            }
        }
        
    }
    
    func showBubble()
    {
        let attrText = NSLocalizedString("Help_\(index)_\(bubbleIndex)", comment: "")
        createBubbleAndText(bubbleUp: bubbles[index][bubbleIndex][0] as! Bool, xProp: CGFloat(bubbles[index][bubbleIndex][1] as! Double), yProp: CGFloat(bubbles[index][bubbleIndex][2] as! Double), widthProp: CGFloat(bubbles[index][bubbleIndex][3] as! Double), heightProp: CGFloat(bubbles[index][bubbleIndex][4] as! Double), text: attrText, mirrored: bubbles[index][bubbleIndex][5] as! Bool)
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
        
        let textXStart = xStart + width * 0.077
        let textYStart = yStart + height * yStartCoeff
        let textWidth = width * 0.846
        let textHeight = height * 0.666
        let label = UILabel(frame: CGRect(x: textXStart, y: textYStart, width: textWidth, height: textHeight))
        
        label.font = UIFont(name: "Lato-Black", size: 50.0)
        label.textColor = HomeViewController.darkBlueColor()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.text = text
        
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
