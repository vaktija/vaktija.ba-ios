//
//  WidgetPrayerFooterView.swift
//  VaktijaWidget
//
//

import UIKit

class WidgetPrayerFooterView: UITableViewHeaderFooterView {
	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var locationLabel: UILabel!
	
	static let reuseIdentifier: String = "WidgetPrayerFooterView"
	static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.backgroundView = UIView(frame: self.bounds)
		self.backgroundView?.backgroundColor = .clear
	}
}
