//
//  WidgetPrayerHeaderView.swift
//  VaktijaWidget
//
//

import UIKit

class WidgetPrayerHeaderView: UITableViewHeaderFooterView {
	@IBOutlet weak var nextPrayerLabel: UILabel!
	@IBOutlet weak var showMoreButton: UIButton!
	var showMoreButtonOnPress: ((UIButton) -> Void)?
	
	static let reuseIdentifier: String = "WidgetPrayerHeaderView"
	static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		self.backgroundView = UIView(frame: self.bounds)
		self.backgroundView?.backgroundColor = .clear
	}
	
	@IBAction func showMoreButtonPressed(_ sender: UIButton) {
		showMoreButtonOnPress?(sender)
	}
}
