//
//  HelpWalkthroughViewController.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/20/20.
//  Copyright © 2020 Rami Sbahi. All rights reserved.
//

import UIKit

class HelpWalkthroughViewController: UIViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentViewControllerIndex
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int
    {
        return 4
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        let currentViewController = viewController as? WalkthroughViewController
        
        guard let currentIndex = currentViewController?.index else
        {
            return nil
        }
        
        currentViewControllerIndex = currentIndex
        
        if currentIndex == 0
        {
            return nil
        }
        
        guard let previousViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController
        else
        {
            return nil
        }
        previousViewController.index = currentIndex - 1
        return previousViewController
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        let currentViewController = viewController as? WalkthroughViewController
        
        guard let currentIndex = currentViewController?.index else
        {
            return nil
        }
        
        currentViewControllerIndex = currentIndex
        
        if currentIndex == 3
        {
            return nil
        }
        
        guard let previousViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController
        else
        {
            return nil
        }
        previousViewController.index = currentIndex + 1
        return previousViewController
    }
    

    @IBOutlet weak var contentView: UIView!
    
    var currentViewControllerIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = nil
        
        configurePageViewController()
        
        // Do any additional setup after loading the view.
    }
    
    func configurePageViewController()
    {
        guard let pageViewController = storyboard?.instantiateViewController(withIdentifier: "PageViewController") as? UIPageViewController
        else
        {
            return
        }
        
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        self.addChild(pageViewController)
        pageViewController.didMove(toParent: self)
        
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(pageViewController.view)
        
        let views: [String: Any] = ["pageView": pageViewController.view!]
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pageView]-0-|", options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: views))
        
        guard let startingViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController
        else
        {
            return
        }
        startingViewController.index = 0
        
        pageViewController.setViewControllers([startingViewController], direction: .forward, animated: true)
    }

    @IBAction func BackPressed(_ sender: Any) {
        slideLeftSegue()
    }
    
    func slideLeftSegue()
    {
        let transition:CATransition = CATransition()
        transition.duration = 0.3
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = CATransitionType.push
        transition.subtype = CATransitionSubtype.fromLeft
    
    
        self.navigationController!.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.popViewController(animated: true)
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
