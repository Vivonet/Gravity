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

		public override var recognizedAttributes: [String]? {
			get {
				return nil // all attributes
			}
		}

		public override func processValue(value: GravityNode) -> GravityResult {
			guard let attribute = value.attributeName else {
				return .NotHandled
			}
			// temp test implementation
			if attribute.containsString(":") {
//				let remainder = attribute.substringFromIndex(attribute.startIndex.advancedBy(7))
				value.parentNode?[attribute.componentsSeparatedByString(":").first!] = value
				return .Handled
			}
			return .NotHandled
		}
	}
}