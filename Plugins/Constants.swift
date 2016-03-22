//
//  Constants.swift
//  GravityAssist
//
//  Created by Logan Murray on 2016-02-23.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension Gravity {
	/// This plugin allows for the registration of unique identifiers mapped to arbitrary values for use in your gravity files. Its purpose is to allow for the use of the many `enum`s in UIKit.
	///
	/// There's unfortunately no way to automate this that I can think of.
	@objc public class Constants: GravityPlugin {
		static var constants = [String: NSNumber]()
		
		/// Register a constant with a `String` identifier that can be used as a value in your gravity file.
		///
		/// You should register the constant using the same form it would appear in code. For example, `UIStackViewAlignment.Bottom` should be registered as "UIStackViewAlignment.Bottom".
		public class func registerConstant(name: String, value: NSNumber) {
			constants[name.stringByReplacingOccurrencesOfString(".", withString: "")] = value// as! NSNumber
		}
		
//		public class func registerConstant(name: String, value: Double) {
//			constants[name.stringByReplacingOccurrencesOfString(".", withString: "")] = value as NSNumber
//		}
		
		public override class func initialize() {
			loadDefaultConstants()
		}
		
		public override var recognizedAttributes: [String]? {
			get {
				return [] // no attributes (presently value calls get called on all plugins)
				// TODO: is there a better way to register value transformers?
			}
		}
		
		public override func transformValue(value: GravityNode) {
			guard let stringValue = value.stringValue else {
				return
			}
			
			if let constant = Constants.constants[stringValue.stringByReplacingOccurrencesOfString(".", withString: "")] {
				value.objectValue = constant
//				return constant
			}
			
//			return nil
		}
		
		private class func loadDefaultConstants() {
			// should we register these alongside the classes that make the most sense? the problem is it's hard to initialize a class extension
			
			// there are obviously a lot of these; i'm just going to add them as i need them; try to keep these sorted alphabetically
			
			// MARK: UILayoutConstraintAxis
			Constants.registerConstant("UILayoutConstraintAxis.Horizontal",			value: UILayoutConstraintAxis.Horizontal.rawValue)
			Constants.registerConstant("UILayoutConstraintAxis.Vertical",			value: UILayoutConstraintAxis.Vertical.rawValue)
			
			// MARK: UIStackViewAlignment
			Constants.registerConstant("UIStackViewAlignment.Bottom",				value: UIStackViewAlignment.Bottom.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Center",				value: UIStackViewAlignment.Center.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Fill",					value: UIStackViewAlignment.Fill.rawValue)
			Constants.registerConstant("UIStackViewAlignment.FirstBaseline",		value: UIStackViewAlignment.FirstBaseline.rawValue)
			Constants.registerConstant("UIStackViewAlignment.LastBaseline",			value: UIStackViewAlignment.LastBaseline.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Leading",				value: UIStackViewAlignment.Leading.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Top",					value: UIStackViewAlignment.Top.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Trailing",				value: UIStackViewAlignment.Trailing.rawValue)
			
			// MARK: UIViewContentMode
			Constants.registerConstant("UIViewContentMode.Bottom",					value: UIViewContentMode.Bottom.rawValue)
			Constants.registerConstant("UIViewContentMode.BottomLeft",				value: UIViewContentMode.BottomLeft.rawValue)
			Constants.registerConstant("UIViewContentMode.BottomRight",				value: UIViewContentMode.BottomRight.rawValue)
			Constants.registerConstant("UIViewContentMode.Redraw",					value: UIViewContentMode.Redraw.rawValue)
			Constants.registerConstant("UIViewContentMode.Center",					value: UIViewContentMode.Center.rawValue)
			Constants.registerConstant("UIViewContentMode.Left",					value: UIViewContentMode.Left.rawValue)
			Constants.registerConstant("UIViewContentMode.Right",					value: UIViewContentMode.Right.rawValue)
			Constants.registerConstant("UIViewContentMode.ScaleAspectFill",			value: UIViewContentMode.ScaleAspectFill.rawValue)
			Constants.registerConstant("UIViewContentMode.ScaleAspectFit",			value: UIViewContentMode.ScaleAspectFit.rawValue)
			Constants.registerConstant("UIViewContentMode.ScaleToFill",				value: UIViewContentMode.ScaleToFill.rawValue)
			Constants.registerConstant("UIViewContentMode.Top",						value: UIViewContentMode.Top.rawValue)
			Constants.registerConstant("UIViewContentMode.TopLeft",					value: UIViewContentMode.TopLeft.rawValue)
			Constants.registerConstant("UIViewContentMode.TopRight",				value: UIViewContentMode.TopRight.rawValue)
		}
	}
}