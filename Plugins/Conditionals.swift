//
//  Conditionals.swift
//  Gravity Demo
//
//  Created by Logan Murray on 2016-03-08.
//  Copyright © 2016 Gravity. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Conditionals: GravityPlugin {

//		public override var handledAttributes: [String]? {
//			get {
//				return nil // all attributes
//			}
//		}

		public override func processValue(value: GravityNode) {
			guard let attribute = value.attributeName else {
				return
			}
			// temp test implementation
			if attribute.containsString(":") {
				let attributeParts = attribute.componentsSeparatedByString(":")
				let conditional = attributeParts.last!
				let remainder = attributeParts.first!
				// should this be on value or value.parentNode??
				if value.getScopedAttribute("\(conditional)")?.boolValue == true { // TODO: we should either require or allow conditionals to be prefixed with :
					value.parentNode?[remainder] = value
				}
				value.include = false // omit the current node
				return
			}
			
			return
		}
	}
}