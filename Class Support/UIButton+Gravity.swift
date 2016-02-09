//
//  UIButton+Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UIButton: GravityElement {
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		switch attribute {
			case "title":
				// TODO: we should replace this with css-style styles, with styles for different button states
				self.setTitle(value, forState: UIControlState.Normal)
				return true
			
			case "action":
				return true // return true because we are handling this attribute in connectController()
			
			default:
				break
		}
		
		return false
	}
	
	public func processElement(node: GravityNode) -> Bool {
		self.adjustsImageWhenHighlighted = true
//		self.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)

		// it seems for some reason, UIButtons have an intrinsic height of 34; i need to figure out where that is coming from and kill it with fire
		
		return false
	}
	
	public func connectController(node: GravityNode, controller: NSObject) {
		if let action = node["action"] {
			removeTarget(nil, action: nil, forControlEvents: UIControlEvents.TouchUpInside) // unverified
			let exception = tryBlock {
				self.addTarget(controller, action: Selector(action), forControlEvents: UIControlEvents.TouchUpInside)
			}
			if exception != nil {
				NSLog("Warning: Action \"\(action)\" not found on object \(controller).")
			}
		}
	}
}