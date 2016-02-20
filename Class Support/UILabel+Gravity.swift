//
//  UILabel+Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UILabel: GravityElement {
	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
		guard let textValue = value.textValue else {
			return .NotHandled
		}
		
		switch attribute {
			case "wrap":
				if (textValue as NSString).boolValue { // or do we want to write a converter to Bool? can we even do that? i'd rather that if we could
					self.numberOfLines = 0
				}
				return .Handled
			
			default:
				break
		}
		
		return .NotHandled//super.processAttribute(gravity, attribute: attribute, value: value)
	}
	
	public func processElement(node: GravityNode) -> GravityResult {
		switch node.gravity.horizontal { // TODO: should improve this, possibly by splitting into horizontalGravity and verticalGravity properties
			case GravityDirection.Left:
				self.textAlignment = NSTextAlignment.Left
				break
			case GravityDirection.Center:
				self.textAlignment = NSTextAlignment.Center
				break
			case GravityDirection.Right:
				self.textAlignment = NSTextAlignment.Right
				break
//			case GravityDirection.Wide:
//				self.textAlignment = NSTextAlignment.Justified // does this make sense?
//				break
			default:
				// TODO: throw
				break
		}
		
		if node.attributes["textColor"] == nil {
			self.textColor = node.color
		}
//						label.setContentCompressionResistancePriority(100, forAxis: UILayoutConstraintAxis.Horizontal)
		return .NotHandled
	}
}