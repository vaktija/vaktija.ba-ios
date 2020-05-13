//
//  String.swift
//  Vaktija.ba
//
//

import Foundation

extension String {
	var capitalizedFirst: String {
		return prefix(1).capitalized + dropFirst()
	}
}
