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
		
		override func postprocessValue(node: GravityNode, attribute: String, input: GravityNode, inout output: AnyObject) -> GravityResult {
			guard let textValue = input.textValue else {
				return .NotHandled
			}
			
			if let constant = Constants.constants[textValue.stringByReplacingOccurrencesOfString(".", withString: "")] {
				output = constant
				return .Handled
			}
			
			return .NotHandled
		}
		
		private class func loadDefaultConstants() {
			// should we register these alongside the classes that make the most sense? the problem is it's hard to initialize a class extension
			
			// there are obviously a lot of these; i'm just going to add them as i need them; try to keep these sorted alphabetically
			
			// MARK: UIStackViewAlignment
			Constants.registerConstant("UIStackViewAlignment.Bottom",				value: UIStackViewAlignment.Bottom.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Center",				value: UIStackViewAlignment.Center.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Fill",					value: UIStackViewAlignment.Fill.rawValue)
			Constants.registerConstant("UIStackViewAlignment.FirstBaseline",		value: UIStackViewAlignment.FirstBaseline.rawValue)
			Constants.registerConstant("UIStackViewAlignment.LastBaseline",			value: UIStackViewAlignment.LastBaseline.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Leading",				value: UIStackViewAlignment.Leading.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Top",					value: UIStackViewAlignment.Top.rawValue)
			Constants.registerConstant("UIStackViewAlignment.Trailing",				value: UIStackViewAlignment.Trailing.rawValue)
		}
	}
}