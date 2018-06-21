//
//  VBNotification.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import UserNotifications

/**
 ### This class is used for configurating and scheduling local notifications for the `Vaktija.ba` application.
 */
class VBNotification
{
    // MARK: Properties
    
    /**
     Array of fire dates settings.
     */
    fileprivate var fireDates = Array<Dictionary<String, AnyObject>>()
    
    // MARK: Public Functions
    
    /**
     Schedules local notifications for prayers's alarms and notifications.
     
     There is limit for iOS and Local Notifications of 64. So, this function should be called whenever user activates app to allways have more prayer times and days covered.
     
     - parameter fireDatesUpdated: Set `true` if fire dates should be genereted again.
     */
    func scheduleLocalNotifications(_ fireDatesUpdated: Bool)
    {
        OperationQueue.main.addOperation
        {
            print("---info---")
            
            let startTimestamp = Date().timeIntervalSince1970
            print("Start scheduling notifications ...")
            
            if #available(iOS 10.0, *)
            {
                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler:
                {
                    (scheduledRequests) in
                    
                    // Create mutable array of requests
                    var requests = scheduledRequests
                    
                    VBNotification.resetSkips()
                    
                    if self.fireDates.isEmpty || fireDatesUpdated
                    {
                        self.fireDates = self.fireDatesSettings()
                    }
                    
                    if self.fireDates.isEmpty
                    {
                        if !requests.isEmpty
                        {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                        }
                        
                        print("Number of canceled notifications: \(requests.count)")
                        print("Number of new notifications: 0")
                        print("Number of scheduled notifications: 0")
                        print("Scheduling of notifications ended.")
                        
                        let duration = Date().timeIntervalSince1970 - startTimestamp
                        print("Duration: \(String(format: "%.4f", duration)) seconds.")
                        print("---end---")
                    }
                    else
                    {
                        self.fireDates.sort
                            {
                                item1, item2 in
                                let date1 = item1["fireDate"] as! Date
                                let date2 = item2["fireDate"] as! Date
                                return date1.compare(date2) == .orderedAscending
                        }
                        
                        var numberOfScheduledRequests = 0
                        var newRequests: [UNNotificationRequest] = []
                        
                        for setting in self.fireDates
                        {
                            let skip = self.checkSkip(forSetting: setting)
                            
                            if !requests.isEmpty
                            {
                                // Check if there is already scheduled same request
                                let request = requests.first(where:
                                {
                                    (request) -> Bool in
                                    
                                    let userInfo = request.content.userInfo
                                    
                                    let settingFireDate = setting["fireDate"] as! Date
                                    let settingType = setting["type"] as! String
                                    let settingPrayer = setting["title"] as! String
                                    
                                    // For the first time app launch after update with this fix is installed, 
                                    // app will crash, because field fire_date does not exists in older versions.
                                    // So, default value is set to be the current date.
                                    let fireDate = userInfo["fire_date"] as? Date ?? Date()
                                    let type = userInfo["alarm_type"] as! String
                                    let prayer = userInfo["prayer"] as! String
                                    
                                    if settingFireDate.compare(fireDate) == .orderedSame && settingType == type && settingPrayer == prayer
                                    {
                                        return true
                                    }
                                    
                                    return false
                                })
                                
                                if let goodRequest = request
                                {
                                    let index = requests.index(of: goodRequest)
                                    
                                    if !skip
                                    {
                                        requests.remove(at: index!)
                                        
                                        numberOfScheduledRequests += 1
                                        if numberOfScheduledRequests == 64
                                        {
                                            break
                                        }
                                    }
                                    
                                    continue
                                }
                            }
                            
                            if skip
                            {
                                continue
                            }
                            
                            let timestamp = Date().timeIntervalSince1970
                            
                            let request = self.createRequest(withIdentifier: String(timestamp), forSetting: setting)
                            newRequests.append(request)
                            
                            numberOfScheduledRequests += 1
                            
                            if numberOfScheduledRequests == 64
                            {
                                break
                            }
                        }
                        
                        if !requests.isEmpty
                        {
                            var identifiers: [String] = []
                            
                            identifiers = requests.map({$0.identifier})
                            
                            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                        }
                        
                        if !newRequests.isEmpty
                        {
                            for request in newRequests
                            {
                                UNUserNotificationCenter.current().add(request, withCompletionHandler:
                                {
                                    (error) in
                                    
                                    if let goodError = error
                                    {
                                        print(goodError.localizedDescription)
                                    }
                                })
                            }
                        }
                        
                        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler:
                        {
                            (scheduledRequests) in
                            
                                print("Number of canceled notifications: \(requests.count)")
                                print("Number of new notifications: \(newRequests.count)")
                                print("Number of scheduled notifications: \(scheduledRequests.count)")
                                print("Scheduling of notifications ended.")
                                
                                let duration = Date().timeIntervalSince1970 - startTimestamp
                                print("Duration: \(String(format: "%.4f", duration)) seconds.")
                                print("---end---")
                        })
                    }
                })
            }
            else
            {
                if var scheduledLocalNotifications = UIApplication.shared.scheduledLocalNotifications
                {
                    VBNotification.resetSkips()
                    
                    if self.fireDates.isEmpty || fireDatesUpdated
                    {
                        self.fireDates = self.fireDatesSettings()
                    }
                    
                    if self.fireDates.isEmpty
                    {
                        if !scheduledLocalNotifications.isEmpty
                        {
                            UIApplication.shared.cancelAllLocalNotifications()
                        }
                        
                        print("Number of canceled notifications: \(scheduledLocalNotifications.count)")
                        print("Number of new notifications: 0")
                        print("Number of scheduled notifications: 0")
                        print("Scheduling of notifications ended.")
                        
                        let duration = Date().timeIntervalSince1970 - startTimestamp
                        print("Duration: \(String(format: "%.4f", duration)) seconds.")
                        print("---end---")
                    }
                    else
                    {
                        self.fireDates.sort
                            {
                                item1, item2 in
                                let date1 = item1["fireDate"] as! Date
                                let date2 = item2["fireDate"] as! Date
                                return date1.compare(date2) == .orderedAscending
                        }
                        
                        var numberOfScheduledNotifications = 0
                        var localNotifications: [UILocalNotification] = []
                        
                        for setting in self.fireDates
                        {
                            let skip = self.checkSkip(forSetting: setting)
                            
                            if !scheduledLocalNotifications.isEmpty
                            {
                                // Check if there is already scheduled same notification
                                let notification = scheduledLocalNotifications.first(where:
                                    {
                                        (notification) -> Bool in
                                        
                                        if let userInfo = notification.userInfo
                                        {
                                            let settingFireDate = setting["fireDate"] as! Date
                                            let settingType = setting["type"] as! String
                                            let settingPrayer = setting["title"] as! String
                                            
                                            // For the first time app launch after update with this fix is installed,
                                            // app will crash, because field fire_date does not exists in older versions.
                                            // So, default value is set to be the current date.
                                            let fireDate = userInfo["fire_date"] as? Date ?? Date()
                                            let type = userInfo["alarm_type"] as! String
                                            let prayer = userInfo["prayer"] as! String
                                            
                                            if settingFireDate.compare(fireDate) == .orderedSame && settingType == type && settingPrayer == prayer
                                            {
                                                return true
                                            }
                                        }
                                        
                                        return false
                                })
                                
                                if let goodNotification = notification
                                {
                                    let index = scheduledLocalNotifications.index(of: goodNotification)
                                    
                                    if !skip
                                    {
                                        scheduledLocalNotifications.remove(at: index!)
                                        
                                        numberOfScheduledNotifications += 1
                                        if numberOfScheduledNotifications == 64
                                        {
                                            break
                                        }
                                    }
                                    
                                    continue
                                }
                            }
                            
                            if skip
                            {
                                continue
                            }
                            
                            let localNotification = self.createLocalNotification(withSetting: setting)
                            localNotifications.append(localNotification)
                            
                            numberOfScheduledNotifications += 1
                            
                            if numberOfScheduledNotifications == 64
                            {
                                break
                            }
                        }
                        
                        if !scheduledLocalNotifications.isEmpty
                        {
                            for localNotification in scheduledLocalNotifications
                            {
                                UIApplication.shared.cancelLocalNotification(localNotification)
                            }
                        }
                        
                        if !localNotifications.isEmpty
                        {
                            for localNotification in localNotifications
                            {
                                UIApplication.shared.scheduleLocalNotification(localNotification)
                            }
                        }
                        
                        print("Number of canceled notifications: \(scheduledLocalNotifications.count)")
                        print("Number of new notifications: \(localNotifications.count)")
                        print("Number of scheduled notifications: \(UIApplication.shared.scheduledLocalNotifications!.count)")
                        print("Scheduling of notifications ended.")
                        
                        let duration = Date().timeIntervalSince1970 - startTimestamp
                        
                        print("Duration: \(String(format: "%.4f", duration)) seconds.")
                        print("---end---")
                    }
                }
            }
        }
    }
    
    /**
     Resets all skips for alarms and notifications.
     */
    class func resetSkips()
    {
        if let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        {
            if var fajrSettings = userDefaults.dictionary(forKey: "fajrSettings")
            {
                var update = false
                let alarmSkip = (fajrSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = fajrSettings["skipAlarmDate"] as! Date
                let notificationSkip = (fajrSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = fajrSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    // Checking skip fire dates for today and tomorrow.
                    // All those fire dates before today are expired and those after tomorrow are imposible to set, so all of their skips should be reset.
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        // All those skip fire dates set before now are expired
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            fajrSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        // Reset skip fire dates before today or after tomorrow
                        fajrSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            fajrSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        fajrSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(fajrSettings, forKey: "fajrSettings")
                }
            }
            
            if var sunriseSettings = userDefaults.dictionary(forKey: "sunriseSettings")
            {
                var update = false
                let alarmSkip = (sunriseSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = sunriseSettings["skipAlarmDate"] as! Date
                let notificationSkip = (sunriseSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = sunriseSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            sunriseSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        sunriseSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            sunriseSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        sunriseSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(sunriseSettings, forKey: "sunriseSettings")
                }
            }
            
            if var dhuhrSettings = userDefaults.dictionary(forKey: "dhuhrSettings")
            {
                var update = false
                let alarmSkip = (dhuhrSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = dhuhrSettings["skipAlarmDate"] as! Date
                let notificationSkip = (dhuhrSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = dhuhrSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            dhuhrSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        dhuhrSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            dhuhrSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        dhuhrSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(dhuhrSettings, forKey: "dhuhrSettings")
                }
            }
            
            if var jumuahSettings = userDefaults.dictionary(forKey: "jumuahSettings")
            {
                var update = false
                let alarmSkip = (jumuahSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = jumuahSettings["skipAlarmDate"] as! Date
                let notificationSkip = (jumuahSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = jumuahSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            jumuahSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        jumuahSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            jumuahSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        jumuahSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(jumuahSettings, forKey: "jumuahSettings")
                }
            }
            
            if var asrSettings = userDefaults.dictionary(forKey: "asrSettings")
            {
                var update = false
                let alarmSkip = (asrSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = asrSettings["skipAlarmDate"] as! Date
                let notificationSkip = (asrSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = asrSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            asrSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        asrSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            asrSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        asrSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(asrSettings, forKey: "asrSettings")
                }
            }
            
            if var maghribSettings = userDefaults.dictionary(forKey: "maghribSettings")
            {
                var update = false
                let alarmSkip = (maghribSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = maghribSettings["skipAlarmDate"] as! Date
                let notificationSkip = (maghribSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = maghribSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            maghribSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        maghribSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            maghribSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        maghribSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(maghribSettings, forKey: "maghribSettings")
                }
            }
            
            if var ishaSettings = userDefaults.dictionary(forKey: "ishaSettings")
            {
                var update = false
                let alarmSkip = (ishaSettings["skipAlarm"] as! NSNumber).boolValue
                let alarmSkipDate = ishaSettings["skipAlarmDate"] as! Date
                let notificationSkip = (ishaSettings["skipNotification"] as! NSNumber).boolValue
                let notificationSkipDate = ishaSettings["skipNotificationDate"] as! Date
                
                if alarmSkip
                {
                    if Calendar.current.isDateInToday(alarmSkipDate)
                    {
                        if alarmSkipDate.compare(Date()) != .orderedDescending
                        {
                            ishaSettings["skipAlarm"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(alarmSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        ishaSettings["skipAlarm"] = false
                        update = true
                    }
                }
                
                if notificationSkip
                {
                    if Calendar.current.isDateInToday(notificationSkipDate)
                    {
                        if notificationSkipDate.compare(Date()) != .orderedDescending
                        {
                            ishaSettings["skipNotification"] = false
                            update = true
                        }
                    }
                    else if Calendar.current.isDateInTomorrow(notificationSkipDate)
                    {
                        // Do not touch fire dates of tomorrow that are set to skip
                    }
                    else
                    {
                        ishaSettings["skipNotification"] = false
                        update = true
                    }
                }
                
                if update
                {
                    userDefaults.set(ishaSettings, forKey: "ishaSettings")
                }
            }
        }
    }
    
    // MARK: Private Functions
    
    /**
     Setups fire date settings for alarms and notifications.
     
     - returns: Array of fire dates settings.
     */
    fileprivate func fireDatesSettings() -> [Dictionary<String, AnyObject>]
    {
        var dateSettings: [Dictionary<String, AnyObject>] = []
        
        // Getting all schedules
        var schedules: [VBSchedule] = []
        let currentDateComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let currentDay = currentDateComponents.day
        let currentMonth = currentDateComponents.month
        let currentYear = currentDateComponents.year
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "(month == %d AND day >= %d) OR month > %d", currentMonth!, currentDay!, currentMonth!)
        schedulesFetchRequest.fetchLimit = 76
        schedulesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true), NSSortDescriptor(key: "day", ascending: true)]
        
        do
        {
            schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as! [VBSchedule]
        }
        catch
        {
            print(error)
        }
        
        if schedules.count < 76
        {
            let newSchedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
            newSchedulesFetchRequest.fetchLimit = 76 - schedules.count
            newSchedulesFetchRequest.sortDescriptors = [NSSortDescriptor(key: "month", ascending: true), NSSortDescriptor(key: "day", ascending: true)]
            
            do
            {
                let newSchedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(newSchedulesFetchRequest) as! [VBSchedule]
                schedules.append(contentsOf: newSchedules)
            }
            catch
            {
                print(error)
            }
        }
        
        if !schedules.isEmpty, let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        {
            let locationId = userDefaults.integer(forKey: "locationId");
            
            for schedule in schedules
            {
                // Getting offset for the schedule
                var offset: VBOffset?
                if locationId != 107
                {
                    let offsetsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBOffset")
                    offsetsFetchRequest.predicate = NSPredicate(format: "month == %d AND locationId == %d", Int(schedule.month), locationId)
                    
                    do
                    {
                        let offsets = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(offsetsFetchRequest) as! [VBOffset]
                        
                        if !offsets.isEmpty
                        {
                            offset = offsets.first
                        }
                    }
                    catch
                    {
                        print(error)
                    }
                }
                
                // Setting alarm and notification fire date for fajr
                if let settings = userDefaults.dictionary(forKey: "fajrSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    var locationOffset = 0
                    if let goodOffset = offset
                    {
                        locationOffset = Int(goodOffset.fajr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.fajr
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let fajr = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Zora", "type": "alarm", "offset": String(alarmOffset), "prayerSettings": "fajrSettings"] as [String : Any]
                            dateSettings.append(fajr as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.fajr
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let fajr = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Zora", "type": "notification", "offset": String(notificationOffset), "prayerSettings": "fajrSettings"] as [String : Any]
                            dateSettings.append(fajr as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
                
                // Setting alarm and notification fire date for sunrise
                if let settings = userDefaults.dictionary(forKey: "sunriseSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    var locationOffset = 0
                    if let goodOffset = offset
                    {
                        locationOffset = Int(goodOffset.fajr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.sunrise
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let sunrise = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Izlazak sunca", "type": "alarm", "offset": String(alarmOffset), "prayerSettings": "sunriseSettings"] as [String : Any]
                            dateSettings.append(sunrise as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.sunrise
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let sunrise = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Izlazak sunca", "type": "notification", "offset": String(notificationOffset), "prayerSettings": "sunriseSettings"] as [String : Any]
                            dateSettings.append(sunrise as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
                
                //Dhuhr and Jumuah case
                var dhuhrAlarmFireDateSettings: Dictionary<String, AnyObject>?
                var dhuhrNotificationFireDateSettings: Dictionary<String, AnyObject>?
                var jumuahAlarmFireDateSettings: Dictionary<String, AnyObject>?
                var jumuahNotificationFireDateSettings: Dictionary<String, AnyObject>?
                
                // Setting alarm and notification fire date for dhuhr
                if let settings = userDefaults.dictionary(forKey: "dhuhrSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    let isStandardDhuhrTime = userDefaults.bool(forKey: "isStandardDhuhrTime")
                    var locationOffset = 0
                    if let goodOffset = offset, !isStandardDhuhrTime
                    {
                        locationOffset = Int(goodOffset.dhuhr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = (isStandardDhuhrTime ? "12:00" : schedule.dhuhr)
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            dhuhrAlarmFireDateSettings = ["prayerDate": prayerDate as AnyObject, "fireDate": fireDate as AnyObject, "title": "Podne" as AnyObject, "type": "alarm" as AnyObject, "offset": String(alarmOffset) as AnyObject, "prayerSettings": "dhuhrSettings" as AnyObject]
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = (isStandardDhuhrTime ? "12:00" : schedule.dhuhr)
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            dhuhrNotificationFireDateSettings = ["prayerDate": prayerDate as AnyObject, "fireDate": fireDate as AnyObject, "title": "Podne" as AnyObject, "type": "notification" as AnyObject, "offset": String(notificationOffset) as AnyObject, "prayerSettings": "dhuhrSettings" as AnyObject]
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
                
                let isJumuahSettingOn = userDefaults.bool(forKey: "isJumuahSettingOn")
                
                if isJumuahSettingOn
                {
                    // Setting alarm and notification fire date for jumuah
                    if let settings = userDefaults.dictionary(forKey: "jumuahSettings")
                    {
                        let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                        let notificationOn = (settings["notification"] as! NSNumber).boolValue
                        let isStandardDhuhrTime = userDefaults.bool(forKey: "isStandardDhuhrTime")
                        var locationOffset = 0
                        if let goodOffset = offset, !isStandardDhuhrTime
                        {
                            locationOffset = Int(goodOffset.dhuhr)
                        }
                        
                        // Setting alarm
                        if alarmOn
                        {
                            let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                            
                            // Getting date components
                            let time = (isStandardDhuhrTime ? "12:00" : schedule.dhuhr)
                            let components = time!.components(separatedBy: ":")
                            
                            var dateComponents = DateComponents()
                            dateComponents.year = currentYear
                            dateComponents.month = Int(schedule.month)
                            dateComponents.day = Int(schedule.day)
                            dateComponents.hour = Int(components.first!)!
                            dateComponents.minute = Int(components.last!)!
                            
                            // Setting fire date
                            if let scheduledDate = Calendar.current.date(from: dateComponents)
                            {
                                let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                                
                                // Adding fire date to return array
                                jumuahAlarmFireDateSettings = ["prayerDate": prayerDate as AnyObject, "fireDate": fireDate as AnyObject, "title": "Džuma" as AnyObject, "type": "alarm" as AnyObject, "offset": String(alarmOffset) as AnyObject, "prayerSettings": "jumuahSettings" as AnyObject]
                                
                                printDateToConsole(fireDate)
                            }
                        }
                        
                        // Setting notification
                        if notificationOn
                        {
                            let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                            
                            // Getting date components
                            let time = (isStandardDhuhrTime ? "12:00" : schedule.dhuhr)
                            let components = time!.components(separatedBy: ":")
                            
                            var dateComponents = DateComponents()
                            dateComponents.year = currentYear
                            dateComponents.month = Int(schedule.month)
                            dateComponents.day = Int(schedule.day)
                            dateComponents.hour = Int(components.first!)!
                            dateComponents.minute = Int(components.last!)!
                            
                            // Setting fire date
                            if let scheduledDate = Calendar.current.date(from: dateComponents)
                            {
                                let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                                
                                // Adding fire date to return array
                                jumuahNotificationFireDateSettings = ["prayerDate": prayerDate as AnyObject, "fireDate": fireDate as AnyObject, "title": "Džuma" as AnyObject, "type": "notification" as AnyObject, "offset": String(notificationOffset) as AnyObject, "prayerSettings": "jumuahSettings" as AnyObject]
                                
                                printDateToConsole(fireDate)
                            }
                        }
                    }
                }
                
                // Check if jumuah, then add jumuah setting to return array
                // If not add dhuhr settings
                // Dhuhr settings should be added only if non of alarm and notification for jumuah are not set
                
                if isJumuahSettingOn
                {
                    // If jumuah alarm and notification are not set, set dhuhr if configured
                    if jumuahAlarmFireDateSettings == nil && jumuahNotificationFireDateSettings == nil
                    {
                        if dhuhrAlarmFireDateSettings != nil
                        {
                            dateSettings.append(dhuhrAlarmFireDateSettings!)
                        }
                        
                        if dhuhrNotificationFireDateSettings != nil
                        {
                            dateSettings.append(dhuhrNotificationFireDateSettings!)
                        }
                    }
                    else
                    {
                        let jumuahFireDate = (jumuahAlarmFireDateSettings != nil ? jumuahAlarmFireDateSettings!["fireDate"] : jumuahNotificationFireDateSettings!["fireDate"]) as! Date
                        let isJumuah = VBPrayer.isJumuah(jumuahFireDate)
                        
                        if isJumuah
                        {
                            if jumuahAlarmFireDateSettings != nil
                            {
                                dateSettings.append(jumuahAlarmFireDateSettings!)
                            }
                            
                            if jumuahNotificationFireDateSettings != nil
                            {
                                dateSettings.append(jumuahNotificationFireDateSettings!)
                            }
                        }
                        else
                        {
                            if dhuhrAlarmFireDateSettings != nil
                            {
                                dateSettings.append(dhuhrAlarmFireDateSettings!)
                            }
                            
                            if dhuhrNotificationFireDateSettings != nil
                            {
                                dateSettings.append(dhuhrNotificationFireDateSettings!)
                            }
                        }
                    }
                }
                else
                {
                    if dhuhrAlarmFireDateSettings != nil
                    {
                        dateSettings.append(dhuhrAlarmFireDateSettings!)
                    }
                    
                    if dhuhrNotificationFireDateSettings != nil
                    {
                        dateSettings.append(dhuhrNotificationFireDateSettings!)
                    }
                }
                
                // Setting alarm and notification fire date for asr
                if let settings = userDefaults.dictionary(forKey: "asrSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    var locationOffset = 0
                    if let goodOffset = offset
                    {
                        locationOffset = Int(goodOffset.asr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.asr
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let asr = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Ikindija", "type": "alarm", "offset": String(alarmOffset), "prayerSettings": "asrSettings"] as [String : Any]
                            dateSettings.append(asr as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.asr
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let asr = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Ikindija", "type": "notification", "offset": String(notificationOffset), "prayerSettings": "asrSettings"] as [String : Any]
                            dateSettings.append(asr as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
                
                // Setting alarm and notification fire date for maghrib
                if let settings = userDefaults.dictionary(forKey: "maghribSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    var locationOffset = 0
                    if let goodOffset = offset
                    {
                        locationOffset = Int(goodOffset.asr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.maghrib
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let maghrib = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Akšam", "type": "alarm", "offset": String(alarmOffset), "prayerSettings": "maghribSettings"] as [String : Any]
                            dateSettings.append(maghrib as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.maghrib
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let maghrib = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Akšam", "type": "notification", "offset": String(notificationOffset), "prayerSettings": "maghribSettings"] as [String : Any]
                            dateSettings.append(maghrib as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
                
                // Setting alarm and notification fire date for isha
                if let settings = userDefaults.dictionary(forKey: "ishaSettings")
                {
                    let alarmOn = (settings["alarm"] as! NSNumber).boolValue
                    let notificationOn = (settings["notification"] as! NSNumber).boolValue
                    var locationOffset = 0
                    if let goodOffset = offset
                    {
                        locationOffset = Int(goodOffset.asr)
                    }
                    
                    // Setting alarm
                    if alarmOn
                    {
                        let alarmOffset = (settings["alarmOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.isha
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: alarmOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let isha = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Jacija", "type": "alarm", "offset": String(alarmOffset), "prayerSettings": "ishaSettings"] as [String : Any]
                            dateSettings.append(isha as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                    
                    // Setting notification
                    if notificationOn
                    {
                        let notificationOffset = (settings["notificationOffset"] as! NSNumber).intValue
                        
                        // Getting date components
                        let time = schedule.isha
                        let components = time!.components(separatedBy: ":")
                        
                        var dateComponents = DateComponents()
                        dateComponents.year = currentYear
                        dateComponents.month = Int(schedule.month)
                        dateComponents.day = Int(schedule.day)
                        dateComponents.hour = Int(components.first!)!
                        dateComponents.minute = Int(components.last!)!
                        
                        // Setting fire date
                        if let scheduledDate = Calendar.current.date(from: dateComponents)
                        {
                            let (prayerDate, fireDate) = fireDateWithOffsets(scheduledDate, userOffset: notificationOffset, locationOffset: locationOffset)
                            
                            // Adding fire date to return array
                            let isha = ["prayerDate": prayerDate, "fireDate": fireDate, "title": "Jacija", "type": "notification", "offset": String(notificationOffset), "prayerSettings": "ishaSettings"] as [String : Any]
                            dateSettings.append(isha as [String : AnyObject])
                            
                            printDateToConsole(fireDate)
                        }
                    }
                }
            }
        }
        
        return dateSettings
    }
    
    /**
     Creates fire date with given date, user offset and location offset.
     
     - parameter scheduledDate:  Original date from schedule table.
     - parameter userOffset:     Offset set by user.
     - parameter locationOffset: Offset by location.
     
     - returns: Tuple with prayer and fire date.
     */
    fileprivate func fireDateWithOffsets(_ scheduledDate: Date, userOffset: Int, locationOffset: Int) -> (Date, Date)
    {
        var returnFireDate = scheduledDate
        var returnPrayerDate = scheduledDate
        
        // Adding location offset
        returnFireDate = Calendar.current.date(byAdding: .minute, value: locationOffset, to: returnFireDate)!
        returnPrayerDate = Calendar.current.date(byAdding: .minute, value: locationOffset, to: returnPrayerDate)!
        
        // Adding user offset
        returnFireDate = Calendar.current.date(byAdding: .minute, value: -userOffset, to: returnFireDate)!
        
        // Adding day light saving offset
        // For Fire Date
        let isDaylightSavingTimeForFireDate = Calendar.current.timeZone.isDaylightSavingTime(for: returnFireDate)
        if isDaylightSavingTimeForFireDate
        {
            returnFireDate = Calendar.current.date(byAdding: .hour, value: 1, to: returnFireDate)!
        }
        // For Prayer Date
        let isDaylightSavingTimeForPrayerDate = Calendar.current.timeZone.isDaylightSavingTime(for: returnPrayerDate)
        if isDaylightSavingTimeForPrayerDate
        {
            returnPrayerDate = Calendar.current.date(byAdding: .hour, value: 1, to: returnPrayerDate)!
        }
        
        // Adding year offset
        let now = Date()
        // For Fire Date
        if returnFireDate.compare(now) == .orderedAscending
        {
            returnFireDate = Calendar.current.date(byAdding: .year, value: 1, to: returnFireDate)!
            
            // When added 1 year to fire date
            // again check is needed for day light saving time
            let isDaylightSavingTimeForNewFireDate = Calendar.current.timeZone.isDaylightSavingTime(for: returnFireDate)
            
            // If both check are not equal some corrections are needed
            if isDaylightSavingTimeForFireDate != isDaylightSavingTimeForNewFireDate
            {
                // If it was winter saving time for old check (current year)
                // and summer saving time for new check (next year)
                // add 1 hour to fire date
                if !isDaylightSavingTimeForFireDate && isDaylightSavingTimeForNewFireDate
                {
                    returnFireDate = Calendar.current.date(byAdding: .hour, value: 1, to: returnFireDate)!
                }
                // If it was summer saving time for old check (current year)
                // and winter saving time for new check (next year)
                // remove 1 hour from fire date
                else
                {
                    returnFireDate = Calendar.current.date(byAdding: .hour, value: -1, to: returnFireDate)!
                }
            }
        }
        // For Prayer Date
        if returnPrayerDate.compare(now) == .orderedAscending
        {
            returnPrayerDate = Calendar.current.date(byAdding: .year, value: 1, to: returnPrayerDate)!
            
            // When added 1 year to prayer date
            // again check is needed for day light saving time
            let isDaylightSavingTimeForNewPrayerDate = Calendar.current.timeZone.isDaylightSavingTime(for: returnPrayerDate)
            
            // If both check are not equal some corrections are needed
            if isDaylightSavingTimeForPrayerDate != isDaylightSavingTimeForNewPrayerDate
            {
                // If it was winter saving time for old check (current year)
                // and summer saving time for new check (next year)
                // add 1 hour to prayer date
                if !isDaylightSavingTimeForPrayerDate && isDaylightSavingTimeForNewPrayerDate
                {
                    returnPrayerDate = Calendar.current.date(byAdding: .hour, value: 1, to: returnPrayerDate)!
                }
                    // If it was summer saving time for old check (current year)
                    // and winter saving time for new check (next year)
                    // remove 1 hour from prayer date
                else
                {
                    returnPrayerDate = Calendar.current.date(byAdding: .hour, value: -1, to: returnPrayerDate)!
                }
            }
        }
        
        return (returnPrayerDate, returnFireDate)
    }
    
    fileprivate func checkSkip(forSetting setting: [String: AnyObject]) -> Bool
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let fireDate = setting["fireDate"] as! Date
        let type = setting["type"] as! String
        
        if Calendar.current.isDateInToday(fireDate)
        {
            let prayerSettingsString = setting["prayerSettings"] as! String
            if let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsString)
            {
                let skip = (prayerSettings[(type == "alarm" ? "skipAlarm" : "skipNotification")] as! NSNumber).boolValue
                
                if skip
                {
                    let skipDate = prayerSettings[(type == "alarm" ? "skipAlarmDate" : "skipNotificationDate")] as? Date
                    
                    if Calendar.current.isDateInToday(skipDate!)
                    {
                        return true
                    }
                }
            }
        }
        else if Calendar.current.isDateInTomorrow(fireDate)
        {
            let prayerSettingsString = setting["prayerSettings"] as! String
            if let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsString)
            {
                let skip = (prayerSettings[(type == "alarm" ? "skipAlarm" : "skipNotification")] as! NSNumber).boolValue
                
                if skip
                {
                    let skipDate = prayerSettings[(type == "alarm" ? "skipAlarmDate" : "skipNotificationDate")] as? Date
                    
                    if Calendar.current.isDateInTomorrow(skipDate!)
                    {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
    @available(iOS 10.0, *)
    fileprivate func createRequest(withIdentifier identifier: String, forSetting setting: [String: AnyObject]) -> UNNotificationRequest
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let prayerDate = setting["prayerDate"] as! Date
        let fireDate = setting["fireDate"] as! Date
        let prayer = setting["title"] as! String
        let type = setting["type"] as! String
        let offset = setting["offset"] as! String
        
        self.printDateToConsole(fireDate)
        
        let alertTitle = (type == "alarm" ? "Alarm" : "Notifikacija") + " za '" + prayer + "'"
        let alertBody = "'" + prayer + "' nastaje za " + offset + " minuta."
        let soundName = userDefaults!.string(forKey: type + "Ringtone")! + ".mp3"
        let userInfo = ["alarm_type": type, "prayer": prayer, "prayer_date": prayerDate, "fire_date": fireDate] as [String : Any]
        
        let content = UNMutableNotificationContent()
        
        content.title = alertTitle
        content.body = alertBody
        content.sound = UNNotificationSound(named: soundName)
        content.userInfo = userInfo
        
        let fireDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: fireDateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        return request
    }
    
    @available(iOS, deprecated: 10)
    fileprivate func createLocalNotification(withSetting setting: [String: AnyObject]) -> UILocalNotification
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let prayerDate = setting["prayerDate"] as! Date
        let fireDate = setting["fireDate"] as! Date
        let prayer = setting["title"] as! String
        let type = setting["type"] as! String
        let offset = setting["offset"] as! String
        
        self.printDateToConsole(fireDate)
        
        let alertTitle = (type == "alarm" ? "Alarm" : "Notifikacija") + " za '" + prayer + "'"
        let alertBody = "'" + prayer + "' nastaje za " + offset + " minuta."
        let soundName = userDefaults!.string(forKey: type + "Ringtone")! + ".mp3"
        let userInfo = ["alarm_type": type, "prayer": prayer, "prayer_date": prayerDate, "fire_date": fireDate] as [String : Any]
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = fireDate
        localNotification.alertTitle = alertTitle
        localNotification.alertBody = alertBody
        
        localNotification.soundName = soundName
        localNotification.userInfo = userInfo
        
        return localNotification
    }
    
    /**
     Prints pretty formated date.
     
     - parameter date: Date to print.
     */
    fileprivate func printDateToConsole(_ date: Date)
    {
        // Printing to console
        /*let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        print(dateFormatter.string(from: date))*/
    }
}
