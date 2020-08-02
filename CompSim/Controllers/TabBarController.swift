//
//  TabBarController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/21/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//
import UIKit


class TabBarController: UITabBarController {
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let tabBarHeight: CGFloat = 70.0
        var tabFrame = tabBar.frame
        tabFrame.size.height = tabBarHeight
        tabFrame.origin.y = self.view.frame.size.height - tabBarHeight
        self.tabBar.frame = tabFrame
        
        UITabBarItem.appearance().titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -6)
        UITabBarItem.appearance()
        .setTitleTextAttributes(
            [NSAttributedString.Key.font: HomeViewController.fontToFitHeight(view: UIView(frame: CGRect(x: 0, y: 0, width: 5, height: tabBarHeight)), multiplier: 0.3, name: "Lato-Black")],
        for: .normal)
        
        /*
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
         */
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if bestSingleTransition || bestAverageTransition || bestMoTransition || currentMoTransition
        {
            self.selectedIndex = 1
        }
        else
        {
            self.selectedIndex = 0
        }

        // Do any additional setup after loading the view.
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
