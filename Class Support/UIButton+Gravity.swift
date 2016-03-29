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

//	public var recognizedAttributes: [String]? {
//		get {
//			return ["title", "action", "backgroundColor", "highlightColor", "disabledColor"]
//		}
//	}
	
//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
////		if let stringValue = value.stringValue as? String {
//			switch attribute {
//				case "title":
//					// TODO: we should replace this with css-style styles, with styles for different button states
//					self.setTitle(value.stringValue, forState: UIControlState.Normal)
//					return .Handled
//				
//				case "action":
//					return .Handled // return handled because we are handling this attribute in connectController()
//				
//				case "backgroundColor":
//					if let color = value.convert() as UIColor? { // won't conversion take care of this?
//						self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Normal)
//						
//						self.adjustsImageWhenHighlighted = (node["highlightColor"] == nil)
//						self.adjustsImageWhenDisabled = (node["disabledColor"] == nil)
//						
//						return .Handled
//					}
//					break
//				
//				case "highlightColor":
//					if let color = value.convert() as UIColor? {
//						self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Highlighted)
//					}
//					break
//				
//				case "disabledColor":
//					if let color = value.convert() as UIColor? {
//						self.setBackgroundImage(imageWithColor(color), forState: UIControlState.Disabled)
//					}
//					break
//					
//				default:
//					break
//			}
////		}
//		
//		return .NotHandled
//	}
	
	public func processElement(node: GravityNode) {
		self.adjustsImageWhenHighlighted = true
		
		if let title = node["title"]?.stringValue {
			self.setTitle(title, forState: .Normal)
		}
		
		if let backgroundColor = node["backgroundColor"]?.convert() as UIColor? {
			self.setBackgroundImage(imageWithColor(backgroundColor), forState: .Normal)
			
			self.adjustsImageWhenHighlighted = (node["highlightColor"] == nil)
			self.adjustsImageWhenDisabled = (node["disabledColor"] == nil)
		}

		if let highlightColor = node["highlightColor"]?.convert() as UIColor? {
			self.setBackgroundImage(imageWithColor(highlightColor), forState: .Highlighted)
		}
		
		if let disabledColor = node["disabledColor"]?.convert() as UIColor? {
			self.setBackgroundImage(imageWithColor(disabledColor), forState: UIControlState.Disabled)
		}
//		self.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)

//		for subview in subviews {
//			subview.removeFromSuperview()
//		}

		// it seems for some reason, UIButtons have an intrinsic height of 34; i need to figure out where that is coming from and kill it with fire
		
//		return .NotHandled
	}
	
	// do we want
	public func connectController(node: GravityNode, controller: UIViewController) {
		if let action = node["action"]?.stringValue {
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