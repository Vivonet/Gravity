//
//  Conditionals.swift
//  Gravity Demo
//
//  Created by Logan Murray on 2016-03-08.
//  Copyright © 2016 Gravity. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@objc public protocol ConditionalNode { // need a better name for this
	optional func rankSelector(first: String, second: String) -> String?
}

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Conditionals: GravityPlugin {

//		public override var handledAttributes: [String]? {
//			get {
//				return nil // all attributes
//			}
//		}
		
//		public override func selectAttribute(node: GravityNode, attribute: String, inout value: GravityNode?) -> GravityResult {
//			// TODO: implement this properly
//			
//		}
		
		// this should no longer be relevant
		public override func processValue(value: GravityNode) {
			guard let attribute = value.attributeName else {
				return
			}
			// temp test implementation
			if attribute.containsString(":") {
				let attributeParts = attribute.componentsSeparatedByString(":")
				let conditions = attributeParts.suffixFrom(1)
				let remainder = attributeParts.first!
				// should this be on value or value.parentNode??
				if !remainder.isEmpty {
//					NSLog("Checking \(conditions.count) conditions")
					var satisfied = true
					for condition in conditions {
						if value.getAttribute(condition, scope: .Global)?.boolValue != true { // TODO: we should either require or allow conditionals to be prefixed with :
							satisfied = false
							break
						}
					}
					
					if satisfied {
						value.parentNode?[remainder] = value
					} else {
						// FIXME: we need to figure out how to handle inclusion when a node (like this one) can be repurposed for use as a different attribute; how can we exclude one and not the other? maybe the real answer is the attribute should be repurposed, not removed and readded
						value.include = false // omit the current node, but not condition value nodes
					}
				}
			}
		}
	}
}