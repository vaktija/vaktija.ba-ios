//
//  UIImage.swift
//  Vaktija.ba
//
//

import Foundation
import UIKit

extension UIImage {
	func imageWithColor(_ color: UIColor) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(size, false, scale)
		
		let context = UIGraphicsGetCurrentContext()!
		context.translateBy(x: 0, y: size.height)
		context.scaleBy(x: 1.0, y: -1.0)
		context.setBlendMode(.normal)

		let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
		context.clip(to: rect, mask: cgImage!)
		color.setFill()
		context.fill(rect)

		let image = UIGraphicsGetImageFromCurrentImageContext()!
		UIGraphicsEndImageContext()
		return image
	}
}
