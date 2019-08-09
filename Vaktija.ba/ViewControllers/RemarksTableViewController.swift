//
//  RemarksTableViewController.swift
//  Vaktija.ba
//
//

import UIKit

class RemarksTableViewController: UITableViewController
{
    // MARK: - View's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Napomene"
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 220.0
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 5
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        if section == 0
        {
            return "Notifikacije"
        }
        else if section == 1
        {
            return "Alarmi"
        }
        else if section == 2
        {
            return "Silent (tihi) mod"
        }
        else if section == 3
        {
            return "Do Not Disturb (DND)"
        }
        else if section == 4
        {
            return "Hidžretski datumi"
        }
        
        return ""
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        if indexPath.section == 0
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath)
            
            // Configure the cell...
            
            return cell
        }
        else if indexPath.section == 1
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmCell", for: indexPath)
            
            // Configure the cell...
            
            return cell
        }
        else if indexPath.section == 2
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SilentModeCell", for: indexPath)
            
            // Configure the cell...
            
            return cell
        }
        else if indexPath.section == 3
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DNDCell", for: indexPath)
            
            // Configure the cell...
            
            return cell
        }
        else if indexPath.section == 4
        {
            let cell = tableView.dequeueReusableCell(withIdentifier: "HijriDatesCell", for: indexPath)
            
            // Configure the cell...
            
            return cell
        }
        
        return UITableViewCell()
    }
}
