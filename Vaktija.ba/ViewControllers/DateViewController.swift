//
//  DateViewController.swift
//  Vaktija.ba
//
//

import UIKit

class DateViewController: UIViewController
{
    @IBOutlet weak var datePicker: UIDatePicker!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = "Odaberi datum"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Prikaži", style: .plain, target: self, action: #selector(showBarButtonItemClick(_:)))
    }
    
    func showBarButtonItemClick(_ sender: UIBarButtonItem)
    {
        let dateScheduleTableViewController = storyboard?.instantiateViewController(withIdentifier: "DateScheduleTableViewController") as! DateScheduleTableViewController
        dateScheduleTableViewController.pickedDate = datePicker.date
        
        navigationController?.pushViewController(dateScheduleTableViewController, animated: true)
    }
}
