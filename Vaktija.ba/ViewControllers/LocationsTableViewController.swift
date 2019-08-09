//
//  LocationsTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData

class LocationsTableViewController: UITableViewController, UISearchResultsUpdating, UISearchControllerDelegate
{
    fileprivate var locations:[VBLocation] = []
    fileprivate var selectedIndexPath = IndexPath(row: -1, section: 0)
    fileprivate var thereAreChanges = false
    fileprivate var thisSearchController: UISearchController?
    
    // MARK: View's Life Cycle
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        title = "Lokacije"
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: true)]
        
        do
        {
            locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
        }
        catch
        {
            print(error)
        }
        
        configSearchController()
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let index = locations.firstIndex(where: {$0.id == Int64(userDefaults!.integer(forKey: "locationId"))})
        
        if let goodIndex = index
        {
            tableView.scrollToRow(at: IndexPath(row: goodIndex, section: 0), at: .middle, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent
        {
            thisSearchController?.view.removeFromSuperview()
            
            if thereAreChanges
            {
                VBNotification().scheduleLocalNotifications(true)
            }
        }
    }
    
    // MARK: - Navigation Bar Functions
    
    @objc func searchBarButtonItemClick(_ sender: UIBarButtonItem)
    {
        if !locations.isEmpty
        {
            if !thisSearchController!.isActive
            {
                thisSearchController?.searchBar.becomeFirstResponder()
            }
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)

        // Configure the cell...
        
        let location = locations[indexPath.row] as VBLocation
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        cell.textLabel?.text = location.location
        
        if location.id == Int64(userDefaults!.integer(forKey: "locationId"))
        {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        }
        else
        {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: Table View Delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        var location: VBLocation? = nil
        var indexPaths = [indexPath]
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
        if tableView == self.tableView
        {
            if selectedIndexPath != indexPath
            {
                location = locations[indexPath.row] as VBLocation
                
                if let index = locations.firstIndex(where: {$0.id == Int64(userDefaults!.integer(forKey: "locationId"))})
                {
                    indexPaths.append(IndexPath(row: index, section: 0))
                }
            }
        }
        else
        {
            let searchTableViewController = thisSearchController?.searchResultsController as! SearchTableViewController
            
            if searchTableViewController.selectedIndexPath != indexPath
            {
                let result = searchTableViewController.searchResults[indexPath.row];
                
                if result is VBLocation
                {
                    location = result as? VBLocation
                    
                    if let index = searchTableViewController.searchResults.firstIndex(where: {$0.id == Int64(userDefaults!.integer(forKey: "locationId"))})
                    {
                        indexPaths.append(IndexPath(row: index, section: 0))
                    }
                    
                    searchTableViewController.thereAreChanges = true
                }
            }
        }
        
        if let goodLocation = location
        {
            userDefaults!.set(Int(goodLocation.id), forKey: "locationId")
            thereAreChanges = true;
            
            tableView.reloadRows(at: indexPaths, with: .none)
            
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: Search Controller Delegates
    
    func willDismissSearchController(_ searchController: UISearchController)
    {
        let searchTableViewController = thisSearchController?.searchResultsController as! SearchTableViewController
        
        if searchTableViewController.thereAreChanges
        {
            let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
            if let index = locations.firstIndex(where: {$0.id == Int64(userDefaults!.integer(forKey: "locationId"))})
            {
                let indexPath = IndexPath(row: index, section: 0)
                
                tableView.scrollToRow(at: indexPath, at: .middle, animated: true)
                tableView.reloadRows(at: [indexPath], with: .none)
            }
            
            searchTableViewController.thereAreChanges = false
            searchTableViewController.selectedIndexPath = IndexPath(item: -1, section: 0)
        }
    }
    
    func updateSearchResults(for searchController: UISearchController)
    {
        let searchTableViewController = thisSearchController?.searchResultsController as! SearchTableViewController
        
        if let searchTerm = searchController.searchBar.text
        {
            if searchTerm.isEmpty
            {
                searchTableViewController.searchResults.removeAll()
            }
            else
            {
                searchTableViewController.searchResults = locations.filter(
                {
                    (location: VBLocation) -> Bool in
                    
                    return location.location!.contains(searchTerm)
                })
            }
        }
        else
        {
            searchTableViewController.searchResults.removeAll()
        }
        searchTableViewController.tableView.reloadData()
    }
    
    // MARK: Private Functions
    
    fileprivate func configSearchController()
    {
        definesPresentationContext = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchBarButtonItemClick(_:)))
        
        let searchTableViewController = storyboard?.instantiateViewController(withIdentifier: "SearchTableViewController") as! SearchTableViewController
        searchTableViewController.tableView.delegate = self
        
        thisSearchController = UISearchController(searchResultsController: searchTableViewController)
        thisSearchController?.delegate = self
        thisSearchController?.searchResultsUpdater = self
        
        thisSearchController?.searchBar.sizeToFit()
        thisSearchController?.searchBar.placeholder = "Traži grad..."
        
        tableView.tableHeaderView = thisSearchController?.searchBar
    }
}
