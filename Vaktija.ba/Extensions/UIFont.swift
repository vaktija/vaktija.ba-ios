//
//  UIFont.swift
//  Vaktija.ba
//
//

import Foundation
import UIKit

extension UIFont {
	enum VBFont {
		case regular
		case bold
		case oblique
		case light
		case boldOblique
		case lightOblique
	}
	
	convenience init(font: VBFont, size: CGFloat) {
		let appFontFamily = "Helvetica"
		var appFontWeight = ""
		
		switch font {
		case .regular:
			appFontWeight = ""
		case .bold:
			appFontWeight = "-Bold"
		case .oblique:
			appFontWeight = "-Oblique"
		case .light:
			appFontWeight = "-Light"
		case .boldOblique:
			appFontWeight = "-BoldOblique"
		case .lightOblique:
			appFontWeight = "-LightOblique"
		}
		
		let fontDescriptor = UIFontDescriptor(name: "\(appFontFamily)\(appFontWeight)", size: size)
		self.init(descriptor: fontDescriptor, size: 0.0)
	}
}
