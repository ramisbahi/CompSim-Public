//
//  TabBarController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/21/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//
import UIKit

extension UITabBar {
    static let height: CGFloat = 20.0

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let window = UIApplication.shared.keyWindow else {
            return super.sizeThatFits(size)
        }
        var sizeThatFits = super.sizeThatFits(size)
        if #available(iOS 11.0, *) {
            sizeThatFits.height = UITabBar.height + window.safeAreaInsets.bottom
        } else {
            sizeThatFits.height = UITabBar.height
        }
        return sizeThatFits
    }
}

class TabBarController: UITabBarController {
    
    func hasTopNotch() -> Bool {
        if #available(iOS 11.0, tvOS 11.0, *) {
          return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 20
        }
        return false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let topNotch = hasTopNotch()
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        
        let tabBarHeight: CGFloat = topNotch && !isIPad ? 102.0 : 70.0
        
        var tabFrame = tabBar.frame
        tabFrame.size.height = tabBarHeight
        tabFrame.origin.y = self.view.frame.size.height - tabBarHeight
        self.tabBar.frame = tabFrame
 
        let verticalUIOffset = UIOffset(horizontal: 0, vertical: topNotch ? 0 : -6)
        UITabBarItem.appearance().titlePositionAdjustment = verticalUIOffset
    
        UITabBarItem.appearance()
        .setTitleTextAttributes(
            [NSAttributedString.Key.font: HomeViewController.fontToFitHeight(view: UIView(frame: CGRect(x: 0, y: 0, width: 5, height: tabBarHeight)), multiplier: topNotch && !isIPad ? 0.24 : 0.29, name: "Lato-Black")],
        for: .normal)
        
        //UITabBarItem.appearance().imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: -5, right: 0)
        
        //self.tabBar.invalidateIntrinsicContentSize()
        /*
        UITabBar.appearance().layer.borderWidth = 0.0
        UITabBar.appearance().clipsToBounds = true
         */
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBar.invalidateIntrinsicContentSize()
        tabBar.superview?.setNeedsLayout()
        tabBar.superview?.layoutSubviews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //(self.tabBar as? ESTabBar)?.itemCustomPositioning = .fillIncludeSeparator
        //self.tabBar.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        
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
