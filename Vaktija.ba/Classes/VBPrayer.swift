//
//  VBPrayer.swift
//  Vaktija.ba
//
//

import CoreData

/**
 ### This class is used for setting and getting data of prayer's time schedules.
 */
class VBPrayer
{
    /**
     Represents prayer times.
     
     - Fajr:    Time interval from the moment when light becomes visible to the sunrise.
     - Sunrise: Moment when sun rises in the horizont.
     - Dhuhr:   Time interval from the noon to, middle of the time interval form the noon to dusk.
     - Asr:     Time interval from, middle of the time interval from noon to dusk, until dusk.
     - Maghrib: Time interval from dusk to moment when light is no longer visible.
     - Isha:    Time interval from moment when light is not visible to the moment when it is visible.
     - Jumuah:  Moment of the noon for every Friday.
     */
    enum PrayerTime: String
    {
        /**
         Time interval from the moment when light becomes visible to the sunrise
        */
        case Fajr = "fajr"
        /**
         Moment when sun rises in the horizont
        */
        case Sunrise = "sunrise"
        /**
         Time interval from the noon to, middle of the time interval form the noon to dusk.
         */
        case Dhuhr = "dhuhr"
        /**
         Time interval from, middle of the time interval from noon to dusk, until dusk
         */
        case Asr = "asr"
        /**
         Time interval from dusk to moment when light is no longer visible.
         */
        case Maghrib = "maghrib"
        /**
         Time interval from moment when light is not visible to the moment when it is visible.
         */
        case Isha = "isha"
        /**
         Moment of the noon for every Friday.
         */
        case Jumuah = "jumuah"
    }
    
    /**
     Types of alarms.
     
     - Alarm:        Alarm is notification with longer sound, intended to wake up, announcement.
     - Notification: It is notification with short sound, intended for reminding, like reminder.
     */
    enum AlarmType: String
    {
        /**
         Alarm is notification with longer sound, intended to wake up, announcement.
         */
        case Alarm = "alarm"
        /**
         It is notification with short sound, intended for reminding, like reminder.
         */
        case Notification = "notification"
    }
    
    /**
     Used for getting prayer for given index.
     
     - parameter index: Positive integer between 0 and 6.
     
     - returns: Prayer time.
     */
    class func prayerTimeForIndex(_ index: Int, schedule: VBSchedule) -> PrayerTime
    {
        if index == 0
        {
            return .Fajr
        }
        else if index == 1
        {
            return .Sunrise
        }
        else if index == 2
        {
            var dateComponents = Calendar.current.dateComponents([.year], from: Date())
            dateComponents.month = Int(schedule.month)
            dateComponents.day = Int(schedule.day)
            let date = Calendar.current.date(from: dateComponents)
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            if userDefaults!.bool(forKey: "isJumuahSettingOn") && isJumuah(date!)
            {
                return .Jumuah
            }
            else
            {
                return .Dhuhr
            }
        }
        else if index == 3
        {
            return .Asr
        }
        else if index == 4
        {
            return .Maghrib
        }
        else if index == 5
        {
            return .Isha
        }
        
        return .Fajr
    }
    
    /**
     Returns localized prayer name for given prayer time.
     
     - parameter prayerTime: Prayer time.
     
     - returns: Localized prayer name.
     */
    class func prayerName(forPrayerTime prayerTime: PrayerTime) -> String
    {
        if prayerTime == .Fajr
        {
            return "zora"
        }
        else if prayerTime == .Sunrise
        {
            return "izlazak sunca"
        }
        else if prayerTime == .Dhuhr
        {
            return "podne"
        }
        else if prayerTime == .Asr
        {
            return "ikindija"
        }
        else if prayerTime == .Maghrib
        {
            return "akšam"
        }
        else if prayerTime == .Isha
        {
            return "jacija"
        }
        else if prayerTime == .Jumuah
        {
            return "džuma"
        }
        
        return "zora"
    }
    
    /**
     Gets prayer's time (as time of the day, in hours and minutes) in format `hours:minutes`.
     
     - parameter schedule:   VBSchedule object for given day, with all prayers data.
     - parameter prayerTime: Prayer time for which time of the day is requested.
     
     - returns: Prayer's time of the day, in format `hours:minutes`.
     */
    class func prayerScheduleTime(fromSchedule schedule:VBSchedule, prayerTime: PrayerTime) -> String!
    {
        if prayerTime == .Fajr
        {
            return schedule.fajr!
        }
        else if prayerTime == .Sunrise
        {
            return schedule.sunrise!
        }
        else if prayerTime == .Dhuhr || prayerTime == .Jumuah
        {
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            if userDefaults!.bool(forKey: "isStandardDhuhrTime")
            {
                return "12:00"
            }
            else
            {
                return schedule.dhuhr!
            }
        }
        else if prayerTime == .Asr
        {
            return schedule.asr!
        }
        else if prayerTime == .Maghrib
        {
            return schedule.maghrib!
        }
        else if prayerTime == .Isha
        {
            return schedule.isha!
        }
        
        return nil
    }
    
    /**
     Used for getting settings key name for given prayer time.
     
     - parameter prayerTime: Prayer time.
     
     - returns: Returns settings key name for given prayer time.
     */
    class func prayerSettingsKey(forPrayerTime prayerTime: PrayerTime, schedule: VBSchedule) -> String
    {
        if prayerTime == .Fajr
        {
            return "fajrSettings"
        }
        else if prayerTime == .Sunrise
        {
            return "sunriseSettings"
        }
        else if prayerTime == .Dhuhr || prayerTime == .Jumuah
        {
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            let isJumuahSettingsOn = userDefaults!.bool(forKey: "isJumuahSettingOn")
            
            var dateComponents = Calendar.current.dateComponents([.year], from: Date())
            dateComponents.month = Int(schedule.month)
            dateComponents.day = Int(schedule.day)
            let date = Calendar.current.date(from: dateComponents)
            
            if isJumuahSettingsOn && isJumuah(date!)
            {
                return "jumuahSettings"
            }
            else
            {
                return "dhuhrSettings"
            }
        }
        else if prayerTime == .Asr
        {
            return "asrSettings"
        }
        else if prayerTime == .Maghrib
        {
            return "maghribSettings"
        }
        else
        {
            return "ishaSettings"
        }
    }
    
    /**
     Detects if the given date is Friday (Jumuah).
     
     - parameter date: Date to check.
     
     - returns: Returns boolean value `true` if the given date is Friday, `false` if not.
     */
    class func isJumuah(_ date: Date) -> Bool
    {
        let weekday = Calendar(identifier: Calendar.Identifier.gregorian).component(.weekday, from: date)
        
        return weekday == 6
    }
    
    /**
     Calculates seconds for given time in format `hours:minutes` and prayer time.
     
     Calculation is done by getting seconds from time string `hours:minutes`, offset for given location, checking if standard dhuhr time setting is on.
     
     - parameter time:   Time string in format `hours:minutes`.
     - parameter prayer: Prayer time.
     
     - returns: Seconds for given time and prayer time.
     */
    class func getSeconds(fromTime time: String, prayer: PrayerTime, schedule: VBSchedule) -> Int
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let components = time.components(separatedBy: ":")
        var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: Date())
        dateComponents.month = Int(schedule.month)
        dateComponents.day = Int(schedule.day)
        
        var seconds = Int(0)
        let month = dateComponents.month
        var offset: VBOffset?
        
        if userDefaults!.integer(forKey: "locationId") == 107
        {
            offset = nil
        }
        else
        {
            let offsetsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBOffset")
            offsetsFetchRequest.predicate = NSPredicate(format: "month == %d AND locationId == %d", month!, userDefaults!.integer(forKey: "locationId"))
            
            do
            {
                let offsets = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(offsetsFetchRequest) as! [VBOffset]
                
                if offsets.count > 0
                {
                    offset = offsets.first
                }
            }
            catch
            {
                print(error)
            }
        }
        
        if let hours = Int(components.first!)
        {
            seconds = seconds + hours*3600
        }
        
        if let minutes = Int(components.last!)
        {
            seconds = seconds + minutes*60
        }
        
        if let goodOffset = offset
        {
            if prayer == .Fajr || prayer == .Sunrise
            {
                seconds = seconds + Int(goodOffset.fajr)*60
            }
            else if prayer == .Dhuhr || prayer == .Jumuah
            {
                if userDefaults!.bool(forKey: "isStandardDhuhrTime")
                {
                    seconds = 12*3600
                }
                else
                {
                    seconds = seconds + Int(goodOffset.dhuhr)*60
                }
            }
            else if prayer == .Asr || prayer == .Maghrib || prayer == .Isha
            {
                seconds = seconds + Int(goodOffset.asr)*60
            }
        }
        else
        {
            if prayer == .Dhuhr || prayer == .Jumuah
            {
                if userDefaults!.bool(forKey: "isStandardDhuhrTime")
                {
                    seconds = 12*3600
                }
            }
        }
        
        if Calendar.current.timeZone.isDaylightSavingTime(for: Calendar.current.date(from: dateComponents)!)
        {
            seconds = seconds + 3600
        }
        
        return seconds
    }
    
    /**
     Gets current prayer time and its index for given day.
     
     - parameter schedule: VBSchedule object which contains all prayer times for given day.
     
     - returns: Tuple with prayer time and index [0 - 6].
     */
    class func currentPrayerTimeAndIndex(forSchedule schedule: VBSchedule) -> (PrayerTime, Int)
    {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
        let currentTimeStamp = Int(dateComponents.hour!*3600 + dateComponents.minute!*60 + dateComponents.second!)
        
        let fajr = getSeconds(fromTime: schedule.fajr!, prayer: .Fajr, schedule:schedule)
        let sunrise = getSeconds(fromTime: schedule.sunrise!, prayer: .Sunrise, schedule:schedule)
        let dhuhr = getSeconds(fromTime: schedule.dhuhr!, prayer: .Dhuhr, schedule:schedule)
        let asr = getSeconds(fromTime: schedule.asr!, prayer: .Asr, schedule:schedule)
        let maghrib = getSeconds(fromTime: schedule.maghrib!, prayer: .Maghrib, schedule:schedule)
        let isha = getSeconds(fromTime: schedule.isha!, prayer: .Isha, schedule:schedule)
        
        if currentTimeStamp < fajr
        {
            return (.Isha, 5) // current schedule is isha after midnight
        }
        else if currentTimeStamp < sunrise
        {
            return (.Fajr, 0) // current schedule is fajr
        }
        else if currentTimeStamp < dhuhr
        {
            return (.Sunrise, 1) // current schedule is sunrise
        }
        else if currentTimeStamp < asr
        {
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            let isJ = userDefaults!.bool(forKey: "isJumuahSettingOn") && isJumuah(Date())
            
            return ((isJ ? .Jumuah : .Dhuhr), 2) // current schedule is dhuhr
        }
        else if currentTimeStamp < maghrib
        {
            return (.Asr, 3) // current schedule is asr
        }
        else if currentTimeStamp < isha
        {
            return (.Maghrib, 4) // current schedule is maghrib
        }
        else
        {
            return (.Isha, 5) // current schedule is isha before midnight
        }
    }
    
    /**
     Prepares prayer time for displaying in GUI.
     
     - parameter schedule:   VBSchedule object which contains all prayer times for given day.
     - parameter prayerTime: Prayer time for which time will be displayed in GUI.
     
     - returns: Prepared string of time for displaying in GUI.
     */
    class func displayPrayerScheduleTime(forSchedule schedule: VBSchedule, prayerTime: PrayerTime) -> String
    {
        if let time = prayerScheduleTime(fromSchedule: schedule, prayerTime: prayerTime)
        {
            let seconds = getSeconds(fromTime: time, prayer: prayerTime, schedule:schedule)
            var components = time.components(separatedBy: ":")
            var hours = Int(seconds/3600)
            let minutes = Int((seconds%3600)/60)
            
            if hours < 10
            {
                components[0] = "0" + String(hours)
            }
            else if hours >= 24
            {
                hours = hours - 24
                
                if hours < 10
                {
                    components[0] = "0" + String(hours)
                }
                else
                {
                    components[0] = String(hours)
                }
            }
            else
            {
                components[0] = String(hours)
            }
            
            if minutes < 10
            {
                components[1] = "0" + String(minutes)
            }
            else
            {
                components[1] = String(minutes)
            }
            
            return components.joined(separator: ":")
        }
        
        return "--:--"
    }
    
    /**
     Determines how much time has left till next prayer.
     
     - parameter schedule:   VBSchedule object which contains all prayer times for given day.
     - parameter prayerTime: Next prayer time.
     
     - returns: Array of strings with time components: hours, minutes, seconds; prepared for display in GUI.
     */
    class func remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule schedule: VBSchedule, prayerTime: PrayerTime) -> [String]
    {
        if let time = prayerScheduleTime(fromSchedule: schedule, prayerTime: prayerTime)
        {
            let prayerTimeSeconds =  getSeconds(fromTime: time, prayer: prayerTime, schedule:schedule)
            
            let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
            let currentTimeSeconds = dateComponents.hour!*3600 + dateComponents.minute!*60 + dateComponents.second!
            
            var delta = 0
            if prayerTimeSeconds < currentTimeSeconds
            {
                delta = prayerTimeSeconds + 86400 - currentTimeSeconds
            }
            else
            {
                delta = prayerTimeSeconds - currentTimeSeconds
            }
            
            let hours = delta/3600
            let minutes = (delta%3600)/60
            let seconds = delta%60
            var components: [String] = [String(hours), String(minutes), String(seconds)]
            
            if hours < 10
            {
                components[0] = "0\(hours)"
            }
            
            if minutes < 10
            {
                components[1] = "0\(minutes)"
            }
            
            if seconds < 10
            {
                components[2] = "0\(seconds)"
            }
            
            return components
        }
        
        return Array(repeating: "00", count: 3)
    }
    
    /**
     Setups skip for alarm or notification.
     
     - parameter schedule:   VBSchedule object which contains all prayer times for given day.
     - parameter prayerTime: Prayer time for which skip will be done.
     - parameter alarmType:  Alarm type for which skip will be done.
     */
    class func skipAlarmSetup(forSchedule schedule: VBSchedule, prayerTime: PrayerTime, alarmType: AlarmType)
    {
        let prayerSettingsName = prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let skipDateKey = alarmType == .Alarm ? "skipAlarmDate" : "skipNotificationDate"
        
        if var prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        {
            let skipAlarmKey = alarmType == .Alarm ? "skipAlarm" : "skipNotification"
            let skipAlarmOffsetKey = alarmType == .Alarm ? "alarmOffset" : "notificationOffset"
            
            let skipAlarm = prayerSettings[skipAlarmKey] as! Bool
            let alarmOffset = prayerSettings[skipAlarmOffsetKey] as! Int
            
            prayerSettings[skipAlarmKey] = !skipAlarm
            
            var locationOffset = 0
            let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
            locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
            
            do
            {
                let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
                
                if !locations.isEmpty
                {
                    if let location = locations.first , location.id != 107
                    {
                        let offsetsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBOffset")
                        offsetsFetchRequest.predicate = NSPredicate(format: "month == %d AND locationId == %d", Int(schedule.month), Int(location.id))
                        
                        do
                        {
                            let offsets = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(offsetsFetchRequest) as! [VBOffset]
                            
                            if !offsets.isEmpty
                            {
                                if let offset = offsets.first
                                {
                                    if [.Fajr, .Sunrise].contains(prayerTime)
                                    {
                                        locationOffset = Int(offset.fajr)
                                    }
                                    else if [.Dhuhr, .Jumuah].contains(prayerTime)
                                    {
                                        locationOffset = Int(offset.dhuhr)
                                    }
                                    else if [.Asr, .Maghrib, .Isha].contains(prayerTime)
                                    {
                                        locationOffset = Int(offset.asr)
                                    }
                                }
                            }
                        }
                        catch
                        {
                            print(error)
                        }
                    }
                }
            }
            catch
            {
                print(error)
            }
            
            let time = prayerScheduleTime(fromSchedule: schedule, prayerTime: prayerTime)
            let components = time!.components(separatedBy: ":")
            
            var dateComponents = DateComponents()
            dateComponents.year = Calendar.current.component(.year, from: Date())
            dateComponents.month = Int(schedule.month)
            dateComponents.day = Int(schedule.day)
            dateComponents.hour = Int(components.first!) ?? 0
            dateComponents.minute = Int(components.last!) ?? 0
            
            // Setting fire date
            if var fireDate = Calendar.current.date(from: dateComponents)
            {
                // Adding location offset
                if prayerTime == .Dhuhr || prayerTime == .Jumuah
                {
                    let isStandardDhuhrTime = userDefaults?.bool(forKey: "isStandardDhuhrTime") ?? false
                    
                    if isStandardDhuhrTime
                    {
                        locationOffset = 0
                    }
                }
                
                fireDate = Calendar.current.date(byAdding: .minute, value: locationOffset, to: fireDate)!
                
                // Adding user offset
                fireDate = Calendar.current.date(byAdding: .minute, value: -alarmOffset, to: fireDate)!
                
                // Adding day light saving offset
                let isDaylightSavingTimeForFireDate = Calendar.current.timeZone.isDaylightSavingTime(for: fireDate)
                if isDaylightSavingTimeForFireDate
                {
                    fireDate = Calendar.current.date(byAdding: .hour, value: 1, to: fireDate)!
                }
                
                // Adding day offset
                let now = Date()
                
                if fireDate.compare(now) == .orderedAscending
                {
                    fireDate = Calendar.current.date(byAdding: .day, value: 1, to: fireDate)!
                    
                    // When added 1 day to fire date
                    // again check is needed for day light saving time
                    let isDaylightSavingTime = Calendar.current.timeZone.isDaylightSavingTime(for: fireDate)
                    
                    // If both check are not equal some corrections are needed
                    if isDaylightSavingTimeForFireDate != isDaylightSavingTime
                    {
                        // If it was winter saving time for old check (today)
                        // and summer saving time for new check (tomorrow)
                        // add 1 hour to fire date
                        if !isDaylightSavingTimeForFireDate && isDaylightSavingTime
                        {
                            fireDate = Calendar.current.date(byAdding: .hour, value: 1, to: fireDate)!
                        }
                            // If it was summer saving time for old check (today)
                            // and winter saving time for new check (tomorrow)
                            // remove 1 hour from fire date
                        else
                        {
                            fireDate = Calendar.current.date(byAdding: .hour, value: -1, to: fireDate)!
                        }
                    }
                }
                
                prayerSettings[skipDateKey] = fireDate
            }
            
            userDefaults?.set(prayerSettings, forKey: prayerSettingsName)
        }
    }
}
