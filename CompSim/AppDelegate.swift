//
//  AppDelegate.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    
    // keys
    static let darkMode = "darkMode"
    static let cuber = "cuber"
    static let ao5 = "ao5"
    static let mo3 = "mo3"
    static let bo3 = "bo3"
    static let timing = "timing"
    static let inspection = "inspection"
    static let holdingTime = "holdingTime"
    static let event = "event"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("entered background")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveSettings()
    }
    
    func saveSettings()
    {
        print("setting to \(ViewController.darkMode)")
        
        UserDefaults.standard.set(ViewController.darkMode, forKey: AppDelegate.darkMode)
        UserDefaults.standard.set(ViewController.cuber, forKey: AppDelegate.cuber)
        UserDefaults.standard.set(ViewController.ao5, forKey: AppDelegate.ao5)
        UserDefaults.standard.set(ViewController.mo3, forKey: AppDelegate.mo3)
        UserDefaults.standard.set(ViewController.bo3, forKey: AppDelegate.bo3)
        UserDefaults.standard.set(ViewController.timing, forKey: AppDelegate.timing)
        UserDefaults.standard.set(ViewController.inspection, forKey: AppDelegate.inspection)
        UserDefaults.standard.set(ViewController.holdingTime, forKey: AppDelegate.holdingTime)
        //UserDefaults.standard.set(ViewController.mySession.scrambler.myEvent, forKey: AppDelegate.event)
    }

//    // MARK: UISceneSession Lifecycle
//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//            // Called when a new scene session is being created.
//            // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//            // Called when the user discards a scene session.
//            // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//            // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }

}

