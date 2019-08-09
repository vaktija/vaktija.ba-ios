//
//  AppDelegate.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import AVFoundation
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate
{
    var window: UIWindow?
    
    // MARK: - Application's Life Cycle
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        // Override point for customization after application launch.
        
        if #available(iOS 10.0, *)
        {
            UNUserNotificationCenter.current().delegate = self
        }
        
        if let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        {
            let settingsVersion = userDefaults.object(forKey: "settingsVersion") as? NSNumber ?? NSNumber(value: 0 as Int)
            if settingsVersion.intValue == 0
            {
                if settingsVersion.intValue == 0
                {
                    preloadData()
                }
                
                //Setting up default settings of the app
                userDefaults.set(1, forKey: "settingsVersion")
                userDefaults.set(107, forKey: "locationId")
                userDefaults.set(true, forKey: "showTodayWidget")
                userDefaults.set(false, forKey: "showAllPrayerTimes")
                userDefaults.set("Notifikacija 1_notification", forKey: "notificationRingtone")
                userDefaults.set("Alarm 1_alarm", forKey: "alarmRingtone")
                userDefaults.set(true, forKey: "isStandardDhuhrTime")
                userDefaults.set(true, forKey: "isJumuahSettingOn")
                userDefaults.set(false, forKey: "showDate")
                
                userDefaults.set(["title": "zora", "alarm": false, "alarmOffset": 45, "skipAlarm": false, "skipAlarmDate": Date(), "notification": false, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "fajrSettings")
                
                userDefaults.set(["title": "izlazak sunca", "alarm": false, "alarmOffset": 45, "skipAlarm": false, "skipAlarmDate": Date(), "notification": false, "notificationOffset": 35, "skipNotification": false, "skipNotificationDate": Date()], forKey: "sunriseSettings")
                
                userDefaults.set(["title": "podne", "alarm": false, "alarmOffset": 30, "skipAlarm": false, "skipAlarmDate": Date(), "notification": true, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "dhuhrSettings")
                
                userDefaults.set(["title": "džuma", "alarm": false, "alarmOffset": 30, "skipAlarm": false, "skipAlarmDate": Date(), "notification": true, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "jumuahSettings")
                
                userDefaults.set(["title": "ikindija", "alarm": false, "alarmOffset": 30, "skipAlarm": false, "skipAlarmDate": Date(), "notification": true, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "asrSettings")
                
                userDefaults.set(["title": "akšam", "alarm": false, "alarmOffset": 30, "skipAlarm": false, "skipAlarmDate": Date(), "notification": true, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "maghribSettings")
                
                userDefaults.set(["title": "jacija", "alarm": false, "alarmOffset": 30, "skipAlarm": false, "skipAlarmDate": Date(), "notification": true, "notificationOffset": 15, "skipNotification": false, "skipNotificationDate": Date()], forKey: "ishaSettings")
            }
        }
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication)
    {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication)
    {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication)
    {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication)
    {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication)
    {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        VBCoreDataStack.sharedInstance.saveContext()
    }
    
    // MARK: - Local Notifications
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void)
    {
        completionHandler()
    }

    @available(iOS, deprecated: 10)
    func application(_ application: UIApplication, didReceive notification: UILocalNotification)
    {
        if UIApplication.shared.applicationState == .active
        {
            if let userInfo = notification.userInfo, let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            {
                let type = userInfo["alarm_type"] as? String ?? "notification"
                
                var soundID: SystemSoundID = 0
                let soundName = userDefaults.string(forKey: type + "Ringtone")!
                
                if let ref: CFURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), soundName as CFString, "mp3" as CFString, nil)
                {
                    AudioServicesCreateSystemSoundID(ref, &soundID)
                    AudioServicesPlaySystemSound(soundID)
                }
                
                let alertController = UIAlertController(title: notification.alertTitle, message: notification.alertBody, preferredStyle: .actionSheet)
                
                alertController.addAction(UIAlertAction(title: "Uredu", style: .destructive, handler:
                    {
                        (_) in
                        
                        AudioServicesDisposeSystemSoundID(soundID)
                }));
                
                let navigationController = window?.rootViewController as! UINavigationController
                if let topViewController = navigationController.topViewController
                {
                    if topViewController.isKind(of: SchedulesViewController.self)
                    {
                        topViewController.viewWillAppear(true)
                    }
                }
                
                if UIDevice.current.userInterfaceIdiom == .pad
                {
                    let navigationBar = navigationController.navigationBar
                    alertController.modalPresentationStyle = .popover
                    alertController.popoverPresentationController?.sourceView = navigationBar
                    alertController.popoverPresentationController?.sourceRect = navigationBar.frame
                }
                
                navigationController.present(alertController, animated: true, completion: nil)
            }
        }
        
        VBNotification().scheduleLocalNotifications(true)
    }
    
    // MARK: - Private Functions
    
    fileprivate func parseCSV(_ contentsOfURL: URL, encoding: String.Encoding) -> [[String]]?
    {
        // Load the CSV file and parse it
        let delimiter = ","
        var items:[[String]]?
        let content:String?
        
        do
        {
            try content = String(contentsOf: contentsOfURL, encoding: encoding)
            
            if let goodContent = content
            {
                items = []
                let lines:[String] = goodContent.components(separatedBy: CharacterSet.newlines) as [String]
                
                for line in lines
                {
                    var values:[String] = []
                    if line != ""
                    {
                        // For a line with double quotes
                        // we use Scanner to perform the parsing
                        if line.range(of: "\"") != nil
                        {
                            var textToScan:String = line
                            var value:NSString?
                            var textScanner:Scanner = Scanner(string: textToScan)
                            while textScanner.string != ""
                            {
                                if (textScanner.string as NSString).substring(to: 1) == "\""
                                {
                                    textScanner.scanLocation += 1
                                    textScanner.scanUpTo("\"", into: &value)
                                    textScanner.scanLocation += 1
                                }
                                else
                                {
                                    textScanner.scanUpTo(delimiter, into: &value)
                                }
                                
                                // Store the value into the values array
                                values.append(value! as String)
                                
                                // Retrieve the unscanned remainder of the string
                                if textScanner.scanLocation < textScanner.string.count
                                {
                                    textToScan = (textScanner.string as NSString).substring(from: textScanner.scanLocation + 1)
                                }
                                else
                                {
                                    textToScan = ""
                                }
                                textScanner = Scanner(string: textToScan)
                            }
                            
                            // For a line without double quotes, we can simply separate the string
                            // by using the delimiter (e.g. comma)
                        }
                        else
                        {
                            values = line.components(separatedBy: delimiter)
                        }
                        
                        // Add it to the items array
                        items?.append(values)
                    }
                }
            }
        }
        catch
        {
            print(error)
        }
        
        return items
    }
    
    fileprivate func preloadData()
    {
        // Preloading locations
        if let contentsOfURL = Bundle.main.url(forResource: "locations", withExtension: "csv")
        {
            // Remove all the locations before preloading
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
            
            do
            {
                let items: [VBLocation]
                try items = VBCoreDataStack.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [VBLocation]
                
                for item in items
                {
                    VBCoreDataStack.sharedInstance.managedObjectContext.delete(item)
                }
            }
            catch
            {
                print(error)
            }
            
            if let items = parseCSV(contentsOfURL, encoding: String.Encoding.utf8)
            {
                for item in items
                {
                    let location = NSEntityDescription.insertNewObject(forEntityName: "VBLocation", into: VBCoreDataStack.sharedInstance.managedObjectContext) as! VBLocation
                    
                    location.id = (item[0] as NSString).longLongValue
                    location.location = item[1]
                    location.weight = (item[2] as NSString).longLongValue
                    location.region = item[3]
                    
                    do
                    {
                        try VBCoreDataStack.sharedInstance.managedObjectContext.save()
                    }
                    catch
                    {
                        print(error);
                    }
                }
            }
        }
        
        // Preloading schedules
        if let contentsOfURL = Bundle.main.url(forResource: "schedule", withExtension: "csv")
        {
            // Remove all the schedules before preloading
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
            
            do
            {
                let items: [VBSchedule]
                try items = VBCoreDataStack.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [VBSchedule]
                
                for item in items
                {
                    VBCoreDataStack.sharedInstance.managedObjectContext.delete(item)
                }
            }
            catch
            {
                print(error)
            }
            
            if let items = parseCSV(contentsOfURL, encoding: String.Encoding.utf8)
            {
                for item in items
                {
                    let schedule = NSEntityDescription.insertNewObject(forEntityName: "VBSchedule", into: VBCoreDataStack.sharedInstance.managedObjectContext) as! VBSchedule
                    
                    schedule.id = (item[0] as NSString).longLongValue
                    schedule.month = (item[1] as NSString).longLongValue
                    schedule.day = (item[2] as NSString).longLongValue
                    schedule.fajr = item[3]
                    schedule.sunrise = item[4]
                    schedule.dhuhr = item[5]
                    schedule.asr = item[6]
                    schedule.maghrib = item[7]
                    schedule.isha = item[8]
                    
                    do
                    {
                        try VBCoreDataStack.sharedInstance.managedObjectContext.save()
                    }
                    catch
                    {
                        print(error);
                    }
                }
            }
        }
        
        // Preloading offsets
        if let contentsOfURL = Bundle.main.url(forResource: "offset", withExtension: "csv")
        {
            // Remove all the offsets before preloading
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBOffset")
            
            do
            {
                let items: [VBOffset]
                try items = VBCoreDataStack.sharedInstance.managedObjectContext.fetch(fetchRequest) as! [VBOffset]
                
                for item in items
                {
                    VBCoreDataStack.sharedInstance.managedObjectContext.delete(item)
                }
            }
            catch
            {
                print(error)
            }
            
            if let items = parseCSV(contentsOfURL, encoding: String.Encoding.utf8)
            {
                for item in items
                {
                    let offset = NSEntityDescription.insertNewObject(forEntityName: "VBOffset", into: VBCoreDataStack.sharedInstance.managedObjectContext) as! VBOffset
                    
                    offset.id = (item[0] as NSString).longLongValue
                    offset.month = (item[1] as NSString).longLongValue
                    offset.locationId = (item[2] as NSString).longLongValue
                    offset.fajr = (item[3] as NSString).longLongValue
                    offset.dhuhr = (item[4] as NSString).longLongValue
                    offset.asr = (item[5] as NSString).longLongValue
                    
                    do
                    {
                        try VBCoreDataStack.sharedInstance.managedObjectContext.save()
                    }
                    catch
                    {
                        print(error);
                    }
                }
            }
        }
    }
}
