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
	
		public override var recognizedAttributes: [String]? {
			get {
				return ["borderColor", "borderSize", "color", "cornerRadius", "font"]
			}
		}
		
		public override func processValue(value: GravityNode) -> GravityResult {
			// TODO: convert things like "font" and "color" here (?)
			return .NotHandled
		}
		
		override public func processNode(node: GravityNode) {
			if let borderColor = node["borderColor"]?.convert() as UIColor? {
				node.view.layer.borderColor = borderColor.CGColor
			}
		
			if let borderSize = node["borderSize"]?.floatValue {
				node.view.layer.borderWidth = CGFloat(borderSize)
			}
		
			if let cornerRadius = node["cornerRadius"]?.floatValue {
				// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
				node.view.layer.cornerRadius = CGFloat(cornerRadius)
				node.view.clipsToBounds = true // assume this is still needed
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