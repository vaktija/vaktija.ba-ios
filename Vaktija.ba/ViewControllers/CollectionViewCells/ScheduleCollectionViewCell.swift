//
//  ScheduleCollectionViewCell.swift
//  Vaktija.ba
//
//

import UIKit

class ScheduleCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var timeRemainingLabel: UILabel!
    @IBOutlet weak var alarmImageView: UIImageView!
    @IBOutlet weak var notificationImageView: UIImageView!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var alarmImageViewTrailingLayoutConstraint: NSLayoutConstraint!
    @IBOutlet weak var notificationImageViewTrailingLayoutConstraint: NSLayoutConstraint!
    
    weak var delegate: ScheduleCollectionViewCellDelegate?
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool
    {
        if action == #selector(skipAlarm(_:))
        {
            if !alarmImageView.isHidden && alarmImageView.tag == 0
            {
                return true
            }
            
            return false
        }
        else if action == #selector(skipNotification(_:))
        {
            if !notificationImageView.isHidden && notificationImageView.tag == 0
            {
                return true
            }
            
            return false
        }
        else if action == #selector(turnAlarm(_:))
        {
            if !alarmImageView.isHidden && alarmImageView.tag == 1
            {
                return true
            }
            
            return false
        }
        else if action == #selector(turnNotification(_:))
        {
            if !notificationImageView.isHidden && notificationImageView.tag == 1
            {
                return true
            }
            
            return false
        }
        else if action == #selector(showScheduleSettings(_:))
        {
            return true
        }
        
        return false
    }
    
    @objc func skipAlarm(_ sender: UIMenuController)
    {
        delegate?.scheduleCollectionViewCellSkipAlarm(self)
    }
    
    @objc func turnAlarm(_ sender: UIMenuController)
    {
        delegate?.scheduleCollectionViewCellSkipAlarm(self)
    }
    
    @objc func skipNotification(_ sender: UIMenuController)
    {
        delegate?.scheduleCollectionViewCellSkipNotification(self)
    }
    
    @objc func turnNotification(_ sender: UIMenuController)
    {
        delegate?.scheduleCollectionViewCellSkipNotification(self)
    }
    
    @objc func showScheduleSettings(_ indexPath: IndexPath)
    {
        delegate?.scheduleCollectionViewCellShowScheduleSettings(self)
    }
}

protocol ScheduleCollectionViewCellDelegate: class
{
    func scheduleCollectionViewCellSkipAlarm(_ cell: ScheduleCollectionViewCell)
    func scheduleCollectionViewCellSkipNotification(_ cell: ScheduleCollectionViewCell)
    func scheduleCollectionViewCellShowScheduleSettings(_ cell: ScheduleCollectionViewCell)
}
