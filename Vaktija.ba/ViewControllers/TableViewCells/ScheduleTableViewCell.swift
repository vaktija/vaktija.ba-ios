//
//  ScheduleTableViewCell.swift
//  Vaktija.ba
//
//

import UIKit

class ScheduleTableViewCell: UITableViewCell
{
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var alarmImageView: UIImageView!
    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var alarmImageViewTrailingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackViewWidthLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewLeadingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var separatorViewTrailingLayoutConstraint: NSLayoutConstraint!
    
    override func awakeFromNib()
    {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
