//
//  SettingsTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData
import MessageUI

class SettingsTableViewController: UITableViewController, MFMailComposeViewControllerDelegate
{
    fileprivate var headers = ["Lokacija", /*"Notifikacije", "Alarm",*/ "Podne namaz", "Aplikacija"]
    fileprivate var isStandardDhuhrTime = false
    fileprivate var isJumuahSettingOn = false
    fileprivate var thereAreChanges = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Postavke"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.estimatedRowHeight = 63.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        isStandardDhuhrTime = userDefaults!.bool(forKey: "isStandardDhuhrTime")
        isJumuahSettingOn = userDefaults!.bool(forKey: "isJumuahSettingOn")
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if !isMovingToParentViewController
        {
            tableView.reloadData()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if isMovingFromParentViewController && thereAreChanges
        {
            var shouldReschedule = false
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            let isStandardDhuhrTimeCurrent = userDefaults!.bool(forKey: "isStandardDhuhrTime") 
            if isStandardDhuhrTimeCurrent != isStandardDhuhrTime
            {
                shouldReschedule = true
            }
            
            let isJumuahSettingOnCurrent = userDefaults!.bool(forKey: "isJumuahSettingOn") 
            if isJumuahSettingOnCurrent != isJumuahSettingOn
            {
                shouldReschedule = true
            }
            
            if shouldReschedule
            {
                VBNotification().scheduleLocalNotifications(true)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return headers.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if section == 0
        {
            return 1
        }
        /*else if section == 1
        {
            return 1
        }
        else if section == 2
        {
            return 1
        }*/
        else if section == 1
        {
            return 2
        }
        else if section == 2
        {
            return 2
        }
        
        return 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return headers[section]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let section = indexPath.section
        let row = indexPath.row
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if section == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingsTableViewCell
            
            // Configure the cell...
            
            if row == 0
            {
                let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
                locationsFetchRequest.predicate = NSPredicate(format: "id == %d", userDefaults!.integer(forKey: "locationId"))
                var locations:[VBLocation] = []
                
                do
                {
                    locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
                }
                catch
                {
                    print(error)
                }
                
                cell.titleLabel.text = (locations.count > 0 ? locations.first?.location : "")
                cell.subtitleLabel.text = ""
                
                cell.accessoryType = .disclosureIndicator
            }
            
            return cell
        }
        /*else if section == 1
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell", forIndexPath: indexPath) as! SettingsTableViewCell
            
            // Configure the cell...
            
            if row == 0
            {
                cell.titleLabel.text = "Zvuk za notifikacije"
                
                cell.subtitleLabel.text = userDefaults!.stringForKey("notificationRingtone")?.componentsSeparatedByString("_").first
                
                cell.accessoryView = nil
                cell.accessoryType = .DisclosureIndicator
            }
            
            return cell
        }
        else if section == 2
        {
            let cell = tableView.dequeueReusableCellWithIdentifier("SettingCell", forIndexPath: indexPath) as! SettingsTableViewCell
            
            // Configure the cell...
            
            if row == 0
            {
                cell.titleLabel.text = "Zvuk za alarm"
                
                cell.subtitleLabel.text = userDefaults!.stringForKey("alarmRingtone")?.componentsSeparatedByString("_").first
                
                cell.accessoryView = nil
                cell.accessoryType = .DisclosureIndicator
            }
            
            return cell
        }*/
        else if section == 1
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingsTableViewCell
            
            // Configure the cell...
            
            if row == 0
            {
                cell.titleLabel.text = "Vrijeme podne namaza"
                
                if userDefaults!.bool(forKey: "isStandardDhuhrTime")
                {
                    cell.subtitleLabel.text = "Standardno vrijeme (12h/13h)"
                }
                else
                {
                    cell.subtitleLabel.text = "Stvarno vrijeme"
                }
                
                let widgetSwitch = UISwitch(frame: CGRect.zero)
                widgetSwitch.addTarget(self, action: #selector(widgetSwitchValueChanged(_:)), for: .valueChanged)
                widgetSwitch.isOn = userDefaults!.bool(forKey: "isStandardDhuhrTime")
                
                cell.accessoryView = widgetSwitch
            }
            else if row == 1
            {
                cell.titleLabel.text = "Posebne postavke za džumu"
                
                if userDefaults!.bool(forKey: "isJumuahSettingOn")
                {
                    cell.subtitleLabel.text = "Koristiti će se posebne postavke za džumu."
                }
                else
                {
                    cell.subtitleLabel.text = "Neće biti razlike između postavki za podne i džumu."
                }
                
                let widgetSwitch = UISwitch(frame: CGRect.zero)
                widgetSwitch.addTarget(self, action: #selector(widgetSwitchValueChanged(_:)), for: .valueChanged)
                widgetSwitch.isOn = userDefaults!.bool(forKey: "isJumuahSettingOn")
                
                cell.accessoryView = widgetSwitch
            }
            
            return cell
        }
        else if section == 2
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingsTableViewCell
            
            // Configure the cell...
            
            if row == 0
            {
                cell.titleLabel.text = "Datum ispod naziva lokacije"
                
                if userDefaults!.bool(forKey: "showDate")
                {
                    cell.subtitleLabel.text = "Datum će se prikazivati."
                }
                else
                {
                    cell.subtitleLabel.text = "Datum se neće prikazivati."
                }
                
                let widgetSwitch = UISwitch(frame: CGRect.zero)
                widgetSwitch.addTarget(self, action: #selector(widgetSwitchValueChanged(_:)), for: .valueChanged)
                widgetSwitch.isOn = userDefaults!.bool(forKey: "showDate")
                
                cell.accessoryView = widgetSwitch
            }
            else if row == 1
            {
                cell.titleLabel.text = "Feedback"
                
                cell.subtitleLabel.text = "Pošalji prijedlog, prijavi bug..."
                
                cell.accessoryView = nil
            }
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    // MARK: - Table view delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0
        {
            if row == 0
            {
                let locationsTableViewController = storyboard?.instantiateViewController(withIdentifier: "LocationsTableViewController")
                
                navigationController?.pushViewController(locationsTableViewController!, animated: true)
            }
        }
        /*else if section == 1
        {
            if row == 0
            {
                let ringtonesTableViewController = storyboard?.instantiateViewControllerWithIdentifier("RingtonesTableViewController") as! RingtonesTableViewController
                ringtonesTableViewController.ringtoneType = .Notification
                
                navigationController?.pushViewController(ringtonesTableViewController, animated: true)
            }
        }
        else if section == 2
        {
            if row == 0
            {
                let ringtonesTableViewController = storyboard?.instantiateViewControllerWithIdentifier("RingtonesTableViewController") as! RingtonesTableViewController
                ringtonesTableViewController.ringtoneType = .Alarm
                
                navigationController?.pushViewController(ringtonesTableViewController, animated: true)
            }
        }*/
        else if section == 2
        {
            if row == 1
            {
                if MFMailComposeViewController.canSendMail()
                {
                    let mailComposeViewController = MFMailComposeViewController()
                    mailComposeViewController.mailComposeDelegate = self
                    
                    let infoDictionary = Bundle.main.infoDictionary
                    let build = infoDictionary!["CFBundleVersion"] as! String
                    let version = infoDictionary!["CFBundleShortVersionString"] as! String
                    
                    mailComposeViewController.setSubject("Feedback Vaktija \(version)(\(build))")
                    mailComposeViewController.setToRecipients(["ios@vaktija.ba"])
                    
                    navigationController?.present(mailComposeViewController, animated: true, completion: nil)
                }
                else
                {
                    let alertController = UIAlertController(title: "Greška", message: "Da bi ste mogli da pošaljete feedback, potrebno je da imate bar jedan email račun postavljen.", preferredStyle: .alert)
                    
                    navigationController?.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
    
    //MARK: - Switch delegates
    
    func widgetSwitchValueChanged(_ sender: UISwitch)
    {
        let cell = sender.superview as! SettingsTableViewCell
        if let indexPath = tableView.indexPath(for: cell)
        {
            let section = indexPath.section
            let row = indexPath.row
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            if section == 1
            {
                if row == 0
                {
                    userDefaults!.set(sender.isOn, forKey: "isStandardDhuhrTime")
                    thereAreChanges = true
                }
                else if row == 1
                {
                    userDefaults!.set(sender.isOn, forKey: "isJumuahSettingOn")
                    thereAreChanges = true
                }
            }
            else if section == 2
            {
                if row == 0
                {
                    userDefaults!.set(sender.isOn, forKey: "showDate")
                }
            }
            
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - Mail Compose View Controller Delegates
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?)
    {
        navigationController?.dismiss(animated: true, completion: nil)
    }
}
