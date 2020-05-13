//
//  TodayViewController.swift
//  VaktijaWidget
//
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController {
	@IBOutlet weak var tableView: UITableView!
    
    private var displayMode: VBWidgetDisplayMode = .compact
	private var compactData: [(prayer: VBPrayer.PrayerTime, schedule: VBSchedule)] = []
	private var expandedData: [(prayer: VBPrayer.PrayerTime, schedule: VBSchedule)] = []
    
    private let expandedHeight: CGFloat = 230.0
    private let compactHeight: CGFloat = 110.0
	private let cellHeight: CGFloat = 24.0
	private let headerHeight: CGFloat = 28.0
    
    var timer: Timer?
	var timeData: TimeData?
    
    // MARK: - Widget's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
		
		tableView.register(WidgetPrayerHeaderView.nib, forHeaderFooterViewReuseIdentifier: WidgetPrayerHeaderView.reuseIdentifier)
		tableView.register(WidgetPrayerFooterView.nib, forHeaderFooterViewReuseIdentifier: WidgetPrayerFooterView.reuseIdentifier)
        
        if #available(iOSApplicationExtension 10.0, *) {
            extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOSApplicationExtension 10.0, *) {
            if extensionContext?.widgetActiveDisplayMode == .expanded {
				displayMode = .expanded
                preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
            } else {
				displayMode = .compact
                preferredContentSize = extensionContext!.widgetMaximumSize(for: .compact)
            }
        } else {
            if displayMode == .expanded {
                preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
            } else {
                preferredContentSize = CGSize(width: preferredContentSize.width, height: compactHeight)
            }
        }
        
        prepareData()
    }
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		let updatedVisibleCellCount = numberOfTableRowsToDisplay()
		let currentVisibleCellCount = self.tableView.visibleCells.count
		let cellCountDifference = updatedVisibleCellCount - currentVisibleCellCount
		
		guard abs(cellCountDifference) == 5 else {
			tableView.reloadData()
			return
		}
		// If the number of visible cells has changed, animate them in/out along with the resize animation.
		coordinator.animate(alongsideTransition: { [unowned self] (UIViewControllerTransitionCoordinatorContext) in
			// Build an array of IndexPath objects representing the rows to be inserted or deleted.
			let range = (1...abs(cellCountDifference))
			let indexPaths = range.map({ (index) -> IndexPath in
				return IndexPath(row: index, section: 0)
			})
			if #available(iOSApplicationExtension 11.0, *) {
				self.tableView.performBatchUpdates({
					// Animate the reload of the first row
					self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
					// Animate the insertion or deletion of the rows.
					if cellCountDifference > 0 {
						self.tableView.insertRows(at: indexPaths, with: .fade)
					} else {
						self.tableView.deleteRows(at: indexPaths, with: .fade)
					}
				}, completion: nil)
			} else {
				// Fallback on earlier versions
				self.tableView.beginUpdates()
				// Animate the reload of the first row
				self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
				// Animate the insertion or deletion of the rows.
				if cellCountDifference > 0 {
					self.tableView.insertRows(at: indexPaths, with: .fade)
				} else {
					self.tableView.deleteRows(at: indexPaths, with: .fade)
				}
				self.tableView.endUpdates()
			}
		}, completion: nil)
	}
    
    // MARK: - Gesture Functions
    
    @IBAction func widgetViewTapGestureRecognizerClick(_ sender: UITapGestureRecognizer) {
        extensionContext?.open(URL(string: "vaktijaba://")!, completionHandler: nil)
    }
    
    // MARK: - Private Functions
    
    fileprivate func prepareData() {
        // Schedule for current date
        
        let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
        
        let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
        schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
		
		guard let schedule = (try? VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as? [VBSchedule])?.first else {
			return
		}
        
        let (currentSchedulePrayerTime, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule)
		
		let nextPrayerTimeIndex = (currentScheduleIndex + 1)%6
		let nextSchedulePrayerTime = VBPrayer.prayerTimeForIndex(nextPrayerTimeIndex, schedule: schedule)
		let nextPrayerTimeString = VBPrayer.prayerName(forPrayerTime: nextSchedulePrayerTime).capitalizedFirst
		let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule, prayerTime: nextSchedulePrayerTime).components
		
		timeData = TimeData(schedule: schedule, label: timeData?.label, nextPrayerTitle: nextPrayerTimeString, components: components)
		
		compactData.removeAll()
		compactData.append((prayer: currentSchedulePrayerTime, schedule: schedule))
		compactData.append((prayer: nextSchedulePrayerTime, schedule: schedule))
		
		expandedData.removeAll()
		let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
		let jumuah = userDefaults!.bool(forKey: "isJumuahSettingOn") && VBPrayer.isJumuah(Date())
		let prayers: [VBPrayer.PrayerTime] = [.Fajr, .Sunrise, jumuah ? .Jumuah : .Dhuhr, .Asr, .Maghrib, .Isha]
		for prayer in prayers {
			expandedData.append((prayer: prayer, schedule: schedule))
		}
		
		tableView.reloadData()
    }
    
    @objc
	private func timeRemainingTick() {
		guard let timer = timer, timer.isValid else {
			return
		}
		
		guard let timeData = timeData else {
			return
		}
		
		var timeInSeconds = Int(timeData.components[0])!*3600 + Int(timeData.components[1])!*60 + Int(timeData.components[2])!
		
		timeInSeconds = timeInSeconds - 1
		
		if timeInSeconds == 0 {
			let dateComponents = Calendar.current.dateComponents([.day, .month], from: Date())
			
			let schedulesFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBSchedule")
			schedulesFetchRequest.predicate = NSPredicate(format: "day == %d AND month == %d", dateComponents.day!, dateComponents.month!)
			
			let schedule = (try? VBCoreDataStack.sharedInstance.managedObjectContext.fetch(schedulesFetchRequest) as? [VBSchedule])?.first ?? timeData.schedule
			let (_, currentScheduleIndex) = VBPrayer.currentPrayerTimeAndIndex(forSchedule: schedule)
			
			let nextPrayerTimeIndex = (currentScheduleIndex + 1)%6
			let nextPrayerTime = VBPrayer.prayerTimeForIndex(nextPrayerTimeIndex, schedule: schedule)
			let nextPrayerTimeString = VBPrayer.prayerName(forPrayerTime: nextPrayerTime).capitalizedFirst
			
			let components = VBPrayer.remainingPrayerScheduleTimeComponentsToNextPrayerTime(forSchedule: schedule, prayerTime: nextPrayerTime).components
			
			self.timeData = TimeData(schedule: schedule, label: timeData.label, nextPrayerTitle: nextPrayerTimeString, components: components)
			
			prepareData()
			
			self.timer?.invalidate()
			self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick), userInfo: nil, repeats: true)
			
			return
		}
		
		let hours = timeInSeconds/3600
		let minutes = (timeInSeconds%3600)/60
		let seconds = timeInSeconds%60
		var components: [String] = [String(hours), String(minutes), String(seconds)]
		
		if hours < 10 {
			components[0] = "0\(hours)"
		}
		
		if minutes < 10 {
			components[1] = "0\(minutes)"
		}
		
		if seconds < 10 {
			components[2] = "0\(seconds)"
		}
		
		self.timeData?.components = components
		self.timeData?.label?.text = timeData.formattedText()
		
		// If schedule day and current day are not the same
		// data should be updated.
		let scheduleDay = Int(timeData.schedule.day)
		let currentDay = Calendar.current.component(.day, from: Date())
		if currentDay != scheduleDay {
			prepareData()
		}
    }
}

extension TodayViewController {
    enum VBWidgetDisplayMode {
        case compact
        case expanded
    }
	
	struct TimeData {
		var schedule: VBSchedule
		var label: UILabel?
		var nextPrayerTitle: String
		var components: [String] = Array(repeating: "0", count: 3)
		
		func formattedText() -> String {
			return "\(nextPrayerTitle) je za \(components[0])h \(components[1])m."
		}
	}
}

extension TodayViewController: NCWidgetProviding {
	func widgetPerformUpdate(completionHandler: ((NCUpdateResult) -> Void)) {
        prepareData()
        
        completionHandler(NCUpdateResult.newData)
    }
    
    @available(iOSApplicationExtension 10.0, *)
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
			displayMode = .expanded
            preferredContentSize = CGSize(width: preferredContentSize.width, height: expandedHeight)
        } else {
			displayMode = .compact
            preferredContentSize = maxSize
        }
    }
    
	@available(iOSApplicationExtension, deprecated: 10.0)
    func widgetMarginInsets(forProposedMarginInsets defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
}

extension TodayViewController: UITableViewDataSource {
	private func numberOfTableRowsToDisplay() -> Int {
		switch displayMode {
		case .compact:
			return 1
		case .expanded:
			return expandedData.count
		}
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return numberOfTableRowsToDisplay()
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch displayMode {
		case .compact:
			if let cell = tableView.dequeueReusableCell(withIdentifier: CompactPrayerTableViewCell.reuseIdentifier, for: indexPath) as? CompactPrayerTableViewCell {
				if let previous = compactData.first, let next = compactData.last {
					let previousName = previous.prayer == .Sunrise ? "Izl. sunca" : VBPrayer.prayerName(forPrayerTime: previous.prayer).capitalizedFirst
					let previousTime = VBPrayer.displayPrayerScheduleTime(forSchedule: previous.schedule, prayerTime: previous.prayer)
					let nextName = next.prayer == .Sunrise ? "Izl. sunca" : VBPrayer.prayerName(forPrayerTime: next.prayer).capitalizedFirst
					let nextTime = VBPrayer.displayPrayerScheduleTime(forSchedule: next.schedule, prayerTime: next.prayer)
					
					cell.previousNameLabel.text = previousName
					cell.previousTimeLabel.text = previousTime
					cell.nextNameLabel.text = nextName
					cell.nextTimeLabel.text = nextTime
				}
				return cell
			}
		case .expanded:
			if let cell = tableView.dequeueReusableCell(withIdentifier: ExpandedPrayerTableViewCell.reuseIdentifier, for: indexPath) as? ExpandedPrayerTableViewCell {
				let data = expandedData[indexPath.row]
				cell.timeLabel.text = VBPrayer.displayPrayerScheduleTime(forSchedule: data.schedule, prayerTime: data.prayer)
				cell.prayerLabel.text = data.prayer == .Sunrise ? "Izl. sunca" : VBPrayer.prayerName(forPrayerTime: data.prayer).capitalizedFirst
				return cell
			}
		}
		return UITableViewCell()
	}
	
	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		guard section == 0, let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WidgetPrayerHeaderView.reuseIdentifier) as? WidgetPrayerHeaderView else {
			return UIView(frame: CGRect.zero)
		}
		
		timeData?.label = headerView.nextPrayerLabel
		headerView.nextPrayerLabel.text = timeData?.formattedText()
		
		timer?.invalidate()
		
		timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timeRemainingTick), userInfo:nil, repeats: true)
		
		if #available(iOSApplicationExtension 10.0, *) {
			headerView.showMoreButton.isHidden = true
		} else {
			headerView.showMoreButton.setTitle((displayMode == .compact ? "Show More" : "Show Less"), for: .normal)
			headerView.showMoreButtonOnPress = { [unowned self] sender in
				self.displayMode = (self.displayMode == .compact ? .expanded : .compact)
				let title: String
				let size: CGSize
				switch self.displayMode {
				case .compact:
					title = "Show More"
					size = CGSize(width: self.preferredContentSize.width, height: self.compactHeight)
				case .expanded:
					title = "Show Less"
					size = CGSize(width: self.preferredContentSize.width, height: self.expandedHeight)
				}
				sender.setTitle(title, for: .normal)
				self.preferredContentSize = size
			}
		}
		
		return headerView
	}
	
	func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		guard section == 0, let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: WidgetPrayerFooterView.reuseIdentifier) as? WidgetPrayerFooterView else {
			return UIView(frame: CGRect.zero)
		}
		
		// Date Label
        
        let hijriMonths = ["", "Muharrem", "Safer", "Rebiu-l-evvel", "Rabiu-l-ahir", "Džumade-l-ula", "Džumade-l-uhra", "Redžeb", "Ša'ban", "Ramazan", "Ševval", "Zu-l-ka'de", "Zu-l-hidždže"]
        let hijriCalendar = Calendar(identifier: Calendar.Identifier.islamicUmmAlQura)
        let hijriDateComponents = hijriCalendar.dateComponents([.day, .month, .year], from: Date())
        
        let hijriDateString = (hijriDateComponents.day! < 10 ? "0" : "") + String(describing: hijriDateComponents.day!) + ". " + hijriMonths[hijriDateComponents.month!] + " " + String(describing: hijriDateComponents.year!) + ". h."
		footerView.dateLabel.text = hijriDateString.lowercased()
        
        // Location Label
        
		let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
		let location = (try? VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as? [VBLocation])?.first
		footerView.locationLabel.text = location?.location
		
		return footerView
	}
}

extension TodayViewController: UITableViewDelegate {
	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return cellHeight
	}
	
	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return headerHeight
	}
	
	func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return headerHeight
	}
}
