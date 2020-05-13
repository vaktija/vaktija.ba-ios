//
//  TableViewHeaderView.swift
//  Vaktija.ba
//
//

import UIKit

class TableViewHeaderView: UITableViewHeaderFooterView {
	@IBOutlet weak var titleLabel: UILabel!
	
	static let reuseIdentifier: String = "TableViewHeaderView"
	static var nib: UINib {
        return UINib(nibName: String(describing: self), bundle: nil)
    }
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let backgroundView = UIView(frame: self.bounds)
		backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		backgroundView.backgroundColor = UIColor.backgroundColor
		self.backgroundView = backgroundView
		
		titleLabel.textColor = UIColor.titleColor
	}

}
