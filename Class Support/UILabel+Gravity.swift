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

	public var recognizedAttributes: [String]? {
		get {
			return ["wrap"]
		}
	}
//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
////		guard let stringValue = value.stringValue else {
////			return .NotHandled
////		}
//		
//		switch attribute {
//			case "wrap":
//				if value.boolValue == true {
//					self.numberOfLines = 0
//				}
//				
//				// TODO: we may want to set preferredMaxLayoutWidth to the label's maxWidth (possibly looking for a parental max?)
//				
//				return .Handled
//			
//			default:
//				break
//		}
//		
//		return .NotHandled//super.processAttribute(gravity, attribute: attribute, value: value)
//	}
	
	public func processElement(node: GravityNode) {
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
		
		if node["textColor"] == nil {
			self.textColor = node.color
		}
		
		if node["wrap"]?.boolValue == true {
			self.numberOfLines = 0
		}
		
		self.font = node.font
		
		if let maxWidth = node.maxWidth {
			// FIXME: we probably want to improve this a lot, perhaps by using swizzling to insert logic during the layout pass
			self.preferredMaxLayoutWidth = CGFloat(maxWidth)
		}
//						label.setContentCompressionResistancePriority(100, forAxis: UILayoutConstraintAxis.Horizontal)
//		return .NotHandled
	}
}