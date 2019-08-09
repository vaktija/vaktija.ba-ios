//
//  SchedulesViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import AVFoundation
import UserNotifications

/// ### Represents View Controller that handles all functionality related to Schedules Display and its GUI.
class SchedulesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UNUserNotificationCenterDelegate, ScheduleCollectionViewCellDelegate
{
    @IBOutlet weak var schedulesTableView: UITableView!
    @IBOutlet weak var schedulesCollectionView: UICollectionView!
    @IBOutlet weak var locationBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var headerLabel: UILabel!
    
    @IBOutlet weak var schedulesTableViewTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var schedulesTableViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var scheduleCollectionViewHeightLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewTopLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    fileprivate var schedule:VBSchedule?
    fileprivate var tableTimeRemainingLabel: UILabel?
    fileprivate var collectionTimeRemainingLabel: UILabel?
    fileprivate var timeLabelFontSize: CGFloat = 50.0
    fileprivate var schedulesTableViewCellHeight: CGFloat = 77.0
    //fileprivate var silentSoundId: SystemSoundID = 0
    //fileprivate var silentSoundInterval: TimeInterval = 0
    //fileprivate var isSilentSoundPaused = false
    
    var timer1:Timer?
    var timer2:Timer?
    //var timer3:Timer?
    
    // MARK: - View's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        //title = "Vaktija"
        
        if #available(iOS 10.0, *)
        {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
                
            })
            //UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
        else
        {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
            
            //UIApplication.shared.cancelAllLocalNotifications()
        }
        
        //testAlarm()
        
        schedulesTableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let delayTime = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime)
        {
            VBNotification().scheduleLocalNotifications(true)
        }
        
        prepareCollectionViewCustomActions()
        
        silentModeDetectorSetup()
        
        silentModeDetectorRun()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        //showScheduledNotifications()
        
        prepareSchedule()
        
        let delayTime = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime)
        {
            self.configureViewsOnInterfaceOrientationChanges()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidChangeStatusBarOrientation(_:)), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        let iOSVersion = Double(UIDevice.current.systemVersion) ?? 10.1
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let isWarningShown = userDefaults?.bool(forKey: "ios_warning_shown") ?? false
        
        if !isWarningShown && iOSVersion >= 10.0 && iOSVersion < 10.1
        {
            let message = "iOS verzija na vašem uređaju je \(iOSVersion).\nPostoji poznati problem na iOS \(iOSVersion) verziji zbog kojeg alarmi neće raditi za aplikaciju Vaktija.ba.\nMolimo vas da updajtujete vaš uređaj na posljednju verziju iOS-a, tako što ćete da odete na Postavke (Settings) -> Općenito (General) -> Ažuriranje softvera (Software Update)."
            
            let alertController = UIAlertController(title: "iOS \(iOSVersion) verzija problem", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Zatvori", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
            
            userDefaults?.set(true, forKey: "ios_warning_shown")
        }
    }
    
    override var canBecomeFirstResponder : Bool
    {
        return true
    }
    
    @objc func applicationDidChangeStatusBarOrientation(_ notification: Notification)
    {
        schedulesCollectionView.collectionViewLayout.invalidateLayout()
        
        let delayTime = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime)
        {
            self.configureViewsOnInterfaceOrientationChanges()
        }
    }
    
    @objc func applicationDidEnterBackground()
    {
        // All timers should be invalidate while app is in the background
        // due to fact it could drain device's batery otherwise
        
        timer1?.invalidate()
        timer2?.invalidate()
        
        //isSilentSoundPaused = true
        //timer3?.invalidate()
    }
    
    @objc func applicationWillEnterForeground()
    {
        // Initialize schedule, notifications and all timers when app enters foreground
        // and prepare adequate GUI
        
        prepareSchedule()
        
        VBNotification().scheduleLocalNotifications(true)
        
        let delayTime = DispatchTime.now() + Double(Int64(0.2 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime)
        {
            self.configureViewsOnInterfaceOrientationChanges()
        }
        
        //isSilentSoundPaused = false
        silentModeDetectorRun()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as! ScheduleTableViewCell
        
        // Configure the cell...
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        
        cell.timeLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: prayerTime)
        cell.nameLabel.text = VBPrayer.prayerName(forPrayerTime: prayerTime)
        
        let (currentSchedulePrayerTime, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule!)
        
        if currentSchedulePrayerTime == prayerTime
        {
            cell.timeLabel.textColor = UIColor(red: 140.0/255.0, green: 142.0/255.0, blue: 4.0/255.0, alpha: 1.0)
            
            cell.timeLabel.font = UIFont.systemFont(ofSize: cell.timeLabel.font.pointSize, weight: UIFont.Weight.light)
        }
        else
        {
            cell.timeLabel.textColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            cell.timeLabel.font = UIFont.systemFont(ofSize: cell.timeLabel.font.pointSize, weight: UIFont.Weight.thin)
        }
        
        let nextScheduleIndex = (currentScheduleIndex + 1)%6
        
        if nextScheduleIndex == indexPath.row
        {
            VBNotification.resetSkips()
            
            let nextPrayerTime = VBPrayer.prayerTimeForIndex(nextScheduleIndex, schedule: schedule!)
            tableTimeRemainingLabel = cell.timeRemainingLabel
            
            let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule!, prayerTime: nextPrayerTime)
            
            tableTimeRemainingLabel!.text = components.joined(separator: ":")
            
            timer1?.invalidate()
            
            timer1 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick1), userInfo: nil, repeats: true)
        }
        else
        {
            cell.timeRemainingLabel.text = ""
        }
        
        return cell
    }
    
    // MARK: Table View Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return schedulesTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        let thisCell = cell as! ScheduleTableViewCell
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettingsName = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        
        let alarm = prayerSettings!["alarm"] as! Bool
        let alarmSkip = prayerSettings!["skipAlarm"] as! Bool
        let notification = prayerSettings!["notification"] as! Bool
        let notificationSkip = prayerSettings!["skipNotification"] as! Bool
        
        var alarmConstant: CGFloat = 0.0
        if alarm && notification
        {
            alarmConstant = 24.0
        }
        
        thisCell.alarmImageViewTrailingLayoutConstraint.constant = alarmConstant
        
        thisCell.alarmImageView.isHidden = !alarm
        thisCell.notificationImageView.isHidden = !notification
        
        thisCell.alarmImageView.image = thisCell.alarmImageView.image?.withRenderingMode(.alwaysTemplate)
        thisCell.notificationImageView.image = thisCell.notificationImageView.image?.withRenderingMode(.alwaysTemplate)
        
        thisCell.alarmImageView.tintColor = (alarmSkip ? UIColor.lightGray : UIColor.black)
        thisCell.notificationImageView.tintColor = (notificationSkip ? UIColor.lightGray : UIColor.black)
        
        let delta = thisCell.frame.width - 280.0
        
        thisCell.stackViewWidthLayoutConstraint.constant = 280.0 + delta/3.0
        
        let newDelta = thisCell.frame.width - thisCell.stackViewWidthLayoutConstraint.constant
        //thisCell.separatorInset = UIEdgeInsetsMake(0.0, newDelta/2.0, 0.0, newDelta/2.0)
        
        thisCell.separatorViewLeadingLayoutConstraint.constant = newDelta/2.0
        thisCell.separatorViewTrailingLayoutConstraint.constant = newDelta/2.0
        
        if indexPath.row == 5
        {
            thisCell.separatorView.backgroundColor = UIColor.clear
        }
        else
        {
            thisCell.separatorView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        showScheduleSettings(indexPath)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]?
    {
        var rowActions = [UITableViewRowAction]()
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettingsName = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        
        let alarm = prayerSettings!["alarm"] as! Bool
        let skipAlarm = prayerSettings!["skipAlarm"] as! Bool
        let notification = prayerSettings!["notification"] as! Bool
        let skipNotification = prayerSettings!["skipNotification"] as! Bool
        
        if alarm
        {
            let skipAlarmRowAction = UITableViewRowAction(style: .default, title: (skipAlarm ? "Uključi\nalarm" : "Preskoči\nalarm"))
            {
                (_, _) in
                
                self.skipAlarm(indexPath)
            }
            
            rowActions.append(skipAlarmRowAction)
        }
        
        if notification
        {
            let skipNotificationRowAction = UITableViewRowAction(style: .normal, title: (skipNotification ? "Uključi\nnotifikaciju" : "Preskoči\nnotifikaciju"))
            {
                (_, _) in
                
                self.skipNotification(indexPath)
            }
            
            skipNotificationRowAction.backgroundColor = UIColor(red: 253.0/255.0, green: 130.0/255.0, blue: 8.0/255.0, alpha: 1.0)
            
            rowActions.append(skipNotificationRowAction)
        }
        
        let prayerSettingsRowAction = UITableViewRowAction(style: .normal, title: "Postavke")
        {
            (_, _) in
            
            self.showScheduleSettings(indexPath)
        }
        
        rowActions.append(prayerSettingsRowAction)
        
        return rowActions
    }
    
    // MARK: - Collection View Data Source
    
    func numberOfSections(in collectionView: UICollectionView) -> Int
    {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return 6
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ScheduleCell", for: indexPath) as! ScheduleCollectionViewCell
        
        // Configure the cell...
        
        cell.delegate = self
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row,schedule: schedule!)
        
        cell.timeLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: prayerTime)
        cell.nameLabel.text = VBPrayer.prayerName(forPrayerTime: prayerTime)
        let (currentSchedulePrayerTime, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule!)
        
        let fontSize = cell.timeLabel.font.pointSize
        if currentSchedulePrayerTime == prayerTime
        {
            cell.timeLabel.textColor = UIColor(red: 140.0/255.0, green: 142.0/255.0, blue: 4.0/255.0, alpha: 1.0)
            cell.timeLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.light)
        }
        else
        {
            cell.timeLabel.textColor = UIColor(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0)
            cell.timeLabel.font = UIFont.systemFont(ofSize: fontSize, weight: UIFont.Weight.thin)
        }
        
        let nextScheduleIndex = (currentScheduleIndex + 1)%6
        let nextPrayerTime = VBPrayer.prayerTimeForIndex(nextScheduleIndex, schedule: schedule!)
        
        if nextScheduleIndex == indexPath.row
        {
            VBNotification.resetSkips()
            
            collectionTimeRemainingLabel = cell.timeRemainingLabel
            let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule!, prayerTime: nextPrayerTime)
            
            collectionTimeRemainingLabel!.text = components.joined(separator: ":")
            
            timer2?.invalidate()
            
            timer2 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick2), userInfo: nil, repeats: true)
        }
        else
        {
            cell.timeRemainingLabel.text = " "
        }
        
        if indexPath.row == 5
        {
            cell.separatorView.backgroundColor = UIColor.clear
        }
        else
        {
            cell.separatorView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        }
        
        return cell
    }
    
    // MARK: - Collection View Delegates
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        let thisCell = cell as! ScheduleCollectionViewCell
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettingsName = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        
        let alarm = prayerSettings!["alarm"] as! Bool
        let alarmSkip = prayerSettings!["skipAlarm"] as! Bool
        let notification = prayerSettings!["notification"] as! Bool
        let notificationSkip = prayerSettings!["skipNotification"] as! Bool
        
        var alarmConstant: CGFloat = 0.0
        var notificationConstant: CGFloat = 0.0
        if alarm && notification
        {
            alarmConstant = 32.0
        }
        else if alarm && !notification
        {
            alarmConstant = 16.0
        }
        else if !alarm && notification
        {
            notificationConstant = 16.0
        }
        
        thisCell.alarmImageViewTrailingLayoutConstraint.constant = alarmConstant
        thisCell.notificationImageViewTrailingLayoutConstraint.constant = notificationConstant
        
        thisCell.alarmImageView.isHidden = !alarm
        thisCell.notificationImageView.isHidden = !notification
        
        thisCell.alarmImageView.image = thisCell.alarmImageView.image?.withRenderingMode(.alwaysTemplate)
        thisCell.notificationImageView.image = thisCell.notificationImageView.image?.withRenderingMode(.alwaysTemplate)
        
        thisCell.alarmImageView.tintColor = (alarmSkip ? UIColor.lightGray : UIColor.black)
        thisCell.alarmImageView.tag = (alarmSkip ? 1 : 0)
        
        thisCell.notificationImageView.tintColor = (notificationSkip ? UIColor.lightGray : UIColor.black)
        thisCell.notificationImageView.tag = (notificationSkip ? 1 : 0)
        
        let fontName = thisCell.timeLabel.font.fontName
        thisCell.timeLabel.font = UIFont(name: fontName, size: timeLabelFontSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let width = collectionView.frame.width/6.0
        let height = width*(144.0/80.0)
        
        scheduleCollectionViewHeightLayoutConstraint.constant = height
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let scheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "ScheduleTableViewController") as! ScheduleTableViewController
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettings = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        
        scheduleTableViewController.prayerTime = prayerTime
        scheduleTableViewController.prayerSettings = prayerSettings
        navigationController?.pushViewController(scheduleTableViewController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool
    {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?)
    {
        print(action)
    }
    
    // MARK: - Schedule Collection View Cell Delegates
    
    func scheduleCollectionViewCellSkipAlarm(_ cell: ScheduleCollectionViewCell)
    {
        if let indexPath = schedulesCollectionView.indexPath(for: cell)
        {
            skipAlarm(indexPath)
        }
    }
    
    func scheduleCollectionViewCellSkipNotification(_ cell: ScheduleCollectionViewCell)
    {
        if let indexPath = schedulesCollectionView.indexPath(for: cell)
        {
            skipNotification(indexPath)
        }
    }
    
    func scheduleCollectionViewCellShowScheduleSettings(_ cell: ScheduleCollectionViewCell)
    {
        if let indexPath = schedulesCollectionView.indexPath(for: cell)
        {
            showScheduleSettings(indexPath)
        }
    }
    
    // MARK: - Public Functions
    
    @objc func timeRemainingTick1()
    {
        let timeComponents: [String] = tableTimeRemainingLabel!.text!.components(separatedBy: ":")
        var timeInSeconds = Int(timeComponents[0])!*3600 + Int(timeComponents[1])!*60 + Int(timeComponents[2])!
        
        timeInSeconds = timeInSeconds - 1
        
        if timeInSeconds == 0
        {
            let delayTime = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime)
            {
                VBNotification.resetSkips()
                
                self.schedulesTableView.reloadData()
            }
            
            schedulesTableView.reloadData()
            
            return
        }
        
        let hours = timeInSeconds/3600
        let minutes = (timeInSeconds%3600)/60
        let seconds = timeInSeconds%60
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
        
        tableTimeRemainingLabel!.text = components.joined(separator: ":")
    }
    
    @objc func timeRemainingTick2()
    {
        let timeComponents: [String] = collectionTimeRemainingLabel!.text!.components(separatedBy: ":")
        var timeInSeconds = Int(timeComponents[0])!*3600 + Int(timeComponents[1])!*60 + Int(timeComponents[2])!
        
        timeInSeconds = timeInSeconds - 1
        
        if timeInSeconds == 0
        {
            let delayTime = DispatchTime.now() + Double(Int64(2.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: delayTime)
            {
                VBNotification.resetSkips()
                
                self.schedulesTableView.reloadData()
            }
            
            schedulesCollectionView.reloadData()
            
            return
        }
        
        let hours = timeInSeconds/3600
        let minutes = (timeInSeconds%3600)/60
        let seconds = timeInSeconds%60
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
        
        collectionTimeRemainingLabel!.text = components.joined(separator: ":")
    }
    
    func skipAlarm(_ indexPath: IndexPath)
    {
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        
        VBPrayer.skipAlarmSetup(forSchedule: schedule!, prayerTime: prayerTime, alarmType: .Alarm)
        
        VBNotification().scheduleLocalNotifications(false)
        
        self.schedulesTableView.setEditing(false, animated: true)
        self.schedulesTableView.reloadRows(at: [indexPath], with: .none)
        self.schedulesCollectionView.reloadItems(at: [indexPath])
    }
    
    func skipNotification(_ indexPath: IndexPath)
    {
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        
        VBPrayer.skipAlarmSetup(forSchedule: schedule!, prayerTime: prayerTime, alarmType: .Notification)
        
        VBNotification().scheduleLocalNotifications(false)
        
        self.schedulesTableView.setEditing(false, animated: true)
        self.schedulesTableView.reloadRows(at: [indexPath], with: .none)
        self.schedulesCollectionView.reloadItems(at: [indexPath])
    }
    
    @objc func showScheduleSettings(_ indexPath: IndexPath)
    {
        let scheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "ScheduleTableViewController") as! ScheduleTableViewController
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettings = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        
        scheduleTableViewController.prayerTime = prayerTime
        scheduleTableViewController.prayerSettings = prayerSettings
        navigationController?.pushViewController(scheduleTableViewController, animated: true)
    }
    
    // MARK: - Private Functions
    
    fileprivate func prepareSchedule()
    {
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        // Schedule
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
        
        do
        {
            let schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as! [VBSchedule]
            
            if schedules.count > 0
            {
                schedule = schedules.first
            }
        }
        catch
        {
            print(error)
        }
        
        // Location
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do
        {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
            
            if locations.count > 0
            {
                let location = locations.first
                
                locationBarButtonItem.title = location?.location?.capitalized
            }
        }
        catch
        {
            print(error)
        }
        
        // Date header view
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "bs-BA")
        dateFormatter.dateFormat = "dd. MMMM yyyy."
        
        var showDates = dateFormatter.string(from: Date()) + " god.\n"
        
        let hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
        let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamic)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
        
        showDates += (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year!) + ". h."
        
        headerLabel.text = showDates.lowercased()
        
        if userDefaults!.bool(forKey: "showDate")
        {
            headerView.isHidden = false
        }
        else
        {
            headerView.isHidden = true
        }
    }
    
    fileprivate func calculateTableViewCellHeight()
    {
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let headerViewHeight = (userDefaults!.bool(forKey: "showDate") ? headerViewHeightLayoutConstraint.constant : 0.0)
        
        let tableArea = view.frame.height - navigationController!.navigationBar.frame.height - UIApplication.shared.statusBarFrame.height - headerViewHeight - headerViewTopLayoutConstraint.constant
        let possibleCellHeight = floor(tableArea/6.0)
        
        if possibleCellHeight <= 100.0
        {
            schedulesTableViewCellHeight = possibleCellHeight
            schedulesTableViewTopLayoutConstraint.constant = headerViewHeight + headerViewTopLayoutConstraint.constant
            schedulesTableViewBottomLayoutConstraint.constant = 0.0
        }
        else
        {
            schedulesTableViewCellHeight = 100.0
            let delta = 6.0*(possibleCellHeight - schedulesTableViewCellHeight)
            schedulesTableViewTopLayoutConstraint.constant = headerViewHeight + headerViewTopLayoutConstraint.constant + delta/2.0
            schedulesTableViewBottomLayoutConstraint.constant = delta/2.0
        }
    }
    
    fileprivate func calculateCollectionCellLabelsFontSize()
    {
        let cellWidth = schedulesCollectionView.frame.width/6.0
        let cellHeight = cellWidth*2
        
        let timeLabelFrame = CGRect(x: 0.0, y: 0.0, width: cellWidth, height: cellHeight/4.0)
        let timeLabel = UILabel(frame: timeLabelFrame)
        timeLabel.text = "99:99"
        var largestFontSize: CGFloat = 50.0
        
        
        while timeLabel.text!.size(withAttributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.font) : timeLabel.font.withSize(largestFontSize)])).width > timeLabelFrame.size.width
        {
            largestFontSize -= 1
        }
        
        timeLabelFontSize = largestFontSize
    }
    
    fileprivate func configureViewsOnInterfaceOrientationChanges()
    {
        if view.bounds.height > view.bounds.width
        {
            schedulesTableView.isHidden = false
            schedulesCollectionView.isHidden = true
            
            calculateTableViewCellHeight()
            schedulesTableView.reloadData()
        }
        else
        {
            schedulesTableView.isHidden = true
            schedulesCollectionView.isHidden = false
            
            calculateCollectionCellLabelsFontSize()
            schedulesCollectionView.reloadData()
        }
    }
    
    fileprivate func prepareCollectionViewCustomActions()
    {
        let skipAlarmMenuItem = UIMenuItem(title: "Preskoči alarm", action: #selector(ScheduleCollectionViewCell.skipAlarm(_:)))
        let turnAlarmMenuItem = UIMenuItem(title: "Uključi alarm", action: #selector(ScheduleCollectionViewCell.turnAlarm(_:)))
        
        let skipNotificationMenuItem = UIMenuItem(title: "Preskoči notifikaciju", action: #selector(ScheduleCollectionViewCell.skipNotification(_:)))
        let turnNotificationMenuItem = UIMenuItem(title: "Uključi notifikaciju", action: #selector(ScheduleCollectionViewCell.turnNotification(_:)))
        
        let showScheduleSettingsMenuItem = UIMenuItem(title: "Postavke", action: #selector(showScheduleSettings(_:)))
        
        UIMenuController.shared.menuItems = [skipAlarmMenuItem, turnAlarmMenuItem, skipNotificationMenuItem, turnNotificationMenuItem, showScheduleSettingsMenuItem]
    }
    
    func silentModeDetectorSetup()
    {
        /*if let urlRef: CFURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "silence" as CFString!, "wav" as CFString!, nil)
        {
            var status = AudioServicesCreateSystemSoundID(urlRef, &silentSoundId)
            
            if status == kAudioServicesNoError
            {
                status = AudioServicesAddSystemSoundCompletion(silentSoundId, nil, nil,
                                                               {
                                                                (soundId, clientData) in
                                                                
                                                                if UIApplication.shared.applicationState != .active
                                                                {
                                                                    return
                                                                }
                                                                
                                                                let dataSelf = unsafeBitCast(clientData, to: SchedulesViewController.self)
                                                                let elapsed = NSDate.timeIntervalSinceReferenceDate - dataSelf.silentSoundInterval
                                                                
                                                                //print("time elapsed: \(elapsed)")
                                                                
                                                                if elapsed < 0.5
                                                                {
                                                                    //print("Silent Mode is on!")
                                                                    
                                                                    if dataSelf.warningView.isHidden
                                                                    {
                                                                        dataSelf.headerViewTopLayoutConstraint.constant = 22.0;
                                                                        dataSelf.warningView.isHidden = false
                                                                        
                                                                        dataSelf.configureViewsOnInterfaceOrientationChanges()
                                                                    }
                                                                }
                                                                else
                                                                {
                                                                    //print("Silent Mode is off!")
                                                                    
                                                                    if !dataSelf.warningView.isHidden
                                                                    {
                                                                        dataSelf.headerViewTopLayoutConstraint.constant = 0.0
                                                                        dataSelf.warningView.isHidden = true
                                                                        
                                                                        dataSelf.configureViewsOnInterfaceOrientationChanges()
                                                                    }
                                                                }
                                                                
                    }, UnsafeMutableRawPointer(mutating: Unmanaged.passUnretained(self).toOpaque()))
                
                if status != kAudioServicesNoError
                {
                    print("System sound completion callback function not registered successfully!")
                }
            }
            else
            {
                print("System sound id for silence.wav file not created!")
            }
        }*/
    }
    
    func silentModeDetectorRun()
    {
        /*timer3?.invalidate()
        timer3 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(silentSoundPlayLoop), userInfo: nil, repeats: true)*/
    }
    
    func silentSoundPlayLoop()
    {
        /*if !isSilentSoundPaused
        {
            self.silentSoundInterval = Date.timeIntervalSinceReferenceDate
            
            AudioServicesPlaySystemSound(self.silentSoundId)
        }*/
    }
    
    // MARK: - Testing Methods
    
    fileprivate func testAlarm()
    {
        // Notification for testing purposes
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if #available(iOS 10.0, *)
        {
            let content = UNMutableNotificationContent()
            
            content.title = "Alarm za Ikindija"
            content.body = "Ikindija nastaje za 5 minuta."
            
            let ringtoneFileName = userDefaults!.string(forKey: "alarmRingtone")
            let ringtoneFilePath = ringtoneFileName! + ".mp3"
            content.sound = UNNotificationSound(named: convertToUNNotificationSoundName(ringtoneFilePath))
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
            let request = UNNotificationRequest(identifier: "Test Alarm", content: content, trigger: trigger)
            
            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request)
            {
                (error) in
                    print(error as Any)
            }
        }
        else
        {
            let localNotification = UILocalNotification()
            localNotification.fireDate = Date().addingTimeInterval(20)
            localNotification.alertTitle = "Alarm za Ikindija"
            localNotification.alertBody = "Ikindija nastaje za 5 minuta."
            
            let ringtoneFileName = userDefaults!.string(forKey: "alarmRingtone")
            let ringtoneFilePath = ringtoneFileName! + ".mp3"
            
            localNotification.soundName = ringtoneFilePath
            
            let userInfo = ["alarm_type": "alarm", "prayer": "ikindija"]
            
            localNotification.userInfo = userInfo
            
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
    
    fileprivate func showScheduledNotifications()
    {
        if #available(iOS 10.0, *)
        {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler:
            {
                (requests) in
                
                for request in requests
                {
                    print(request.identifier)
                    print(request.content.title)
                    print(request.content.body)
                    
                    let trigger = request.trigger as! UNCalendarNotificationTrigger
                    
                    print(String(describing: trigger.dateComponents.year!) + "-" + String(describing: trigger.dateComponents.month!) + "-" + String(describing: trigger.dateComponents.day!) + " " + String(describing: trigger.dateComponents.hour!) + ":" + String(describing: trigger.dateComponents.minute!) + ":" + String(describing: trigger.dateComponents.second!))
                }
            })
        }
        else
        {
            let scheduled = UIApplication.shared.scheduledLocalNotifications
            
            print("\(scheduled?.count ?? 0)")
            
            for notif in scheduled!
            {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                print(notif.userInfo!.description)
                print(dateFormatter.string(from: notif.fireDate!))
            }
        }
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToUNNotificationSoundName(_ input: String) -> UNNotificationSoundName {
	return UNNotificationSoundName(rawValue: input)
}
