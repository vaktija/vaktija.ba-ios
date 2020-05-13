//
//  RemarksTableViewController.swift
//  Vaktija.ba
//
//

import UIKit

class RemarksTableViewController: UITableViewController {
	private lazy var dataSource: RemarksTableViewDataSource = {
		return RemarksTableViewDataSource()
	}()
	
    // MARK: - View's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
		navigationItem.title = "Napomene"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220.0
        
		tableView.register(TableViewHeaderView.nib, forHeaderFooterViewReuseIdentifier: TableViewHeaderView.reuseIdentifier)
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
		return dataSource.data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "RemarkTableViewCell", for: indexPath)
		
		// Configure the cell...
		cell.backgroundColor = UIColor.backgroundColor
		cell.textLabel?.attributedText = dataSource.data[indexPath.section].summary
		
		return cell
    }
}

// MARK - Table View Delegates

extension RemarksTableViewController {
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
}

extension RemarksTableViewController {
	private struct RemarksTableViewDataSource {
		lazy var data: [RemarksData] = {
			var data: [RemarksData] = []
			
			// Notifications
			data.append(RemarksData(title: "Notifikacije", summary: createNotificationsAttributedString()))
			
			// Alarms
			data.append(RemarksData(title: "Alarmi", summary: createAlarmsAttributedString()))
			
			// Silent mode
			data.append(RemarksData(title: "Silent (tihi) mod", summary: createSilentModeAttributedString()))
			
			// Do Not Disturb
			data.append(RemarksData(title: "Do Not Disturb (DND)", summary: createDoNotDisturbAttributedString()))
			
			// Hijri dates
			data.append(RemarksData(title: "Hidžretski datumi", summary: createHijriDatesAttributedString()))
			return data
		}()
		private let regularFont = UIFont(font: .regular, size: 16.0)
		private let boldFont = UIFont(font: .bold, size: 16.0)
		private let italicFont = UIFont(font: .oblique, size: 16.0)
		
		private lazy var attributes: [NSAttributedString.Key: Any] = {
			let paragraphStyle = NSMutableParagraphStyle()
			paragraphStyle.alignment = .center
			return [.paragraphStyle: paragraphStyle as Any, .font: regularFont as Any, .foregroundColor: UIColor.titleColor as Any]
		}()
		
		private mutating func createNotificationsAttributedString() -> NSAttributedString {
			let boldOne = "limit za rezervisanje notifikacija je 64"
			let boldTwo = "onda maksimalan broj dana za kojih se može rezervisat notifikacija je 5"
			let boldThree = "u toku 5 dana aplikacija barem jedan put otvorila"
			let string =
			"""
			Postoji ograničenje na iOS-ovim uređajima što se tiče notifikacija.
			
			Naime, \(boldOne).
			
			Što znači, ako su uključene sve notifikacije, za zvaki namaz i alarm i notifikacija, \(boldTwo).
			
			Da bi se ova restrikcija prevažišla bilo bi dobro ako bi se \(boldThree), da bi se moglo rezervisati dodanih notifikacija i produžiti broj dana za koje će se alarmi okidati.
			"""
			let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
			let nsString = (string as NSString)
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldOne))
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldTwo))
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldThree))
			return attributedString
		}
		
		private mutating func createAlarmsAttributedString() -> NSAttributedString {
			let boldOne = "Dužina zvuka alarma je ograničena na 30 sekundi"
			let string =
			"""
			\(boldOne) (iOS restrikcija), tako da se ne mogu postaviti alarmi kao što je ezan, jer on traje duže od 30 sekundi.
			"""
			let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
			let nsString = (string as NSString)
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldOne))
			return attributedString
		}
		
		private mutating func createSilentModeAttributedString() -> NSAttributedString {
			let boldOne = "silent (tihi) mod uključen, zvuk alarma i notifikacije biti će nečujni"
			let string =
			"""
			Kada je \(boldOne), a bit će uključena vibracija, koja će se okinuti samo jedanput.
			
			Treba povesti pažnju kada želite da uključite alarm, da je i silent (tihi) mode isključen, u protivnom alarm neće biti čujan.
			"""
			let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
			let nsString = (string as NSString)
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldOne))
			return attributedString
		}
		
		private mutating func createDoNotDisturbAttributedString() -> NSAttributedString {
			let boldOne = "Do Not Disturb"
			let italicOne = "DND, Ne Ometaj, Ne Smetaj, Ne Uznemiravaj"
			let boldTwo = "DND uključen, zvuk alarma i notifikacije biti će nečujni"
			let boldThree = "DND"
			let string =
			"""
			\(boldOne) (\(italicOne)) mod ima iste karakteristike kao Silent (tihi) mode.
			
			Kada je \(boldTwo), a bit će uključena vibracija, koja će se okinuti samo jedanput.
			
			Treba povesti pažnju kada želite da uključite alarm, da je i \(boldThree) isključen, u protivnom alarm neće biti čujan.
			"""
			let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
			let nsString = (string as NSString)
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldOne))
			attributedString.addAttribute(.font, value: italicFont, range: nsString.range(of: italicOne))
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldTwo))
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldThree, options: .backwards))
			return attributedString
		}
		
		private mutating func createHijriDatesAttributedString() -> NSAttributedString {
			let boldOne = "različiti metodi za računanje hidžretskih datuma"
			let boldTwo = "na dva različita dana za dvije različite muslimanske skupine"
			let string =
			"""
			Postoje \(boldOne). Zbog toga se dešava da npr. Bajram bude \(boldTwo).
			
			Treba ovo uzeti u obzir u slučaju da se datumi u ovoj aplikaciji ne poklapaju sa datumima i odlukama nekih islamskih ulema.
			"""
			let attributedString = NSMutableAttributedString(string: string, attributes: attributes)
			let nsString = (string as NSString)
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldOne))
			attributedString.addAttribute(.font, value: boldFont, range: nsString.range(of: boldTwo))
			return attributedString
		}
	}
	
	struct RemarksData {
		let title: String
		let summary: NSAttributedString
	}
}
