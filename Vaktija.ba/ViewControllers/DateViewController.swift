//
//  DateViewController.swift
//  Vaktija.ba
//
//

import UIKit

class DateViewController: UIViewController {
	@IBOutlet weak var pickerView: UIPickerView!
	@IBOutlet weak var pickerViewLeadingLayoutConstraint: NSLayoutConstraint!
	@IBOutlet weak var pickerViewTrailingLayoutConstraint: NSLayoutConstraint!
	
	private lazy var calendar: Calendar = {
		var calendar = Calendar(identifier: .gregorian)
		calendar.locale = Locale(identifier: "bs_BA")
		calendar.timeZone = TimeZone.autoupdatingCurrent
		return calendar
	}()
	
	private let dayComponent = 0
	private let monthComponent = 1
	private let yearComponent = 2
	
	private var days: [Int] = []
	private var months: [String] {
		return calendar.monthSymbols
	}
	private let years: [Int] = Array(1...10000)
	
	private var selectedDay: Int {
		return pickerView.selectedRow(inComponent: dayComponent) + 1
	}
	private var selectedMonth: Int {
		return pickerView.selectedRow(inComponent: monthComponent) + 1
	}
	private var selectedYear: Int {
		return pickerView.selectedRow(inComponent: yearComponent) + 1
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
		navigationItem.title = "Odaberi datum"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Prikaži", style: .plain, target: self, action: #selector(showBarButtonItemClick(_:)))
		view.backgroundColor = UIColor.backgroundColor
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		setupConstraints()
		setDaysOnAppear()
		prepareData()
	}
    
    @objc private func showBarButtonItemClick(_ sender: UIBarButtonItem) {
		let dateComponents = DateComponents(year: selectedYear, month: selectedMonth, day: selectedDay)
		if let pickedDate = calendar.date(from: dateComponents) {
			let dateScheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "DateScheduleTableViewController") as! DateScheduleTableViewController
			dateScheduleTableViewController.pickedDate = pickedDate
			
			navigationController?.pushViewController(dateScheduleTableViewController, animated: true)
		}
    }
	
	private func prepareData() {
		let now = Date()
		let dayIndex = calendar.component(.day, from: now) - 1
		let monthIndex = calendar.component(.month, from: now) - 1
		let yearIndex = calendar.component(.year, from: now) - 1
		
		pickerView.selectRow(dayIndex, inComponent: dayComponent, animated: false)
		pickerView.selectRow(monthIndex, inComponent: monthComponent, animated: false)
		pickerView.selectRow(yearIndex, inComponent: yearComponent, animated: false)
	}
	
	private func setDaysOnAppear()  {
		let now = Date()
		let year = calendar.component(.year, from: now)
		let month = calendar.component(.month, from: now)
		let dateComponents = DateComponents(year: year, month: month, day: 1)
		var numberOfDaysInMonth = 30
		if let date = calendar.date(from: dateComponents) {
		   numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 0
		}
		days = Array(1...numberOfDaysInMonth)
		pickerView.reloadComponent(dayComponent)
   }
	
	private func setDaysOnPickerScroll()  {
		let dateComponents = DateComponents(year: selectedYear, month: selectedMonth, day: 1)
		var numberOfDaysInMonth = 30
		if let date = calendar.date(from: dateComponents) {
			numberOfDaysInMonth = calendar.range(of: .day, in: .month, for: date)?.count ?? 0
		}
		days = Array(1...numberOfDaysInMonth)
		pickerView.reloadComponent(dayComponent)
   }
	
	private func hideSelectionLines() {
		let count = pickerView.subviews.count
		if 1 < count {
			pickerView.subviews[1].isHidden = true
		}
		if 2 < count {
			pickerView.subviews[2].isHidden = true
		}
	}
	
	private func setupConstraints() {
		let pickerViewWidth = pickerView.frame.width
		let multiplier: CGFloat = pickerViewWidth/375.0
		let constant: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100.0 : 0.0
		pickerViewLeadingLayoutConstraint.constant = 15.0*multiplier + constant
		pickerViewTrailingLayoutConstraint.constant = 15.0*multiplier + constant
	}
}

extension DateViewController: UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		hideSelectionLines()
		return 3
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch component {
		case dayComponent:
			return days.count
		case monthComponent:
			return months.count
		case yearComponent:
			return years.count
		default:
			return 0
		}
	}
}

extension DateViewController: UIPickerViewDelegate {
	func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
		var value: String = ""
		switch component {
		case dayComponent:
			value = String(days[row])
		case monthComponent:
			value = months[row].capitalized
		case yearComponent:
			value = String(years[row])
		default:
			break
		}
		
		guard let titleLabel = view as? UILabel else {
            let titleLabel = UILabel()
			titleLabel.font = UIFont(font: .regular, size: 23.0)
			titleLabel.textAlignment = .center
			titleLabel.textColor = UIColor.titleColor
            titleLabel.text = value
            return titleLabel
        }

		titleLabel.text = value
		return titleLabel
	}
	
	func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		let width = pickerView.frame.width
		switch component {
		case dayComponent:
			return width*0.15
		case monthComponent:
			return width*0.55
		case yearComponent:
			return width*0.30
		default:
			return 0
		}
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		setDaysOnPickerScroll()
	}
}
