//
//  SettingsTableViewCell.swift
//  Vaktija.ba
//
//

import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		backgroundColor = UIColor.backgroundColor
		titleLabel.textColor = UIColor.titleColor
		subtitleLabel.textColor = UIColor.titleColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
