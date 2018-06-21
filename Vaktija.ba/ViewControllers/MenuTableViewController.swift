//
//  MenuTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import Social

class MenuTableViewController: UITableViewController, UIActivityItemSource
{
    fileprivate let items = [["id": "qibla", "title": "Kibla kompas"], ["id": "times", "title": "Zakazane obavijesti"], ["id": "date", "title": "Odaberi datum..."], ["id": "settings", "title": "Postavke"], ["id": "share", "title": "Podijeli"], ["id": "remarks", "title": "Napomene"], ["id": "about", "title": "O aplikaciji"]]
    fileprivate var hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        
        title = "Meni"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)

        // Configure the cell...
        
        let item = items[indexPath.row]
        cell.textLabel?.text = item["title"]
        return cell
    }

    // MARK: - Table View Delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let item = items[indexPath.row]
        
        if let id = item["id"]
        {
            switch id
            {
                case "qibla":
                    if let qiblaViewController = storyboard?.instantiateViewController(withIdentifier: "QiblaViewController")
                    {
                        navigationController?.pushViewController(qiblaViewController, animated: true)
                    }
                
                case "times":
                    if let timesTableViewController = storyboard?.instantiateViewController(withIdentifier: "TimesTableViewController")
                    {
                        navigationController?.pushViewController(timesTableViewController, animated: true)
                    }
                
                case "date":
                    if let dateViewController = storyboard?.instantiateViewController(withIdentifier: "DateViewController")
                    {
                        navigationController?.pushViewController(dateViewController, animated: true)
                    }
                
                case "settings":
                    if let settingsTableViewController = storyboard?.instantiateViewController(withIdentifier: "SettingsTableViewController")
                    {
                        navigationController?.pushViewController(settingsTableViewController, animated: true)
                    }
                
                case "share":
                    var activityItems: Array<AnyObject> = [self]
                    
                    if let url = URL(string:"https://itunes.apple.com/us/app/vaktija.ba/id1095343967?ls=1&mt=8")
                    {
                        activityItems.append(url as AnyObject)
                    }
                    
                    if let image = UIImage(named: "logo_small")
                    {
                        activityItems.append(image)
                    }
                    
                    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    
                    if UIDevice.current.userInterfaceIdiom == .pad
                    {
                        let navigationBar = navigationController?.navigationBar
                        activityViewController.modalPresentationStyle = .popover
                        activityViewController.popoverPresentationController?.sourceView = navigationBar
                        activityViewController.popoverPresentationController?.sourceRect = navigationBar!.frame
                    }
                    
                    navigationController?.present(activityViewController, animated: true, completion: nil)
                
                case "remarks":
                    if let remarksTableViewController = storyboard?.instantiateViewController(withIdentifier: "RemarksTableViewController")
                    {
                        navigationController?.pushViewController(remarksTableViewController, animated: true)
                    }
                
                case "about":
                    if let aboutViewController = storyboard?.instantiateViewController(withIdentifier: "AboutViewController")
                    {
                        navigationController?.pushViewController(aboutViewController, animated: true)
                    }
                
                default:
                    print("No action for selected menu item!")
            }
        }
    }
    
    // MARK: - Activity Item Source
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any?
    {
        var schedule: VBSchedule? = nil
        var location: VBLocation? = nil
        
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
        
        do
        {
            let schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as! [VBSchedule]
            
            if schedules.count > 0
            {
                schedule = schedules.first!
            }
        }
        catch
        {
            print(error)
        }
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do
        {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
            
            if locations.count > 0
            {
                location = locations.first!
            }
        }
        catch
        {
            print(error)
        }
        
        var content = ""
        
        if activityType == UIActivityType.postToTwitter
        {
            let isJumuah = VBPrayer.isJumuah(Date())
            
            content += "\n\nzora: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Fajr) + "\n"
            content += "izlazak sunca: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Sunrise) + "\n"
            content += (isJumuah ? "džuma" : "podne: ") + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Dhuhr) + "\n"
            content += "ikindija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Asr) + "\n"
            content += "akšam: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Maghrib) + "\n"
            content += "jacija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Isha) + "\n"
            
            return content
        }
        else
        {
            content += location!.location! + "\n"
            
            let today = Date()
            let locale = Locale(identifier: "bs_BA")
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE, dd. MMMM yyyy."
            dateFormatter.locale = locale
            
            content += dateFormatter.string(from: today) + "\n"
            
            let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamic)
            let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
            
            content += (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year) + ".h"
            
            let isJumuah = VBPrayer.isJumuah(Date())
            
            content += "\n\nzora: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Fajr) + "\n"
            content += "izlazak sunca: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Sunrise) + "\n"
            content += (isJumuah ? "džuma: " : "podne: ") + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Dhuhr) + "\n"
            content += "ikindija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Asr) + "\n"
            content += "akšam: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Maghrib) + "\n"
            content += "jacija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Isha) + "\n"
            
            if activityType == UIActivityType.postToFacebook
            {
                dismiss(animated: true, completion: {
                    
                    if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook)
                    {
                        let alertController = UIAlertController(title: "Facebook", message: "Zbog novih uslova koje nudi Facebook, morat ćete kopirati text ispod, a zatim kada se Facebook Post Screen otvori, priljepiti (paste) isti.\n\n\(content)", preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: "Zatvori", style: .cancel, handler: nil))
                        alertController.addAction(UIAlertAction(title: "Kopiraj", style: .default, handler: { (action) in
                            
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = content
                            
                            let facebookComposeVC = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
                            
                            facebookComposeVC?.setInitialText(content)
                            
                            if let image = UIImage(named: "logo_small")
                            {
                                facebookComposeVC?.add(image)
                            }
                            
                            if let url = URL(string:"https://itunes.apple.com/us/app/vaktija.ba/id1095343967?ls=1&mt=8")
                            {
                                facebookComposeVC?.add(url)
                            }
                            
                            self.present(facebookComposeVC!, animated: true, completion: nil)
                        }))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                    else
                    {
                        let alertController = UIAlertController(title: "", message: "You are not connected to your Facebook account.", preferredStyle: .alert)
                        
                        alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
                        
                        self.present(alertController, animated: true, completion: nil)
                    }
                })
            }
            else
            {
                return content
            }
        }
        
        return ""
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        let infoDictionary = Bundle.main.infoDictionary
        let bundleName = infoDictionary!["CFBundleName"] as! String
        
        return bundleName
    }
}
