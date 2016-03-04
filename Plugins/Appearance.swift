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
		public override func preprocessAttribute(node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult {
			guard let textValue = value.textValue else {
				return .NotHandled
			}
			
			switch attribute {
				case "borderColor":
					if let color = value.convert() as UIColor? {
						node.view.layer.borderColor = color.CGColor
					}
					return .Handled
				
				case "borderSize":
					if let floatValue = value.floatValue {
						node.view.layer.borderWidth = CGFloat(floatValue)
					}
					return .Handled
				
				case "color":
					return .Handled
				
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					node.view.layer.cornerRadius = CGFloat((textValue as NSString).floatValue)
					node.view.clipsToBounds = true // assume this is still needed
					return .Handled
				
				case "font":
					return .Handled
				
				default:
					return .NotHandled
			}
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