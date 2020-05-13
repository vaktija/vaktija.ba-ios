//
//  ScheduleTableViewCell.swift
//  Vaktija.ba
//
//

import UIKit

class ScheduleTableViewCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
	
    @IBOutlet weak var nameLabelLeadingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeLabelTrailingLayoutConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		backgroundColor = UIColor.backgroundColor
		timeLabel.textColor = UIColor.subtitleColor
		nameLabel.textColor = UIColor.titleColor
		timeRemainingLabel.textColor = UIColor.titleColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
