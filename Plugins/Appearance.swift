//
//  Appearance.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-19.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Appearance: GravityPlugin {
	
//		public override var registeredElements: [String]? {
//			get {
//				return nil
//			}
//		}
	
		public override var handledAttributes: [String]? {
			get {
				return ["color", "font"]
			}
		}
		
//		public override func processValue(value: GravityNode) -> GravityResult {
//			// TODO: convert things like "font" and "color" here (?)
//			return .NotHandled
//		}
		
		override public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
			if attribute == "borderColor" || attribute == nil {
				if let borderColor = value?.convert() as UIColor? {
					node.view.layer.borderColor = borderColor.CGColor
				} else {
					node.view.layer.borderColor = node.color.CGColor
				}
				return .Handled
			}
				
			if attribute == "borderSize" || attribute == nil {
				if let borderSize = value?.floatValue {
					node.view.layer.borderWidth = CGFloat(borderSize)
				} else {
					node.view.layer.borderWidth = 1
				}
				return .Handled
			}
				
			if attribute == "cornerRadius" || attribute == nil {
				if let cornerRadius = value?.floatValue {
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					node.view.layer.cornerRadius = CGFloat(cornerRadius)
					node.view.clipsToBounds = true // assume this is still needed
				} else {
					node.view.layer.cornerRadius = 0
					node.view.clipsToBounds = false // should we do this?
				}
				return .Handled
			}
			
			return .NotHandled
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	public var color: UIColor {
		get {
			return getScopedAttribute("color")?.convert() as UIColor? ?? UIColor.blackColor()
		}
	}
	
	public var font: UIFont {
		get {
			return getScopedAttribute("font")?.convert() as UIFont? ?? UIFont.systemFontOfSize(17) // same as UILabel default font
		}
	}
}