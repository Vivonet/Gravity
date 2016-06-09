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
			// this avoids annoying warnings on the console (perhaps find a better way to more accurately determine if the layer is a transform-only layer)
			if node.view.isKindOfClass(UIStackView.self) {
				return .NotHandled
			}
			
			if attribute == "borderColor" || attribute == nil {
				if let borderColor = value?.convert() as UIColor? {
					node.view.layer.borderColor = borderColor.CGColor
					return .Handled
				} else {
					node.view.layer.borderColor = node.color.CGColor
				}
			}
				
			if attribute == "borderSize" || attribute == nil {
				if let borderSize = value?.floatValue {
					node.view.layer.borderWidth = CGFloat(borderSize)
					return .Handled
				} else {
					node.view.layer.borderWidth = 0
				}
			}
				
			if attribute == "cornerRadius" || attribute == nil {
				if let cornerRadius = value?.floatValue {
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					node.view.layer.cornerRadius = CGFloat(cornerRadius)
					node.view.clipsToBounds = true // assume this is still needed
					return .Handled
				} else {
					node.view.layer.cornerRadius = 0
					node.view.clipsToBounds = true // false is a bad idea; true seems to work as a default
				}
			}
			
			return .NotHandled
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	public var color: UIColor {
		get {
			return getAttribute("color", scope: .Global)?.convert() as UIColor? ?? UIColor.blackColor()
		}
	}
	
	public var font: UIFont {
		get {
			return getAttribute("font", scope: .Global)?.convert() as UIFont? ?? UIFont.systemFontOfSize(17) // same as UILabel default font
		}
	}
}