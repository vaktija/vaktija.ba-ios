//
//  CompactPrayerTableViewCell.swift
//  VaktijaWidget
//
//

import UIKit

class CompactPrayerTableViewCell: UITableViewCell {
	@IBOutlet weak var previousNameLabel: UILabel!
	@IBOutlet weak var previousTimeLabel: UILabel!
	@IBOutlet weak var separatorView: UIView!
	@IBOutlet weak var nextTimeLabel: UILabel!
	@IBOutlet weak var nextNameLabel: UILabel!
	
	static let reuseIdentifier: String = "CompactPrayerTableViewCell"
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
