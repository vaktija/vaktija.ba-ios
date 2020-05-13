//
//  DateScheduleTableHeaderView.swift
//  Vaktija.ba
//
//

import UIKit

class DateScheduleTableHeaderView: UITableViewHeaderFooterView {
    @IBOutlet var headerLabel: UILabel?
	
	override func awakeFromNib() {
		super.awakeFromNib()
		
		let backgroundView = UIView(frame: self.bounds)
		backgroundView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		backgroundView.backgroundColor = UIColor.backgroundColor
		self.backgroundView = backgroundView
		
		headerLabel?.textColor = UIColor.titleColor
	}
	
    override func layoutSubviews() {
        super.layoutSubviews()
        
        headerLabel?.preferredMaxLayoutWidth = headerLabel!.frame.width
    }
}
