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
				// TODO: implement actions as strings that map to methods on the controller
				// should support parameterless and single-parameter variations
				break
			
			default:
				break
		}
		
		return false//super.processAttribute(gravity, attribute: attribute, value: value)
	}
	
	public func processElement(node: GravityNode) -> Bool {
		self.adjustsImageWhenHighlighted = true
//		self.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)

		// it seems for some reason, UIButtons have an intrinsic height of 34; i need to figure out where that is coming from and kill it with fire
		
		return false
	}
}