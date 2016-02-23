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
			switch attribute {
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
			return nil ?? UIFont() // TODO
		}
	}
}