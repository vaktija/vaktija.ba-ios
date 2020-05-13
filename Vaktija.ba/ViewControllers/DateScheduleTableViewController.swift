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
        
		navigationItem.title = "Namaska vremena"
        
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
        
        dateString += dateFormatter.string(from: pickedDate) + "\n"
        
		let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamicUmmAlQura)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: pickedDate)
        
        dateString += (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year!) + "."
        
        let headerView = tableView.tableHeaderView as! DateScheduleTableHeaderView
		headerView.headerLabel?.text = dateString.lowercased()
        tableView.tableHeaderView = headerView
        sizeHeaderToFit()
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
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
        
		cell.backgroundColor = UIColor.backgroundColor
        cell.textLabel!.text = VBPrayer.prayerName(forPrayerTime: prayerTime).capitalizedFirst
		cell.textLabel?.textColor = UIColor.titleColor
		cell.detailTextLabel!.text = VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: prayerTime)
		cell.detailTextLabel?.textColor = UIColor.subtitleColor

        return cell
    }
    
    func sizeHeaderToFit()
    {
        let headerView = tableView.tableHeaderView!
        
        headerView.setNeedsLayout()
        headerView.layoutIfNeeded()
        
        let height = headerView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        var frame = headerView.frame
        frame.size.height = height
        headerView.frame = frame
        
        tableView.tableHeaderView = headerView
    }
}
