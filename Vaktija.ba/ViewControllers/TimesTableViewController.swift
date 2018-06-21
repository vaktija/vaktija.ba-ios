//
//  TimesTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import UserNotifications

class TimesTableViewController: UITableViewController
{
    @IBOutlet weak var headerLabel: UILabel!
    
    fileprivate var dates: [String] = []
    fileprivate var times: [[[String: String]]] = []
    
    // MARK: - View's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Zakazane obavijesti"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do
        {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
            
            if locations.count > 0
            {
                let location = locations.first
                
                headerLabel.text = location?.location?.capitalized
            }
        }
        catch
        {
            print(error)
        }
        
        let activityIndicatorView = UIActivityIndicatorView(frame: CGRect(x: tableView.frame.midX - 15.0, y: tableView.frame.midY - 30.0, width: 30.0, height: 30.0))
        activityIndicatorView.hidesWhenStopped = true
        activityIndicatorView.activityIndicatorViewStyle = .gray
        
        tableView.addSubview(activityIndicatorView)
        activityIndicatorView.startAnimating()
        
        if #available(iOS 10.0, *)
        {
            UNUserNotificationCenter.current().getPendingNotificationRequests
            {
                (scheduledRequests) in
                
                if scheduledRequests.isEmpty
                {
                    OperationQueue.main.addOperation
                    {
                        activityIndicatorView.stopAnimating()
                    }
                    
                    return
                }
                
                var requests = scheduledRequests
                
                requests.sort(by:
                {
                    (request1, request2) -> Bool in
                    
                    if let trigger1 = request1.trigger as? UNCalendarNotificationTrigger, let trigger2 = request2.trigger as? UNCalendarNotificationTrigger, let date1 = Calendar.current.date(from: trigger1.dateComponents), let date2 = Calendar.current.date(from: trigger2.dateComponents)
                    {
                        return date1.compare(date2) == .orderedAscending
                    }
                    
                    return false
                })
                
                var index = 0
                var previousPrayer = ""
                
                for request in requests
                {
                    let userInfo = request.content.userInfo
                    let prayer = userInfo["prayer"] as! String
                    let type = userInfo["alarm_type"] as! String
                    
                    let prayerDate = userInfo["prayer_date"] as! Date
                    let prayerDateFormatter = DateFormatter()
                    prayerDateFormatter.dateFormat = "HH:mm"
                    let scheduleString = prayerDateFormatter.string(from: prayerDate)
                    
                    let trigger = request.trigger as! UNCalendarNotificationTrigger
                    
                    let triggerDate = Calendar.current.date(from: trigger.dateComponents)
                    let triggerDateFormatter = DateFormatter()
                    triggerDateFormatter.dateFormat = "EEEE, dd. MMMM. yyyy."
                    triggerDateFormatter.locale = Locale(identifier: "bs_BA")
                    
                    var dateString = triggerDateFormatter.string(from: triggerDate!)
                    
                    if VBPrayer.isJumuah(triggerDate!)
                    {
                        dateString = dateString + " (Džuma)"
                    }
                    
                    let timeString = (trigger.dateComponents.hour! < 10 ? "0" : "") + String(describing: trigger.dateComponents.hour!) + ":" + (trigger.dateComponents.minute! < 10 ? "0" : "") + String(describing: trigger.dateComponents.minute!)
                    
                    var time = ["prayer": prayer, "time": scheduleString]
                    
                    if type == "alarm"
                    {
                        time["alarm"] = timeString
                        time["notification"] = ""
                    }
                    else
                    {
                        time["alarm"] = ""
                        time["notification"] = timeString
                    }
                    
                    if self.dates.count == 0
                    {
                        self.dates.append(dateString)
                        self.times.append([time])
                    }
                    else if self.dates.contains(dateString)
                    {
                        if previousPrayer == prayer
                        {
                            var previousTimes = self.times.last
                            var previousTime = previousTimes?.last
                            previousTime?["notification"] = timeString
                            previousTimes?[previousTimes!.count - 1] = previousTime!
                            self.times[self.times.count - 1] = previousTimes!
                        }
                        else
                        {
                            self.times[index].append(time)
                        }
                    }
                    else
                    {
                        self.dates.append(dateString)
                        self.times.append([time])
                        index = index + 1
                    }
                    
                    previousPrayer = prayer
                }
                
                OperationQueue.main.addOperation({
                    
                    self.tableView.reloadData()
                    activityIndicatorView.stopAnimating()
                })
            }
        }
        else
        {
            if var notifications = UIApplication.shared.scheduledLocalNotifications, !notifications.isEmpty
            {
                notifications.sort(by:
                {
                    (notification1, notification2) -> Bool in
                    
                    if let fireDate1 = notification1.fireDate, let fireDate2 = notification2.fireDate
                    {
                        return fireDate1.compare(fireDate2) == .orderedAscending
                    }
                    
                    return false
                })
                
                var index = 0
                var previousPrayer = ""
                
                for notification in notifications
                {
                    let userInfo = notification.userInfo
                    let prayer = userInfo?["prayer"] as! String
                    let type = userInfo?["alarm_type"] as! String
                    
                    let prayerDate = userInfo?["prayer_date"] as! Date
                    let prayerDateFormatter = DateFormatter()
                    prayerDateFormatter.dateFormat = "HH:mm"
                    let scheduleString = prayerDateFormatter.string(from: prayerDate)
                    
                    let fireDate = notification.fireDate
                    let fireDateFormatter = DateFormatter()
                    fireDateFormatter.dateFormat = "EEEE, dd. MMMM. yyyy."
                    fireDateFormatter.locale = Locale(identifier: "bs_BA")
                    
                    var dateString = fireDateFormatter.string(from: fireDate!)
                    
                    if VBPrayer.isJumuah(fireDate!)
                    {
                        dateString = dateString + " (Džuma)"
                    }
                    
                    let fireTimeFormatter = DateFormatter()
                    fireTimeFormatter.dateFormat = "HH:mm"
                    let timeString = fireTimeFormatter.string(from: fireDate!)
                    
                    var time = ["prayer": prayer, "time": scheduleString]
                    
                    if type == "alarm"
                    {
                        time["alarm"] = timeString
                        time["notification"] = ""
                    }
                    else
                    {
                        time["alarm"] = ""
                        time["notification"] = timeString
                    }
                    
                    if self.dates.count == 0
                    {
                        self.dates.append(dateString)
                        self.times.append([time])
                    }
                    else if self.dates.contains(dateString)
                    {
                        if previousPrayer == prayer
                        {
                            var previousTimes = self.times.last
                            var previousTime = previousTimes?.last
                            previousTime?["notification"] = timeString
                            previousTimes?[previousTimes!.count - 1] = previousTime!
                            self.times[self.times.count - 1] = previousTimes!
                        }
                        else
                        {
                            self.times[index].append(time)
                        }
                    }
                    else
                    {
                        self.dates.append(dateString)
                        self.times.append([time])
                        index = index + 1
                    }
                    
                    previousPrayer = prayer
                }
            }
            
            activityIndicatorView.stopAnimating()
        }
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return dates.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return times[section].count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return dates[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimeCell", for: indexPath)
        
        let time = times[indexPath.section][indexPath.row]
        
        let alarm = (time["alarm"] == "" ? "" : "Alarm: " + time["alarm"]! + "h")
        let notification = (time["notification"] == "" ? "" : "Notifikacija: " + time["notification"]! + "h")
        let newLine = ((time["alarm"] != "" && time["notification"] != "") ? "\n" : "")
        
        cell.textLabel?.text = time["prayer"]! + " " + time["time"]! + "h"
        cell.detailTextLabel?.text = alarm + newLine + notification

        return cell
    }
}
