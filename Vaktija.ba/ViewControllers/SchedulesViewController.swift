//
//  SchedulesViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import AVFoundation
import UserNotifications

/// ### Represents View Controller that handles all functionality related to Schedules Display and GUI.
class SchedulesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UNUserNotificationCenterDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var warningView: UIView!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var headerView: UIView!
	@IBOutlet weak var locationImageView: UIImageView!
	@IBOutlet weak var locationLabel: UILabel!
	@IBOutlet weak var headerLabel: UILabel!
    
	@IBOutlet weak var tableViewHeightLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var tableViewCenterYLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewBottomLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerViewHeightLayoutConstraint: NSLayoutConstraint!
    
    fileprivate var schedule: VBSchedule?
	private var remainingTimes: [TimeData] = []
    private var schedulesTableViewCellHeight: CGFloat = 67.0
	private let cellHeight: CGFloat = 67.0
	private let locationOffset: CGFloat = 42.0
    //fileprivate var silentSoundId: SystemSoundID = 0
    //fileprivate var silentSoundInterval: TimeInterval = 0
    //fileprivate var isSilentSoundPaused = false
    
    var timer: Timer?
    //var timer3: Timer?
	
	struct TimeData {
		var label: UILabel
		var prayerIndex: Int
		var time: Int = 0
		var isSelected: Bool = false
	}
    
    // MARK: - View's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "Vaktija"
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
				if granted {
					VBNotification().scheduleLocalNotifications(true)
				}
            })
        } else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.alert, .sound], categories: nil))
        }
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        silentModeDetectorSetup()
        silentModeDetectorRun()
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
		for index in 0...5 {
			remainingTimes.append(TimeData(label: UILabel(), prayerIndex: index))
		}
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		navigationController?.setNavigationBarHidden(true, animated: true)
        
        prepareSchedule()
        
		DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) { [weak self] in
            self?.calculateTableViewCellHeight()
			self?.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let iOSVersion = Double(UIDevice.current.systemVersion) ?? 10.1
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let isWarningShown = userDefaults?.bool(forKey: "ios_warning_shown") ?? false
        
        if !isWarningShown && iOSVersion >= 10.0 && iOSVersion < 10.1 {
            let message = "iOS verzija na vašem uređaju je \(iOSVersion).\nPostoji poznati problem na iOS \(iOSVersion) verziji zbog kojeg alarmi neće raditi za aplikaciju Vaktija.ba.\nMolimo vas da updajtujete vaš uređaj na posljednju verziju iOS-a, tako što ćete da odete na Postavke (Settings) -> Općenito (General) -> Ažuriranje softvera (Software Update)."
            
            let alertController = UIAlertController(title: "iOS \(iOSVersion) verzija problem", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Zatvori", style: .cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
            
            userDefaults?.set(true, forKey: "ios_warning_shown")
        }
    }
    
    override var canBecomeFirstResponder : Bool {
        return true
    }
    
    @objc func applicationDidEnterBackground() {
        // All timers should be invalidate while app is in the background
        // due to fact it could drain device's battery otherwise
        
        timer?.invalidate()
        
        //isSilentSoundPaused = true
        //timer3?.invalidate()
    }
    
    @objc func applicationWillEnterForeground() {
        // Initialise schedule, notifications and all timers when app enters foreground
        // and prepare adequate GUI
        
        prepareSchedule()
        
        VBNotification().scheduleLocalNotifications(true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(20)) { [weak self] in
            self?.calculateTableViewCellHeight()
			self?.tableView.reloadData()
        }
        
        //isSilentSoundPaused = false
        silentModeDetectorRun()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath) as! ScheduleTableViewCell
		let row = indexPath.row
        
        // Configure the cell...
        
        let prayerTime = VBPrayer.prayerTimeForIndex(row, schedule: schedule!)
        
        cell.timeLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: prayerTime)
		cell.nameLabel.text = VBPrayer.prayerName(forPrayerTime: prayerTime).capitalizedFirst
        
        let (_, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule!)
		
		let (nextSchedulePrayerTime, _) = VBPrayer.nextPrayerTimeAndIndex(forSchedule: schedule!)
        
        if nextSchedulePrayerTime == prayerTime {
			cell.nameLabel.textColor = UIColor.selectedColor
        } else {
			cell.nameLabel.textColor = UIColor.titleColor
        }
        
        let nextScheduleIndex = (currentScheduleIndex + 1)%6

		var timeData = remainingTimes[indexPath.row]
		timeData.label = cell.timeRemainingLabel
		timeData.prayerIndex = indexPath.row
        if nextScheduleIndex == indexPath.row {
            VBNotification.resetSkips()
			timeData.isSelected = true
			
			let nextPrayerTime = VBPrayer.prayerTimeForIndex(nextScheduleIndex, schedule: schedule!)
            let display = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule!, prayerTime: nextPrayerTime)
            
            cell.timeRemainingLabel.text = display.formattedText
            
            timer?.invalidate()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick), userInfo: nil, repeats: true)
        } else {
			timeData.isSelected = false
			
			let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
            let display = VBPrayer.displayRemainingPrayerScheduleTimeToPrayerTime(forSchedule: schedule!, prayerTime: prayerTime)
            
            cell.timeRemainingLabel.text = display.formattedText
        }
		remainingTimes[indexPath.row] = timeData
        
        return cell
    }
    
    // MARK: Table View Delegates
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return schedulesTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		if let thisCell = cell as? ScheduleTableViewCell {
			let cellWidth = thisCell.frame.width
			let multiplier: CGFloat = cellWidth/375.0
			let constant: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100.0 : 0.0
			thisCell.nameLabelLeadingLayoutConstraint.constant = 50.0*multiplier + constant
			thisCell.timeLabelTrailingLayoutConstraint.constant = 50.0*multiplier + constant
		}
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        showScheduleSettings(indexPath)
    }
	
	@available(iOS 11, *)
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		
		var rowActions: [UIContextualAction] = []
		
		let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettingsName = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        
        let alarm = prayerSettings!["alarm"] as! Bool
        let skipAlarm = prayerSettings!["skipAlarm"] as! Bool
        let notification = prayerSettings!["notification"] as! Bool
        let skipNotification = prayerSettings!["skipNotification"] as! Bool
        
        if alarm {
			let skipAlarmRowAction = UIContextualAction(style: .destructive, title: (skipAlarm ? "Uključi\nalarm" : "Preskoči\nalarm")) { [weak self] _, _, _  in
                self?.skipAlarm(indexPath)
            }
			skipAlarmRowAction.backgroundColor = UIColor.errorColor
            rowActions.append(skipAlarmRowAction)
        }
        
        if notification {
            let skipNotificationRowAction = UIContextualAction(style: .normal, title: (skipNotification ? "Uključi\nnotifikaciju" : "Preskoči\nnotifikaciju")) { [weak self] _, _, _ in
                self?.skipNotification(indexPath)
            }
			skipNotificationRowAction.backgroundColor = UIColor.warningColor
            rowActions.append(skipNotificationRowAction)
        }
        
        let prayerSettingsRowAction = UIContextualAction(style: .normal, title: "Postavke") { [weak self] _, _, _ in
            self?.showScheduleSettings(indexPath)
        }
		prayerSettingsRowAction.backgroundColor = UIColor.subtitleColor
        rowActions.append(prayerSettingsRowAction)
		
		return UISwipeActionsConfiguration(actions: rowActions)
	}
    
	@available(iOS, deprecated: 11.0)
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var rowActions = [UITableViewRowAction]()
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettingsName = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let prayerSettings = userDefaults!.dictionary(forKey: prayerSettingsName)
        
        let alarm = prayerSettings!["alarm"] as! Bool
        let skipAlarm = prayerSettings!["skipAlarm"] as! Bool
        let notification = prayerSettings!["notification"] as! Bool
        let skipNotification = prayerSettings!["skipNotification"] as! Bool
        
        if alarm {
            let skipAlarmRowAction = UITableViewRowAction(style: .default, title: (skipAlarm ? "Uključi\nalarm" : "Preskoči\nalarm")) { [weak self] (_, _) in
                self?.skipAlarm(indexPath)
            }
			skipAlarmRowAction.backgroundColor = UIColor.errorColor
            rowActions.append(skipAlarmRowAction)
        }
        
        if notification {
            let skipNotificationRowAction = UITableViewRowAction(style: .normal, title: (skipNotification ? "Uključi\nnotifikaciju" : "Preskoči\nnotifikaciju")) { [weak self] (_, _) in
                 self?.skipNotification(indexPath)
            }
			skipNotificationRowAction.backgroundColor = UIColor.warningColor
            rowActions.append(skipNotificationRowAction)
        }
        
        let prayerSettingsRowAction = UITableViewRowAction(style: .normal, title: "Postavke") { (_, _) in
             self.showScheduleSettings(indexPath)
        }
		prayerSettingsRowAction.backgroundColor = UIColor.subtitleColor
        rowActions.append(prayerSettingsRowAction)
        
        return rowActions
    }
    
    // MARK: - Public Functions
    
    @objc func timeRemainingTick() {
		let times = remainingTimes
		for (index, timeData) in times.enumerated() {
			let prayerTime = VBPrayer.prayerTimeForIndex(timeData.prayerIndex, schedule: schedule!)
			if timeData.isSelected {
				let display = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule!, prayerTime: prayerTime)
				
				if display.timeInSeconds - 2 == 0 {
					DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) { [weak self] in
						VBNotification.resetSkips()
						self?.tableView.reloadData()
					}
					tableView.reloadData()
					break
				}
				timeData.label.text = display.formattedText
			} else {
				let display = VBPrayer.displayRemainingPrayerScheduleTimeToPrayerTime(forSchedule: schedule!, prayerTime: prayerTime)
				timeData.label.text = display.formattedText
			}
			remainingTimes[index] = timeData
		}
    }
    
    func skipAlarm(_ indexPath: IndexPath) {
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        
        VBPrayer.skipAlarmSetup(forSchedule: schedule!, prayerTime: prayerTime, alarmType: .Alarm)
        
        VBNotification().scheduleLocalNotifications(false)
        
        self.tableView.setEditing(false, animated: true)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func skipNotification(_ indexPath: IndexPath) {
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        
        VBPrayer.skipAlarmSetup(forSchedule: schedule!, prayerTime: prayerTime, alarmType: .Notification)
        
        VBNotification().scheduleLocalNotifications(false)
        
        self.tableView.setEditing(false, animated: true)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    @objc func showScheduleSettings(_ indexPath: IndexPath) {
        let scheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "ScheduleTableViewController") as! ScheduleTableViewController
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule: schedule!)
        let prayerSettings = VBPrayer.prayerSettingsKey(forPrayerTime: prayerTime, schedule: schedule!)
        
        scheduleTableViewController.prayerTime = prayerTime
        scheduleTableViewController.prayerSettings = prayerSettings
        navigationController?.pushViewController(scheduleTableViewController, animated: true)
    }
    
    // MARK: - Private Functions
    
    fileprivate func prepareSchedule() {
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        // Schedule
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
        
        do {
            let schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as! [VBSchedule]
            schedule = schedules.first
        } catch {
            print(error)
        }
		
		// Location
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as? [VBLocation]
			locationLabel.text = locations?.first?.location?.capitalized
        } catch {
            print(error)
        }
        
        // Date header view
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "bs-BA")
        dateFormatter.dateFormat = "EEE, dd. MMMM yyyy"
        
        var showDates = dateFormatter.string(from: Date()) + " / "
        
        let hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
		let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamicUmmAlQura)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
        
        showDates += (hijriDateComponents.day! < 10 ? "0" : "") + String(hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(hijriDateComponents.year!)
        
        headerLabel.text = showDates.lowercased()
		
		locationImageView.tintColor = UIColor.titleColor
		locationLabel.textColor = UIColor.titleColor
		headerLabel.textColor = UIColor.titleColor
		warningLabel.textColor = UIColor.warningColor
    }
    
    fileprivate func calculateTableViewCellHeight() {
        let headerViewHeight = headerViewHeightLayoutConstraint.constant
		let safeAreaHeight: CGFloat
		if #available(iOS 11.0, *) {
			safeAreaHeight = view.safeAreaLayoutGuide.layoutFrame.height
		} else {
			safeAreaHeight = self.view.frame.height - self.topLayoutGuide.length - self.bottomLayoutGuide.length
		}
		let tableAreaHeight = safeAreaHeight - headerViewHeight - locationOffset
        let possibleCellHeight = floor(tableAreaHeight/6.0)
		let calculatedLocationOffset: CGFloat
        if possibleCellHeight <= cellHeight {
            schedulesTableViewCellHeight = possibleCellHeight
			calculatedLocationOffset = locationOffset/4.0
        } else {
			let calculatedCellHeight = cellHeight + (possibleCellHeight - cellHeight)*0.3
            schedulesTableViewCellHeight = calculatedCellHeight
			calculatedLocationOffset = locationOffset
        }
		tableViewHeightLayoutConstraint.constant = 6.0*schedulesTableViewCellHeight
		tableViewCenterYLayoutConstraint.constant = (headerViewHeight + calculatedLocationOffset)/2.0
		headerViewBottomLayoutConstraint.constant = calculatedLocationOffset
    }
    
    func silentModeDetectorSetup() {
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
    
    func silentModeDetectorRun() {
        /*timer3?.invalidate()
        timer3 = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(silentSoundPlayLoop), userInfo: nil, repeats: true)*/
    }
    
    func silentSoundPlayLoop() {
        /*if !isSilentSoundPaused
        {
            self.silentSoundInterval = Date.timeIntervalSinceReferenceDate
            
            AudioServicesPlaySystemSound(self.silentSoundId)
        }*/
    }
    
    // MARK: - Testing Methods
    
    fileprivate func testAlarm() {
        // Notification for testing purposes
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if #available(iOS 10.0, *)
        {
            let content = UNMutableNotificationContent()
            
            content.title = "Alarm za Ikindija"
            content.body = "Ikindija nastupa za 5 minuta."
            
            let ringtoneFileName = userDefaults!.string(forKey: "alarmRingtone")
            let ringtoneFilePath = ringtoneFileName! + ".mp3"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: ringtoneFilePath))
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20, repeats: false)
            let request = UNNotificationRequest(identifier: "Test Alarm", content: content, trigger: trigger)
            
            // Schedule the notification.
            let center = UNUserNotificationCenter.current()
            center.add(request)
            {
                (error) in
                    print(error as Any)
            }
        } else {
            let localNotification = UILocalNotification()
            localNotification.fireDate = Date().addingTimeInterval(20)
            localNotification.alertTitle = "Alarm za Ikindija"
            localNotification.alertBody = "Ikindija nastupa za 5 minuta."
            
            let ringtoneFileName = userDefaults!.string(forKey: "alarmRingtone")
            let ringtoneFilePath = ringtoneFileName! + ".mp3"
            
            localNotification.soundName = ringtoneFilePath
            
            let userInfo = ["alarm_type": "alarm", "prayer": "ikindija"]
            
            localNotification.userInfo = userInfo
            
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
    
    fileprivate func showScheduledNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                for request in requests {
                    print(request.identifier)
                    print(request.content.title)
                    print(request.content.body)
                    
                    let trigger = request.trigger as! UNCalendarNotificationTrigger
                    
                    print(String(describing: trigger.dateComponents.year!) + "-" + String(describing: trigger.dateComponents.month!) + "-" + String(describing: trigger.dateComponents.day!) + " " + String(describing: trigger.dateComponents.hour!) + ":" + String(describing: trigger.dateComponents.minute!) + ":" + String(describing: trigger.dateComponents.second!))
                }
            })
        } else {
            let scheduled = UIApplication.shared.scheduledLocalNotifications
            
			print("\(String(describing: scheduled?.count))")
            
            for notif in scheduled! {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                print(notif.userInfo!.description)
                print(dateFormatter.string(from: notif.fireDate!))
            }
        }
    }
}
