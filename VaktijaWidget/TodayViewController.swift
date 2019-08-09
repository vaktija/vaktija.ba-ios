//
//  TodayViewController.swift
//  VaktijaWidget
//
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController, NCWidgetProviding
{
    @IBOutlet weak var headerStackView: UIStackView!
    @IBOutlet weak var nextPrayerLabel: UILabel!
    @IBOutlet weak var showMoreButton: UIButton!
    
    @IBOutlet weak var minContentStackView: UIStackView!
    @IBOutlet weak var previousPrayerTimeLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var nextPrayerTimeLabel: UILabel!
    
    @IBOutlet weak var maxContentStackView: UIStackView!
    @IBOutlet weak var fajrLabel: UILabel!
    @IBOutlet weak var sunriseLabel: UILabel!
    @IBOutlet weak var dhuhrLabel: UILabel!
    @IBOutlet weak var asrLabel: UILabel!
    @IBOutlet weak var maghribLabel: UILabel!
    @IBOutlet weak var ishaLabel: UILabel!
    
    @IBOutlet weak var footerStackView: UIStackView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    
    @IBOutlet weak var footerStackViewTopLayoutConstraint: NSLayoutConstraint!
    
    enum VBWidgetDisplayMode
    {
        case compact
        case expanded
    }
    
    fileprivate var displayMode: VBWidgetDisplayMode = .compact
    fileprivate var prayer = VBPrayer()
    
    fileprivate let expandedHeight: CGFloat = 218.0
    fileprivate let compactHeight: CGFloat = 110.0
    fileprivate let bottomMargin: CGFloat = 13.0
    
    var timer: Timer?
    var timeRemainingComponents: [String] = []
    
    // MARK: - Widget's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        nextPrayerLabel.text = "--"
        previousPrayerTimeLabel.text = "--"
        nextPrayerTimeLabel.text = "--"
        fajrLabel.text = "--"
        sunriseLabel.text = "--"
        dhuhrLabel.text = "--"
        asrLabel.text = "--"
        maghribLabel.text = "--"
        ishaLabel.text = "--"
        dateLabel.text = "--"
        locationLabel.text = "--"
        
        if #available(iOSApplicationExtension 10.0, *)
        {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
            
            showMoreButton.isHidden = true
        }
        else
        {
            nextPrayerLabel.textColor = .white
            previousPrayerTimeLabel.textColor = .white
            separatorView.backgroundColor = .white
            nextPrayerTimeLabel.textColor = .white
            fajrLabel.textColor = .white
            sunriseLabel.textColor = .white
            dhuhrLabel.textColor = .white
            asrLabel.textColor = .white
            maghribLabel.textColor = .white
            ishaLabel.textColor = .white
            dateLabel.textColor = .white
            locationLabel.textColor = .white
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if #available(iOSApplicationExtension 10.0, *)
        {
            if extensionContext?.widgetActiveDisplayMode == .expanded
            {
                preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
                
                footerStackViewTopLayoutConstraint.constant = maxContentStackView.frame.maxY + bottomMargin
                
                minContentStackView.isHidden = true
                maxContentStackView.isHidden = false
            }
            else
            {
                preferredContentSize = extensionContext!.widgetMaximumSize(for: .compact)
                
                footerStackViewTopLayoutConstraint.constant = minContentStackView.frame.maxY + bottomMargin
                
                minContentStackView.isHidden = false
                maxContentStackView.isHidden = true
            }
        }
        else
        {
            showMoreButton.setTitle((displayMode == .compact ? "Show More" : "Show Less"), for: .normal)
            
            if displayMode == .expanded
            {
                preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
                
                footerStackViewTopLayoutConstraint.constant = maxContentStackView.frame.maxY + bottomMargin
                
                minContentStackView.isHidden = true
                maxContentStackView.isHidden = false
            }
            else
            {
                preferredContentSize = CGSize(width: preferredContentSize.width, height: compactHeight)
                
                footerStackViewTopLayoutConstraint.constant = minContentStackView.frame.maxY + bottomMargin
                
                minContentStackView.isHidden = false
                maxContentStackView.isHidden = true
            }
        }
        
        prepareData()
    }
    
    internal func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void))
    {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        prepareData()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets
    {
        return UIEdgeInsets.zero
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize)
    {
        if activeDisplayMode == .expanded
        {
            preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
            
            footerStackViewTopLayoutConstraint.constant = maxContentStackView.frame.maxY + bottomMargin
            
            minContentStackView.isHidden = true
            maxContentStackView.isHidden = false
        }
        else
        {
            preferredContentSize = maxSize
            
            footerStackViewTopLayoutConstraint.constant = minContentStackView.frame.maxY + bottomMargin
            
            minContentStackView.isHidden = false
            maxContentStackView.isHidden = true
        }
    }
    
    // MARK: - Button Functions
    
    @IBAction func showMoreButtonClick(_ sender: UIButton)
    {
        displayMode = (displayMode == .compact ? .expanded : .compact)
        sender.setTitle((displayMode == .compact ? "Show More" : "Show Less"), for: .normal)
        
        if displayMode == .expanded
        {
            preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
            
            footerStackViewTopLayoutConstraint.constant = maxContentStackView.frame.maxY + bottomMargin
            
            minContentStackView.isHidden = true
            maxContentStackView.isHidden = false
        }
        else
        {
            preferredContentSize = CGSize(width: preferredContentSize.width, height: compactHeight)
            
            footerStackViewTopLayoutConstraint.constant = minContentStackView.frame.maxY + bottomMargin
            
            minContentStackView.isHidden = false
            maxContentStackView.isHidden = true
        }
    }
    
    // MARK: - Gesture Functions
    
    @IBAction func widgetViewTapGestureRecognizerClick(_ sender: UITapGestureRecognizer)
    {
        extensionContext?.open(URL(string: "vaktijaba://")!, completionHandler: nil)
    }
    
    // MARK: - Private Functions
    
    fileprivate func prepareData()
    {
        // Schedule for current date
        
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
        
        do
        {
            let schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as! [VBSchedule]
            
            if schedules.count > 0
            {
                let schedule = schedules.first
                let (currentSchedulePrayerTime, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule!)
                let currentPrayerTimeString = VBPrayer.prayerName(forPrayerTime: currentSchedulePrayerTime);
                
                let nextPrayerTimeIndex = (currentScheduleIndex + 1)%6
                let nextSchedulePrayerTime = VBPrayer.prayerTimeForIndex(nextPrayerTimeIndex, schedule: schedule!)
                let nextPrayerTimeString = VBPrayer.prayerName(forPrayerTime: nextSchedulePrayerTime)
                
                let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule!, prayerTime: nextSchedulePrayerTime)
                let title = nextPrayerTimeString.capitalized
                
                // Min Content's Data
                
                nextPrayerLabel.text = title + " je za " + components[0] + "h " + components[1] + "m. "; //+ components[2] + "s."
                
                timeRemainingComponents = components
                
                timer?.invalidate()
                
                let userInfo: [String: AnyObject] = ["title": title as AnyObject, "schedule": schedule!, "prayerTime": nextPrayerTimeIndex as AnyObject]
                
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick), userInfo: userInfo, repeats: true)
                
                previousPrayerTimeLabel.text = (currentSchedulePrayerTime == .Sunrise ? "Izl. sunca" : currentPrayerTimeString.capitalized) + " " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: currentSchedulePrayerTime)
                
                nextPrayerTimeLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: nextSchedulePrayerTime) + " " + (nextSchedulePrayerTime == .Sunrise ? "Izl. sunca" : nextPrayerTimeString.capitalized)
                
                // Max Content's Data
                
                fajrLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Fajr) + " - Zora"
                sunriseLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Sunrise) + " - Izl. sunca"
                let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
                let jumuah = userDefaults!.bool(forKey: "isJumuahSettingOn") && VBPrayer.isJumuah(Date())
                dhuhrLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Dhuhr) + (jumuah ? " - Džuma" : " - Podne")
                asrLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Asr) + " - Ikindija"
                maghribLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Maghrib) + " - Akšam"
                ishaLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Isha) + " - Jacija"
            }
        }
        catch
        {
            print(error)
        }
        
        // Date Label
        
        let hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
        let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamic)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
        
        let hijriDateString = (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year!) + ". h."
        dateLabel.text = hijriDateString.lowercased()
        
        // Location Label
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do
        {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
            
            if locations.count > 0
            {
                let location = locations.first
                
                locationLabel.text = location?.location
            }
        }
        catch
        {
            print(error)
        }
    }
    
    @objc func timeRemainingTick()
    {
        if let goodTimer = timer
        {
            if goodTimer.isValid
            {
                let userInfo = goodTimer.userInfo as! [String: AnyObject]
                let title = userInfo["title"] as! String
                let schedule = userInfo["schedule"] as! VBSchedule
                let prayerIndex = userInfo["prayerTime"] as! Int
                
                var timeInSeconds = Int(timeRemainingComponents[0])!*3600 + Int(timeRemainingComponents[1])!*60 + Int(timeRemainingComponents[2])!
                
                timeInSeconds = timeInSeconds - 1
                
                if timeInSeconds == 0
                {
                    let nextPrayerTimeIndex = (prayerIndex + 1)%6
                    let nextPrayerTime = VBPrayer.prayerTimeForIndex(nextPrayerTimeIndex, schedule: schedule)
                    let nextPrayerTimeString = VBPrayer.prayerName(forPrayerTime: nextPrayerTime)
                    
                    let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule, prayerTime: nextPrayerTime)
                    let title = nextPrayerTimeString.capitalized
                    
                    nextPrayerLabel.text = title + " je za " + components[0] + "h " + components[1] + "m " + components[2] + "s."
                    
                    timeRemainingComponents = components
                    
                    timer?.invalidate()
                    
                    let userInfo: [String: AnyObject] = ["title": title as AnyObject, "schedule": schedule, "prayerTime": nextPrayerTimeIndex as AnyObject]
                    
                    timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick), userInfo: userInfo, repeats: true)
                    
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
                
                nextPrayerLabel.text = title + " je za " + components[0] + "h " + components[1] + "m. "; //+ components[2] + "s."
                
                timeRemainingComponents = components
            }
        }
    }
}
