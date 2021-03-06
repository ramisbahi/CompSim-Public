//
//  AppDelegate.swift
//  CompSim
//
//  Created by Rami Sbahi on 7/15/19.
//  Copyright © 2019 Rami Sbahi. All rights reserved.
//

import UIKit
import RealmSwift


// get device name
extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}


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
    static let hasSet = "hasSet"
    static let totalAverages = "totalAverages"
    
    lazy var realm = try! Realm()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        
        print("scale: \(UIScreen.main.scale)")
        
        
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor.init(displayP3Red: 0/255, green: 51/255, blue: 89/255, alpha: 0.7)
        UIPageControl.appearance().pageIndicatorTintColor =
            UIColor.init(displayP3Red: 196/255, green: 196/255, blue: 196/255, alpha: 1.0)

        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 3,

            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 3) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
            })
        
        
        
        HomeViewController.deviceName = UIDevice.current.modelName

        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config

        // Now that we've told Realm how to handle the schema change, opening the file
        // will automatically perform the migration
        retrieveSessions()
        
        TimerViewController.initializeFormatters()
        
        application.isIdleTimerDisabled = true
        
        return true
    }
    
    
    func retrieveSessions()
    {
        print(Realm.Configuration.defaultConfiguration.fileURL!)
        let results = realm.objects(Session.self)
        if results.count > 0 // has a session saved
        {
            HomeViewController.allSessions.removeAll()
            HomeViewController.mySession = results[0] // will change to last session, just in case
            for result in results
            {
                if(result.name == UserDefaults.standard.string(forKey: AppDelegate.sessionName)) // last session left on
                {
                    HomeViewController.mySession = result
                    HomeViewController.mySession.updateScrambler()
                }
                HomeViewController.allSessions.append(result)
                //print("created \(result.name) session")
            }
        }
        else
        {
            addFirstSession()
        }
    }
    
    func addFirstSession()
    {
        let session = HomeViewController.mySession
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
        if HomeViewController.mySession.currentIndex == 5 // temporary solution
        {
            try! realm.write
            {
                HomeViewController.mySession.reset()
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
        if HomeViewController.mySession.currentIndex == 5 // temporary solution
        {
            try! realm.write
            {
                HomeViewController.mySession.reset()
            }
        }
        saveSettings()
    }
    
    func saveSettings()
    {
        bestMoTransition = false
        currentMoTransition = false
        
        let defaults = UserDefaults.standard
        
        defaults.set(HomeViewController.darkMode, forKey: AppDelegate.darkMode)
        defaults.set(HomeViewController.cuber, forKey: AppDelegate.cuber)
        defaults.set(HomeViewController.timing, forKey: AppDelegate.timing)
        defaults.set(HomeViewController.inspection, forKey: AppDelegate.inspection)
        defaults.set(HomeViewController.holdingTime, forKey: AppDelegate.holdingTime)
        defaults.set(HomeViewController.mySession.scrambler.myEvent, forKey: AppDelegate.event)
        defaults.set(HomeViewController.mySession.name, forKey: AppDelegate.sessionName)
        defaults.set(HomeViewController.timerUpdate, forKey: AppDelegate.timerUpdate)
        defaults.set(true, forKey: AppDelegate.hasSet)
        defaults.set(HomeViewController.totalAverages, forKey: AppDelegate.totalAverages)
        
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

