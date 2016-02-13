//
//  UIButton+Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

private func imageWithColor(color: UIColor) -> UIImage {
	let rect = CGRectMake(0.0, 0.0, 1.0, 1.0)
	UIGraphicsBeginImageContext(rect.size)
	let context = UIGraphicsGetCurrentContext()

	CGContextSetFillColorWithColor(context, color.CGColor)
	CGContextFillRect(context, rect)

	let image = UIGraphicsGetImageFromCurrentImageContext()
	UIGraphicsEndImageContext()

	return image.resizableImageWithCapInsets(UIEdgeInsetsMake(0.5, 0.5, 0.5, 0.5))
}

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
			
			case "backgroundColor":
				if let color = Gravity.convert(value) as UIColor? {
					self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Normal)
					
					self.adjustsImageWhenHighlighted = (node["highlightColor"] == nil)
					self.adjustsImageWhenDisabled = (node["disabledColor"] == nil)
					
					return true
				}
				break
			
			case "highlightColor":
				if let color = Gravity.convert(value) as UIColor? {
					self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Highlighted)
				}
				break
			
			case "disabledColor":
				if let color = Gravity.convert(value) as UIColor? {
					self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Disabled)
				}
				break
				
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
			// unfortunately this doesn't work because it doesn't give an exception on adding, but only when it tries to actually call it
			let exception = tryBlock {
				self.addTarget(controller, action: Selector(action), forControlEvents: UIControlEvents.TouchUpInside)
			}
			if exception != nil {
				NSLog("Warning: Action \"\(action)\" not found on object \(controller).")
			}
		}
	}
	
}