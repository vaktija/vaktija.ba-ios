//
//  UIColor.swift
//  Vaktija.ba
//
//

import Foundation
import UIKit

extension UIColor {
	
	/// Initialise UIColor with hexadecimal representation.
	/// - Parameter rgb: Hexadecimal representation of the color. Example: #FFCA34 is 0xFFCA34
	convenience init(rgb: Int) {
		let red = CGFloat((rgb >> 16) & 0xFF)/255.0
		let green = CGFloat((rgb >> 8) & 0xFF)/255.0
		let blue = CGFloat(rgb & 0xFF)/255.0
		self.init(red: red, green: green, blue: blue, alpha: 1.0)
	}
	
	/// Light Mode: #4A4A4A Dark Mode: #FFFFFF Universal: #4A4A4A
	static var titleColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "titleColor") ?? UIColor(rgb: 0x4A4A4A)
		} else {
			return UIColor(rgb: 0x4A4A4A)
		}
	}
	
	/// #CACACA
	static var subtitleColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "subtitleColor") ?? UIColor(rgb: 0xCACACA)
		} else {
			return UIColor(rgb: 0xCACACA)
		}
	}
	
	/// #9A9D14
	static var selectedColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "selectedColor") ?? UIColor(rgb: 0x9A9D14)
		} else {
			return UIColor(rgb: 0x9A9D14)
		}
	}
	
	/// #007AFF
	static var actionColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "actionColor") ?? UIColor(rgb: 0x007AFF)
		} else {
			return UIColor(rgb: 0x007AFF)
		}
	}
	
	/// #FF0000
	static var errorColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "errorColor") ?? UIColor(rgb: 0xFF0000)
		} else {
			return UIColor(rgb: 0xFF0000)
		}
	}
	
	/// #FD8208
	static var warningColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "warningColor") ?? UIColor(rgb: 0xFD8208)
		} else {
			return UIColor(rgb: 0xFD8208)
		}
	}
	
	/// Light Mode: #FFFFFF Dark Mode: ##1E2227 Universal: #FFFFFF
	static var backgroundColor: UIColor {
		if #available(iOS 11.0, *) {
			return UIColor(named: "backgroundColor") ?? UIColor(rgb: 0xFFFFFF)
		} else {
			return UIColor(rgb: 0xFFFFFF)
		}
	}
}
