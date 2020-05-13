//
//  LocationsTableViewController.swift
//  Vaktija.ba
//
//

import UIKit
import CoreData

class LocationsTableViewController: UITableViewController {
	private lazy var searchBar: UISearchBar = {
		let searchBar = UISearchBar(frame: CGRect.zero)
		searchBar.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		searchBar.placeholder = "Traži grad..."
		searchBar.searchBarStyle = .minimal
		searchBar.delegate = self
		return searchBar
	}()
	
	private var locations: [VBLocation] = []
    private var selectedIndexPath = IndexPath(row: -1, section: 0)
    private var thereAreChanges = false
	private var isSearchActive = false
	private var searchResults: [VBLocation] = [] {
		didSet {
			isSearchActive = searchResults.isEmpty == false || searchBar.text?.isEmpty == false
			tableView.reloadData()
		}
	}
    
    // MARK: View's Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
		navigationItem.title = "Lokacije"
        
        let locationsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VBLocation")
        locationsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "weight", ascending: true)]
        
        do {
            locations = try VBCoreDataStack.sharedInstance.managedObjectContext.fetch(locationsFetchRequest) as! [VBLocation]
        } catch {
            print(error)
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchBarButtonItemClick(_:)))
		let headerView = UIView(frame: CGRect.zero)
		headerView.frame.size.height = 56.0
		headerView.backgroundColor = UIColor.backgroundColor
		headerView.addSubview(searchBar)
		searchBar.sizeToFit()
		tableView.tableHeaderView = headerView
		
		view.backgroundColor = UIColor.backgroundColor
		tableView.backgroundColor = UIColor.backgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
		
		navigationController?.setNavigationBarHidden(false, animated: true)
		
		let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        let index = locations.firstIndex(where: {$0.id == Int64(userDefaults!.integer(forKey: "locationId"))})
        
        if let goodIndex = index {
            tableView.scrollToRow(at: IndexPath(row: goodIndex, section: 0), at: .middle, animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
		
		if thereAreChanges {
			VBNotification().scheduleLocalNotifications(true)
		}
    }
    
    // MARK: - Navigation Bar Functions
    
    @objc func searchBarButtonItemClick(_ sender: UIBarButtonItem) {
        if locations.isEmpty == false {
			searchBar.becomeFirstResponder()
        }
    }

    // MARK: - Table View Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return isSearchActive ? searchResults.count : locations.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath)

        // Configure the cell...
        let row = indexPath.row
        let location = isSearchActive ? searchResults[row] : locations[row]
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        
		cell.backgroundColor = UIColor.backgroundColor
        cell.textLabel?.text = location.location
		cell.textLabel?.textColor = UIColor.titleColor
        
        if location.id == Int64(userDefaults!.integer(forKey: "locationId")) {
            cell.accessoryType = .checkmark
            selectedIndexPath = indexPath
        } else {
            cell.accessoryType = .none
        }

        return cell
    }
    
    // MARK: Table View Delegates
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let row = indexPath.row
		let location = isSearchActive ? searchResults[row] : locations[row]
        let userDefaults = UserDefaults(suiteName: "group.ba.vaktija.Vaktija.ba")
        var indexPaths = [indexPath]
		if selectedIndexPath != indexPath {
			let index = (isSearchActive ? searchResults : locations).firstIndex(where: {
				$0.id == Int64(userDefaults!.integer(forKey: "locationId"))
			})
			if let index = index {
				indexPaths.append(IndexPath(row: index, section: 0))
			}
		}
		userDefaults!.set(Int(location.id), forKey: "locationId")
		thereAreChanges = true
		tableView.reloadRows(at: indexPaths, with: .none)
		_ = self.navigationController?.popViewController(animated: true)
    }
}

extension LocationsTableViewController: UISearchBarDelegate {
	func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
		searchBar.setShowsCancelButton(true, animated: true)
		navigationController?.setNavigationBarHidden(true, animated: true)
		return true
	}
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		searchResults = locations.filter {
			return $0.location?.range(of: searchText, options: [.caseInsensitive, .diacriticInsensitive]) != nil
		}
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.resignFirstResponder()
		searchBar.text = ""
		searchBar.setShowsCancelButton(false, animated: false)
		navigationController?.setNavigationBarHidden(false, animated: true)
		searchResults = []
	}
}
