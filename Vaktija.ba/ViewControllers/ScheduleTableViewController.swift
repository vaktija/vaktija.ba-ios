//
//  ScheduleTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class ScheduleTableViewController: UITableViewController
{
    var prayerTime: VBPrayer.PrayerTime?
    var prayerSettings: String?
    
    fileprivate var alarmOn = false
    fileprivate var notificationOn = false
    fileprivate var alarmOffset = 0
    fileprivate var notificationOffset = 0
    fileprivate var thereAreChanges = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if let prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            let prayerTitle = prayer["title"] as? String
            title = prayerTitle?.capitalized
            
            alarmOn = prayer["alarm"] as! Bool
            notificationOn = prayer["notification"] as! Bool
            alarmOffset = prayer["alarmOffset"] as! Int
            notificationOffset = prayer["notificationOffset"] as! Int
        }
        
        if [.Dhuhr, .Jumuah].contains(prayerTime!)
        {
            let filteredViewControllers = navigationController?.viewControllers.filter({$0.isKind(of: ScheduleTableViewController.self)})
            
            if filteredViewControllers?.count < 2
            {
                if prayerTime == .Dhuhr
                {
                    if userDefaults!.bool(forKey: "isJumuahSettingOn")
                    {
                        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Džuma", style: .plain, target: self, action: #selector(jumuahBarButtonItemClick(_:)))
                    }
                }
                else if prayerTime == .Jumuah
                {
                    navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Podne", style: .plain, target: self, action: #selector(dhuhrBarButtonItemClick(_:)))
                }
            }
        }
        
        tableView.estimatedRowHeight = 101
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if isMovingFromParentViewController && thereAreChanges
        {
            var shouldReschedule = false
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            if let prayer = userDefaults!.dictionary(forKey: prayerSettings!)
            {
                let currentAlarmOn = prayer["alarm"] as? Bool ?? false
                if currentAlarmOn != alarmOn
                {
                    shouldReschedule = true
                }
                
                let currentNotificationOn = prayer["notification"] as? Bool ?? false
                if currentNotificationOn != notificationOn
                {
                    shouldReschedule = true
                }
                
                let currentAlarmOffset = prayer["alarmOffset"] as? Int ?? 0
                if currentAlarmOffset != alarmOffset
                {
                    shouldReschedule = true
                }
                
                let currentNotificationOffset = prayer["notificationOffset"] as? Int ?? 0
                if currentNotificationOffset != notificationOffset
                {
                    shouldReschedule = true
                }
            }
            
            if shouldReschedule
            {
                VBNotification().scheduleLocalNotifications(true)
            }
        }
    }
    
    // MARK: - Navigation Bar
    
    func jumuahBarButtonItemClick(_ sender:UIBarButtonItem)
    {
        let scheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "ScheduleTableViewController") as! ScheduleTableViewController
        
        scheduleTableViewController.prayerTime = .Jumuah
        scheduleTableViewController.prayerSettings = "jumuahSettings"
        
        navigationController?.pushViewController(scheduleTableViewController, animated: true)
    }
    
    func dhuhrBarButtonItemClick(_ sender:UIBarButtonItem)
    {
        let scheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "ScheduleTableViewController") as! ScheduleTableViewController
        
        scheduleTableViewController.prayerTime = .Jumuah
        scheduleTableViewController.prayerSettings = "dhuhrSettings"
        
        navigationController?.pushViewController(scheduleTableViewController, animated: true)
    }
    
    func resetBarButtonItemClick(_ sender: UIBarButtonItem)
    {
        if var rightBarButtonItems = navigationItem.rightBarButtonItems
        {
            rightBarButtonItems.removeFirst()
            
            navigationItem.rightBarButtonItems = (rightBarButtonItems.isEmpty ? nil : rightBarButtonItems)
        }
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        if var prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            prayer["alarm"] = alarmOn
            prayer["notification"] = notificationOn
            prayer["alarmOffset"] = alarmOffset
            prayer["notificationOffset"] = notificationOffset
            
            userDefaults?.set(prayer, forKey: prayerSettings!)
        }
        
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let row = indexPath.row
        
        if row == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath) as! AlarmTableViewCell
            
            // Configure the cell...
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            if let prayer = userDefaults!.dictionary(forKey: prayerSettings!)
            {
                let alarmState = prayer["alarm"] as! Bool
                cell.stateSwitch.isOn = alarmState
                cell.detailsLabel.isEnabled = alarmState
                cell.offsetSlider.isEnabled = alarmState
                
                let alarmMinutesOffset = prayer["alarmOffset"] as! Int
                cell.detailsLabel.text = getOffsetString(alarmMinutesOffset) + " prije nastupa"
                cell.offsetSlider.value = Float(alarmMinutesOffset*100)
                
                cell.stateSwitch.addTarget(self, action: #selector(alarmStateSwitchValueChanged(_:)), for: .valueChanged)
                cell.offsetSlider.addTarget(self, action: #selector(alarmOffsetSliderValueChanged(_:)), for: .valueChanged)
            }
            
            return cell
        }
        else if row == 1
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath) as! NotificationTableViewCell
            
            // Configure the cell...
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            if let prayer = userDefaults!.dictionary(forKey: prayerSettings!)
            {
                let notificationState = prayer["notification"] as! Bool
                cell.stateSwitch.isOn = notificationState
                cell.detailsLabel.isEnabled = notificationState
                cell.offsetSlider.isEnabled = notificationState
                
                let notificationMinutesOffset = prayer["notificationOffset"] as! Int
                cell.detailsLabel.text = getOffsetString(notificationMinutesOffset) + " prije nastupa"
                cell.offsetSlider.value = Float(notificationMinutesOffset*100)
                
                cell.stateSwitch.addTarget(self, action: #selector(notificationStateSwitchValueChanged(_:)), for: .valueChanged)
                cell.offsetSlider.addTarget(self, action: #selector(notificationOffsetSliderValueChanged(_:)), for: .valueChanged)
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - Switch Delegates
    
    func alarmStateSwitchValueChanged(_ sender: UISwitch)
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if var prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            prayer["alarm"] = sender.isOn
            
            userDefaults!.set(prayer, forKey: prayerSettings!)
            
            thereAreChanges = true
            displayResetBarButtonItem()
        }
        
        if sender.superview!.superview!.isKind(of: AlarmTableViewCell.self)
        {
            let cell = sender.superview?.superview as! AlarmTableViewCell
            let indexPath = tableView.indexPath(for: cell)
            
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        }
    }
    
    func notificationStateSwitchValueChanged(_ sender: UISwitch)
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if var prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            prayer["notification"] = sender.isOn
            
            userDefaults!.set(prayer, forKey: prayerSettings!)
            
            thereAreChanges = true
            displayResetBarButtonItem()
        }
        
        if sender.superview!.superview!.isKind(of: NotificationTableViewCell.self)
        {
            let cell = sender.superview?.superview as! NotificationTableViewCell
            let indexPath = tableView.indexPath(for: cell)
            
            tableView.reloadRows(at: [indexPath!], with: .automatic)
        }
    }
    
    // MARK: - Slider Delegates
    
    func alarmOffsetSliderValueChanged(_ sender: UISlider)
    {
        let offset = Int(sender.value/100.0)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if var prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            prayer["alarmOffset"] = offset
            
            userDefaults!.set(prayer, forKey: prayerSettings!)
            
            thereAreChanges = true
            displayResetBarButtonItem()
        }
        
        if sender.superview!.superview!.isKind(of: AlarmTableViewCell.self)
        {
            let cell = sender.superview?.superview as! AlarmTableViewCell
            
            cell.detailsLabel.text = getOffsetString(offset) + " prije nastupa"
        }
    }
    
    func notificationOffsetSliderValueChanged(_ sender: UISlider)
    {
        let offset = Int(sender.value/100.0)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if var prayer = userDefaults!.dictionary(forKey: prayerSettings!)
        {
            prayer["notificationOffset"] = offset
            
            userDefaults!.set(prayer, forKey: prayerSettings!)
            
            thereAreChanges = true
            displayResetBarButtonItem()
        }
        
        if sender.superview!.superview!.isKind(of: NotificationTableViewCell.self)
        {
            let cell = sender.superview?.superview as! NotificationTableViewCell
            
            cell.detailsLabel.text = getOffsetString(offset) + " prije nastupa"
        }
    }
    
    // MARK: - Private Functions
    
    fileprivate func getOffsetString(_ offset: Int) -> String
    {
        let hours = Int(offset/60)
        let minutes = Int(offset%60)
        
        var alarmOffsetString = ""
        
        if hours < 10
        {
            alarmOffsetString = "0\(hours):"
        }
        else
        {
            alarmOffsetString = "\(hours):"
        }
        
        if minutes < 10
        {
            alarmOffsetString = alarmOffsetString + "0\(minutes)"
        }
        else
        {
            alarmOffsetString = alarmOffsetString + "\(minutes)"
        }
        
        return alarmOffsetString
    }
    
    fileprivate func displayResetBarButtonItem()
    {
        if navigationItem.rightBarButtonItems == nil
        {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Otkaži", style: .plain, target: self, action: #selector(resetBarButtonItemClick(_:)))
            navigationItem.rightBarButtonItem?.tintColor = UIColor.red
        }
        else if navigationItem.rightBarButtonItems?.count == 1
        {
            if var rightBarButtonItems = navigationItem.rightBarButtonItems
            {
                if rightBarButtonItems.first?.title?.lowercased() == "džuma"
                {
                    rightBarButtonItems.insert(UIBarButtonItem(title: "Otkaži", style: .plain, target: self, action: #selector(resetBarButtonItemClick(_:))), at: 0)
                    rightBarButtonItems.first?.tintColor = UIColor.red
                    
                    navigationItem.rightBarButtonItems = rightBarButtonItems
                }
            }
        }
    }
}
