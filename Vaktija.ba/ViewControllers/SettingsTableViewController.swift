//
//  SettingsTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import MessageUI
import LinkPresentation
import Social

class SettingsTableViewController: UITableViewController {
	private lazy var dataSource: SettingsDataSource = {
		return SettingsDataSource()
	}()
	
	// MARK: View's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		navigationItem.title = "Postavke"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 63.0
        tableView.rowHeight = UITableView.automaticDimension
        
		tableView.register(TableViewHeaderView.nib, forHeaderFooterViewReuseIdentifier: TableViewHeaderView.reuseIdentifier)
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		if let index = dataSource.data.firstIndex(where: { $0.id == .location }) {
			var setting = dataSource.data[index].items.first
			setting?.value = dataSource.locationName
			if let setting = setting {
				dataSource.data[index].items = [setting]
			}
		}
		tableView.reloadData()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
		return dataSource.data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dataSource.data[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
		let setting = dataSource.data[section].items[row]
		
		// Configure the cell...
		
		if let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as? SettingsTableViewCell {
			// Title
			switch setting.id {
			case .location:
				cell.titleLabel.text = setting.value as? String
			default:
				cell.titleLabel.text = setting.title
			}
			// Subtitle
			cell.subtitleLabel.text = setting.subtitle
			// Switch
			switch setting.id {
			case .location:
				cell.accessoryType = .disclosureIndicator
			case .dhuhr, .jummah:
				let widgetSwitch = UISwitch(frame: CGRect.zero)
				widgetSwitch.addTarget(self, action: #selector(widgetSwitchValueChanged(_:)), for: .valueChanged)
				widgetSwitch.isOn = (setting.value as? Bool) ?? false
				cell.accessoryType = .none
				cell.accessoryView = widgetSwitch
			default:
				cell.accessoryType = .none
				cell.accessoryView = nil
			}
			
			return cell
		}
		
		return UITableViewCell()
    }
    
    // MARK: - Table view delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row
		let setting = dataSource.data[section].items[row]
		
		switch setting.id {
		case .location:
			navigateToLocations()
		case .share:
			openShareActivity(sourceView: tableView.cellForRow(at: indexPath))
		case .feedback:
			sendFeedback()
		default:
			break
		}
    }
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TableViewHeaderView.reuseIdentifier) as? TableViewHeaderView else {
			return nil
		}
		headerView.titleLabel.text = dataSource.data[section].title
		return headerView
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 28.0
	}
    
    //MARK: - Switch delegates
    
    @objc func widgetSwitchValueChanged(_ sender: UISwitch) {
        let cell = sender.superview as! SettingsTableViewCell
        if let indexPath = tableView.indexPath(for: cell) {
            let section = indexPath.section
            let row = indexPath.row
			var setting = dataSource.data[section].items[row]
			
			switch setting.id {
			case .dhuhr:
				setting.value = sender.isOn
				setting.subtitle = dataSource.getDhuhrDetails(isOn: sender.isOn)
			case .jummah:
				setting.value = sender.isOn
				setting.subtitle = dataSource.getJummahDetails(isOn: sender.isOn)
			default:
				break
			}
			dataSource.data[section].items[row] = setting
            tableView.reloadRows(at: [indexPath], with: .automatic)
			
			if dataSource.saveChanges() {
				VBNotification().scheduleLocalNotifications(true)
			}
        }
    }
	
	// MARK: - Private Methods
	
	private func navigateToLocations() {
		if let locationsTableViewController = storyboard?.instantiateViewController(withIdentifier: "LocationsTableViewController") {
			navigationController?.pushViewController(locationsTableViewController, animated: true)
		}
	}
	
	private func openShareActivity(sourceView: UIView?) {
		var activityItems: Array<AnyObject> = [self]
		if let url = URL(string: dataSource.shareLink) {
			activityItems.append(url as AnyObject)
		}
		
		let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
		activityViewController.excludedActivityTypes = [.assignToContact, .openInIBooks, .saveToCameraRoll]
		
		if UIDevice.current.userInterfaceIdiom == .pad {
			activityViewController.modalPresentationStyle = .popover
			activityViewController.popoverPresentationController?.sourceView = sourceView
		}
		
		navigationController?.present(activityViewController, animated: true, completion: nil)
	}
	
	private func sendFeedback() {
		if MFMailComposeViewController.canSendMail() {
			let mailComposeViewController = MFMailComposeViewController()
			mailComposeViewController.mailComposeDelegate = self
			
			let infoDictionary = Bundle.main.infoDictionary
			let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
			let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
			
			mailComposeViewController.setSubject("Feedback Vaktija \(version)(\(build))")
			mailComposeViewController.setToRecipients(["ios@vaktija.ba"])
			
			navigationController?.present(mailComposeViewController, animated: true, completion: nil)
		} else {
			let alertController = UIAlertController(title: "Greška", message: "Da bi ste mogli da pošaljete feedback, potrebno je da imate bar jedan email račun postavljen.", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "Zatvori", style: .cancel, handler: nil))
			
			navigationController?.present(alertController, animated: true, completion: nil)
		}
	}
	
	@available(iOS, deprecated: 11.0)
	private func postToFacebook(content: String) {
		dismiss(animated: true, completion: {
			if SLComposeViewController.isAvailable(forServiceType: SLServiceTypeFacebook) {
				let alertController = UIAlertController(title: "Facebook", message: "Zbog novih uslova koje nudi Facebook, morat ćete kopirati text ispod, a zatim kada se Facebook Post Screen otvori, priljepiti (paste) isti.\n\n\(content)", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "Zatvori", style: .cancel, handler: nil))
				alertController.addAction(UIAlertAction(title: "Kopiraj", style: .default, handler: { [weak self] (action) in
					let pasteBoard = UIPasteboard.general
					pasteBoard.string = content
					let facebookComposeVC = SLComposeViewController(forServiceType: SLServiceTypeFacebook)
					facebookComposeVC?.setInitialText(content)
					if let image = UIImage(named: "logo_small") {
						facebookComposeVC?.add(image)
					}
					if let url = URL(string: self?.dataSource.shareLink ?? "") {
						facebookComposeVC?.add(url)
					}
					
					self?.present(facebookComposeVC!, animated: true, completion: nil)
				}))
				
				self.present(alertController, animated: true, completion: nil)
			} else {
				let alertController = UIAlertController(title: "", message: "You are not connected to your Facebook account.", preferredStyle: .alert)
				alertController.addAction(UIAlertAction(title: "Close", style: .cancel, handler: nil))
				
				self.present(alertController, animated: true, completion: nil)
			}
		})
	}
}

// MARK: - Activity Item Source

extension SettingsTableViewController: UIActivityItemSource {
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
		hijriDateString += ". " + dataSource.hijriMonths[hijriDateComponents.month!] + " "
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
		
		if activityType == .postToFacebook {
			if #available(iOS 11.0, *) {
				return content
			} else {
				postToFacebook(content: content)
				return ""
			}
		} else {
			return content
		}
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        let infoDictionary = Bundle.main.infoDictionary
        let bundleName = infoDictionary!["CFBundleName"] as! String
        
        return bundleName
    }
	
	@available(iOS 13.0, *)
	func activityViewControllerLinkMetadata(_: UIActivityViewController) -> LPLinkMetadata? {
		return dataSource.metadata
	}
}

// MARK: - Mail Compose View Controller Delegates

extension SettingsTableViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}

extension SettingsTableViewController {
	struct SettingsDataSource {
		var data: [Setting]
		var hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
		let shareLink = "https://itunes.apple.com/us/app/vaktija.ba/id1095343967?ls=1&mt=8"
		@available(iOS 13.0, *)
		lazy var metadata: LPLinkMetadata = {
			let metadata = LPLinkMetadata()
			metadata.originalURL = URL(string: shareLink)
			metadata.url = metadata.originalURL
			metadata.title = "Vaktija.ba na AppStore-u"
			metadata.imageProvider = NSItemProvider.init(contentsOf:
			Bundle.main.url(forResource: "app_thumbnail", withExtension: "png"))
			return metadata
		}()
		var locationName: String {
			let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
			let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
			locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
			var locations:[VBLocation] = []
			
			do {
				locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
			} catch {
				print(error)
			}
			
			return locations.first?.location ?? ""
		}
		
		init() {
			self.data = []
			let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
			// Location
			let locationItem = Setting.SettingItem(id: .location, title: nil, subtitle: nil, value: locationName)
			self.data.append(Setting(id: .location, title: "Lokacija", items: [locationItem]))
			// Dhuhr
			let isDhuhrOn = userDefaults?.bool(forKey: "isStandardDhuhrTime") ?? false
			let dhuhrSubtitle = getDhuhrDetails(isOn: isDhuhrOn)
			let dhuhrItem = Setting.SettingItem(id: .dhuhr, title: "Vrijeme podne namaza", subtitle: dhuhrSubtitle, value: isDhuhrOn)
			let isJummahOn = userDefaults?.bool(forKey: "isJumuahSettingOn") ?? false
			let jummahSubtitle = getJummahDetails(isOn: isJummahOn)
			let jummahItem = Setting.SettingItem(id: .jummah, title: "Posebne postavke za džumu", subtitle: jummahSubtitle, value: isJummahOn)
			self.data.append(Setting(id: .dhuhr, title: "Podne namaz", items: [dhuhrItem, jummahItem]))
			// Share
			let shareItem = Setting.SettingItem(id: .share, title: "Podijeli", subtitle: "Email, SMS, chat", value: nil)
			self.data.append(Setting(id: .social, title: "Social", items: [shareItem]))
			// Application
			let contactItem = Setting.SettingItem(id: .feedback, title: "Kontakt", subtitle: "Pošalji prijedlog, prijavi bug...", value: nil)
			let infoDictionary = Bundle.main.infoDictionary
			let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
			let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
			let versionItem = Setting.SettingItem(id: .version, title: "Verzija", subtitle: "Version \(version) (build: \(build))", value: nil)
			self.data.append(Setting(id: .app, title: "Aplikacija", items: [contactItem, versionItem]))
		}
		
		func getDhuhrDetails(isOn: Bool) -> String {
			return isOn ? "Standardno vrijeme (12h/13h)." : "Stvarno vrijeme"
		}
		
		func getJummahDetails(isOn: Bool) -> String {
			return isOn ? "Koristit će se posebne postavke za džumu." : "Neće biti razlike između postavki za podne i džumu."
		}
		
		func saveChanges() -> Bool {
			var thereWereChanges = false
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            let isStandardDhuhrTime = userDefaults?.bool(forKey: "isStandardDhuhrTime") ?? false
			let isDhuhrOn = data.first { $0.id == .dhuhr }?.items.first { $0.id == .dhuhr }?.value as? Bool ?? false
            if isStandardDhuhrTime != isDhuhrOn {
				userDefaults?.set(isDhuhrOn, forKey: "isStandardDhuhrTime")
                thereWereChanges = true
            }
            
            let isJumuahSettingOn = userDefaults?.bool(forKey: "isJumuahSettingOn") ?? false
			let isJummahOn = data.first { $0.id == .dhuhr }?.items.first { $0.id == .jummah }?.value as? Bool ?? false
            if isJumuahSettingOn != isJummahOn {
				userDefaults?.set(isJummahOn, forKey: "isJumuahSettingOn")
                thereWereChanges = true
            }
			return thereWereChanges
		}
	}
	
	struct Setting {
		enum Id {
			case location
			case dhuhr
			case social
			case app
		}
		let id: Id
		let title: String
		var items: [SettingItem]
		
		struct SettingItem {
			enum Id {
				case location
				case dhuhr
				case jummah
				case share
				case feedback
				case version
			}
			let id: Id
			let title: String?
			var subtitle: String?
			var value: Any?
		}
	}
}
