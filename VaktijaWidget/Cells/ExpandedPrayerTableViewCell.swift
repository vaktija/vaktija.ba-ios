//
//  ExpandedPrayerTableViewCell.swift
//  VaktijaWidget
//
//

import UIKit

class ExpandedPrayerTableViewCell: UITableViewCell {
	@IBOutlet weak var timeLabel: UILabel!
	@IBOutlet weak var dashLabel: UILabel!
	@IBOutlet weak var prayerLabel: UILabel!
	
	static let reuseIdentifier: String = "ExpandedPrayerTableViewCell"
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
