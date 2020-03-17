//
//  DrawScrambleViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 2/24/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//


import UIKit

class DrawScrambleViewController: UIViewController {

    
    @IBOutlet weak var Collection1: UICollectionView!
    @IBOutlet weak var Collection2: UICollectionView!
    @IBOutlet weak var Collection3: UICollectionView!
    @IBOutlet weak var Collection4: UICollectionView!
    @IBOutlet weak var Collection5: UICollectionView!
    @IBOutlet weak var Collection6: UICollectionView!
    
    
    override func viewDidLoad()
    {
        let currentWidth = Int(Collection1.frame.size.width)
    
        
        Collection1.widthAnchor.constraint(equalToConstant: CGFloat(currentWidth - currentWidth % 3)).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(false)
        
        
        drawSide(side: Collection1, colors: Array(ViewController.mySession.scrambler.drawScramble[0..<9]))
        drawSide(side: Collection2, colors: Array(ViewController.mySession.scrambler.drawScramble[9..<18]))
        drawSide(side: Collection3, colors: Array(ViewController.mySession.scrambler.drawScramble[18..<27]))
        drawSide(side: Collection4, colors: Array(ViewController.mySession.scrambler.drawScramble[27..<36]))
        drawSide(side: Collection5, colors: Array(ViewController.mySession.scrambler.drawScramble[36..<45]))
        drawSide(side: Collection6, colors: Array(ViewController.mySession.scrambler.drawScramble[45..<54]))
    }
    
    func drawSide(side: UIView, colors: [String])
    {
        let colorMap: [String: UIColor] = ["R" : .red, "B" : .blue, "Y" : .yellow, "G" : .green, "W" : .white, "O" : .orange]
        
        let squareWidth = Double(side.frame.size.width / 3.0) - 1
        
        for i in 0..<9
        {
            let color: UIColor = colorMap[colors[i]]!
            let xPos: Double = squareWidth * Double(i % 3)
            let yPos: Double = squareWidth * Double(i / 3) 
            
            
            let newView = UIView(frame: CGRect(x: xPos, y: yPos, width: squareWidth, height: squareWidth))
            newView.backgroundColor = color
            newView.layer.borderWidth = 1
            newView.layer.borderColor = UIColor.black.cgColor
            side.addSubview(newView)
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
