//
//  MainTabBarController.swift
//  Vaktija.ba
//
//

import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
		
		if #available(iOS 10.0, *) {
			
		} else {
			if let items = tabBar.items {
				let selectedColor = UIColor.titleColor
				let unselectedColor = UIColor.subtitleColor
				for item in items {
					item.selectedImage = item.selectedImage?.imageWithColor(selectedColor).withRenderingMode(.alwaysOriginal)
					item.image = item.image?.imageWithColor(unselectedColor).withRenderingMode(.alwaysOriginal)
				}
			}
		}
    }
}
