//
//  MenuTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import LinkPresentation
import Social

class MenuTableViewController: UITableViewController
{
    fileprivate let items = [["id": "times", "title": "Zakazane obavijesti"], ["id": "settings", "title": "Postavke"], ["id": "share", "title": "Podijeli"], ["id": "remarks", "title": "Napomene"], ["id": "about", "title": "O aplikaciji"]]
    fileprivate var hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
	
	fileprivate let shareLink = "https://itunes.apple.com/us/app/vaktija.ba/id1095343967?ls=1&mt=8"
	@available(iOS 13.0, *)
	fileprivate lazy var metadata: LPLinkMetadata = {
		let metadata = LPLinkMetadata()
		metadata.originalURL = URL(string: shareLink)
		metadata.url = metadata.originalURL
		metadata.title = "Vaktija.ba na AppStore-u"
		metadata.imageProvider = NSItemProvider.init(contentsOf:
        Bundle.main.url(forResource: "app_thumbnail", withExtension: "png"))
		return metadata
	}()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
		navigationItem.title = "Meni"
        tableView.tableFooterView = UIView(frame: CGRect.zero)
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCell", for: indexPath)

        // Configure the cell...
        
        let item = items[indexPath.row]
		cell.backgroundColor = UIColor.backgroundColor
        cell.textLabel?.text = item["title"]
		cell.textLabel?.textColor = UIColor.titleColor
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
                case "times":
                    if let timesTableViewController = storyboard?.instantiateViewController(withIdentifier: "TimesTableViewController")
                    {
                        navigationController?.pushViewController(timesTableViewController, animated: true)
                    }
                
                case "settings":
                    if let settingsTableViewController = storyboard?.instantiateViewController(withIdentifier: "SettingsTableViewController")
                    {
                        navigationController?.pushViewController(settingsTableViewController, animated: true)
                    }
                
                case "share":
                    var activityItems: Array<AnyObject> = [self]
                    
                    if let url = URL(string:shareLink)
                    {
                        activityItems.append(url as AnyObject)
                    }
                    
                    if let image = UIImage(named: "logo_small")
                    {
                        activityItems.append(image)
                    }
                    
                    let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
					activityViewController.excludedActivityTypes = [.assignToContact, .openInIBooks, .saveToCameraRoll]
                    
                    if UIDevice.current.userInterfaceIdiom == .pad {
						let sourceView = tableView.cellForRow(at: indexPath)
                        activityViewController.modalPresentationStyle = .popover
                        activityViewController.popoverPresentationController?.sourceView = sourceView
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
}

// MARK: - Activity Item Source

extension MenuTableViewController: UIActivityItemSource {
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        var schedule: VBSchedule? = nil
        var location: VBLocation? = nil
        
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
        
        do {
            let schedules = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as? [VBSchedule]
            schedule = schedules?.first
        } catch {
            print(error)
        }
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
        
        do {
            let locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as? [VBLocation]
            location = locations?.first
        } catch {
            print(error)
        }
        
		var content = "\n"
		
		// Location
		if let locationName = location?.location {
			content += "\(locationName)\n\n"
		}
		
		// Date
		let today = Date()
		let locale = Locale(identifier: "bs_BA")
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "EEEE, dd. MMMM yyyy."
		dateFormatter.locale = locale
		content += "\(dateFormatter.string(from: today))\n"
		
		// Hijri date
		let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamicUmmAlQura)
		let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
		var hijriDateString = (hijriDateComponents.day! < 10 ? "0" : "") + String(hijriDateComponents.day!)
		hijriDateString += ". " + hijriMonths[hijriDateComponents.month!] + " "
		hijriDateString += String(hijriDateComponents.year!) + ".h"
		content += hijriDateString
		
		// Times
		let isJumuah = VBPrayer.isJumuah(Date())
		content += "\n\nzora: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Fajr) + "\n"
		content += "izlazak sunca: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Sunrise) + "\n"
		content += (isJumuah ? "džuma: " : "podne: ") + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Dhuhr) + "\n"
		content += "ikindija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Asr) + "\n"
		content += "akšam: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Maghrib) + "\n"
		content += "jacija: " + VBPrayer.displayPrayerScheduleTime(forSchedule: schedule!, prayerTime: .Isha) + "\n\n"
		
		if activityType == .postToFacebook
		{
			if #available(iOS 11.0, *) {
				return content
			} else {
				postToFacebook(content: content)
				return ""
			}
		}
		else
		{
			return content
		}
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String
    {
        let infoDictionary = Bundle.main.infoDictionary
        let bundleName = infoDictionary!["CFBundleName"] as! String
        
        return bundleName
    }
	
	@available(iOS 13.0, *)
	func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
		return metadata
	}
	
	@available(iOS, deprecated: 11.0)
	private func postToFacebook(content: String) {
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
					
					if let url = URL(string: self.shareLink)
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
}
