//
//  DateScheduleTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData

class DateScheduleTableViewController: UITableViewController
{
    var pickedDate = Date()
    fileprivate var schedule: VBSchedule?
    fileprivate var hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Namaska vremena"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: pickedDate)
        
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
        
        var dateString = ""
        let locale = Locale(identifier: "bs_BA")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, dd. MMMM yyyy."
        dateFormatter.locale = locale
        
        dateString += dateFormatter.string(from: pickedDate) + " god.\n"
        
        let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamic)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: pickedDate)
        
        dateString += (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year!) + ". h."
        
        let headerView = tableView.tableHeaderView as! DateScheduleTableHeaderView
        headerView.headerLabel?.text = dateString
        
        tableView.tableHeaderView = headerView
        
        sizeHeaderToFit()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidChangeStatusBarOrientation(_:)), name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationDidChangeStatusBarOrientation, object: nil)
    }
    
    func applicationDidChangeStatusBarOrientation(_ notification: Notification)
    {
        sizeHeaderToFit()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 6
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ScheduleCell", for: indexPath)

        // Configure the cell...
        
        let prayerTime = VBPrayer.prayerTimeForIndex(indexPath.row, schedule:schedule!)
        
        cell.textLabel!.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: prayerTime)
        cell.detailTextLabel!.text = VBPrayer.prayerName(forPrayerTime: prayerTime)

        return cell
    }
    
    func sizeHeaderToFit()
    {
        let headerView = tableView.tableHeaderView!
        
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        let height = headerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        
        tableView.tableHeaderView = headerView
    }
}
