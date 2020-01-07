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
    static let sessionName = "sessionName"
    static let timerUpdate = "timerUpdate"
    
    lazy var realm = try! Realm()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 2,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 2) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        retrieveSessions()
        return true
    }
    
    
    func retrieveSessions()
    {
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        let results = realm.objects(Session.self)
        if results.count > 0 // has a session saved
        {
            ViewController.allSessions.removeAll()
            ViewController.mySession = results[0]
            for result in results
            {
                if(result.name == UserDefaults.standard.string(forKey: AppDelegate.sessionName)) // last session left on
                {
                    ViewController.mySession = result
                }
                ViewController.mySession.updateScrambler()
                ViewController.allSessions[result.name] = result
                print("created \(result.name) session")
            }
        }
        else
        {
            addFirstSession()
        }
    }
    
    func addFirstSession()
    {
        let session = ViewController.mySession
        try! realm.write
        {
            realm.add(session)
        }
    }
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        print("entered background")
        if ViewController.mySession.currentIndex == 5 // temporary solution
        {
            try! realm.write
            {
                ViewController.mySession.reset()
            }
        }
        saveSettings()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
         
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        if ViewController.mySession.currentIndex == 5 // temporary solution
        {
            try! realm.write
            {
                ViewController.mySession.reset()
            }
        }
        saveSettings()
    }
    
    func saveSettings()
    {
        print("setting to \(ViewController.darkMode)")
        
        let defaults = UserDefaults.standard
        
        defaults.set(ViewController.darkMode, forKey: AppDelegate.darkMode)
        defaults.set(ViewController.cuber, forKey: AppDelegate.cuber)
        defaults.set(ViewController.ao5, forKey: AppDelegate.ao5)
        defaults.set(ViewController.mo3, forKey: AppDelegate.mo3)
        defaults.set(ViewController.bo3, forKey: AppDelegate.bo3)
        defaults.set(ViewController.timing, forKey: AppDelegate.timing)
        defaults.set(ViewController.inspection, forKey: AppDelegate.inspection)
        defaults.set(ViewController.holdingTime, forKey: AppDelegate.holdingTime)
        defaults.set(ViewController.mySession.scrambler.myEvent, forKey: AppDelegate.event)
        defaults.set(ViewController.mySession.name, forKey: AppDelegate.sessionName)
        defaults.set(ViewController.timerUpdate, forKey: AppDelegate.timerUpdate)
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

