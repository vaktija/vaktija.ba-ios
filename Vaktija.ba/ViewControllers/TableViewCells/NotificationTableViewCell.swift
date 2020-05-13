//
//  NotificationTableViewCell.swift
//  Vaktija.ba
//
//

import UIKit

class NotificationTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stateSwitch: UISwitch!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var offsetSlider: UISlider!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		backgroundColor = UIColor.backgroundColor
		titleLabel.textColor = UIColor.titleColor
		detailsLabel.textColor = UIColor.titleColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
