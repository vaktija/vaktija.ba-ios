//
//  SearchTableViewController.swift
//  Vaktija.ba
//
//

import UIKit

class SearchTableViewController: UITableViewController
{
    var thereAreChanges = false
    var selectedIndexPath = IndexPath(row: -1, section: 0)
    var searchResults = [AnyObject]();
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return searchResults.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SearchCell", for: indexPath)

        // Configure the cell...
        
        let result = searchResults[indexPath.row];
        
        if result is VBLocation
        {
            let location = result as! VBLocation
            
            cell.textLabel?.text = location.location
            
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            
            if location.id == Int64(userDefaults!.integer(forKey: "locationId"))
            {
                cell.accessoryType = .checkmark
                selectedIndexPath = indexPath
            }
            else
            {
                cell.accessoryType = .none
            }
        }

        return cell
    }
}
