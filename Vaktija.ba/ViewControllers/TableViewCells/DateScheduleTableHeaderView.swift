//
//  DateScheduleTableHeaderView.swift
//  Vaktija.ba
//
//

import UIKit

class DateScheduleTableHeaderView: UIView
{
    @IBOutlet var headerLabel: UILabel?
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        headerLabel?.preferredMaxLayoutWidth = headerLabel!.frame.width
    }
}
