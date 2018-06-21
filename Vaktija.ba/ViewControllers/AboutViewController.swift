//
//  AboutViewController.swift
//  Vaktija.ba
//
//

import UIKit
import SafariServices

class AboutViewController: UIViewController
{
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var appLinkButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        title = "O aplikaciji"
        
        let infoDictionary = Bundle.main.infoDictionary!
        let version = infoDictionary["CFBundleShortVersionString"] as! String
        let build = infoDictionary["CFBundleVersion"] as! String
        let appName = infoDictionary["CFBundleName"] as! String
        
        versionLabel.text = "Version \(version) (build: \(build))"
        appLinkButton.titleLabel?.text = appName
    }
    
    @IBAction func appLinkButtonClick(_ sender: UIButton)
    {
        let safariViewController = SFSafariViewController(url: URL(string: "http://vaktija.ba")!)
        
        present(safariViewController, animated: true, completion: nil)
    }
}
