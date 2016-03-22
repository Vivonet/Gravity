//
//  Templating.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-14.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension Gravity {

	@available(iOS 9.0, *)
	@objc public class Templating: GravityPlugin {
		
		public override var recognizedAttributes: [String]? {
			get {
				return []
			}
		}
		
		// TODO: this will change to processValue in the dom phase
		public override func transformValue(var value: GravityNode) {
			guard let stringValue = value.stringValue else {
				return //.NotHandled
			}
			
			// TODO: if value is a node, check property type on target and potentially convert into a view (view controller?) -- we should be able to write a very simple converter for that, no? (does that mean templating and conversion both need to have a chance?)
//			if let stringValue = value.stringValue {
				var regex: NSRegularExpression? = nil
				do {
					regex = try NSRegularExpression(pattern: "\\{([_a-zA-Z\\.]*)\\}", options: NSRegularExpressionOptions.CaseInsensitive) // TODO: support unicode characters
				} catch {
				}
				
				if let matches = regex?.matchesInString(stringValue, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, stringValue.characters.count)) {
					var tempString: NSString = stringValue as NSString
					for match in matches.reverse() { // work from the back of the string so the ranges don't get clobbered
						let outerRange = match.rangeAtIndex(0)
						let innerRange = match.rangeAtIndex(1)
						var keyPath = (stringValue as NSString).substringWithRange(innerRange) // experimental
						let keyPathParts = keyPath.componentsSeparatedByString(".")
						if keyPathParts[0] != "model" {
							keyPath = (["model"] + keyPathParts).joinWithSeparator(".")
						}
						let templateValue = value.valueForKeyPath(keyPath) // here is an interesting question: do we access this on the node node or on the value node? // changed to value
	//					if matches.count == 1 && innerRange.location == 0 && innerRange.length == value.characters.count { // FIXME: this may be wrong
	//						value = markerValue
	//						return .Handled
	//					}
						tempString = tempString.stringByReplacingCharactersInRange(outerRange, withString: "\((templateValue ?? "")!)")
		//				newValue.replaceRange(, with: "\(node.model?.valueForKeyPath(keyPath))")
						value.stringValue = tempString as String
//						NSLog("keyPath: \(keyPath)")
		//				node.model?.valueForKeyPath(keyPath)
		//				var nodePointer = UnsafeMutablePointer<GravityNode>()
		
		
						// TODO: pretty sure we should be changing the entire value object, not changing its stringValue
						// how do we want to make that interface though? creating gravity nodes should not be left to the developer
						// maybe this should actually not act on nodes anymore but literal values…??
//						value.stringValue = stringValue
						
						value.addObserver(self, forKeyPath: keyPath, options: [.Initial], context: &value) // is it safe to pass node in an unsafe pointer?
					}
				}
				
				do {
					regex = try NSRegularExpression(pattern: "\\^{([_a-zA-Z\\.]*)\\}$", options: NSRegularExpressionOptions.CaseInsensitive) // TODO: support unicode characters
				} catch {
				}
				
				if let match = regex?.matchesInString(stringValue, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, stringValue.characters.count)).first {
//					let outerRange = match.rangeAtIndex(0)
					let innerRange = match.rangeAtIndex(1)
					var keyPath = (stringValue as NSString).substringWithRange(innerRange) // experimental
					let keyPathParts = keyPath.componentsSeparatedByString(".")
					if keyPathParts[0] != "model" {
						keyPath = (["model"] + keyPathParts).joinWithSeparator(".")
					}
					NSLog("postprocessValue keyPath: \(keyPath)")
					
					value.objectValue = value.valueForKeyPath(keyPath)
				}
//			}
			
			var propertyType: String? = nil
			
			if let attribute = value.attributeName {
				// this should really probably be in Conversion:
				// this is string.endsWith in swift. :| lovely.
				if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
					propertyType = "UIColor" // bit of a hack because UIView.backgroundColor doesn't seem to know its property class via inspection :/
				}
				
				if propertyType == nil {
	//				NSLog("Looking up property for \(node.view.dynamicType) . \(attribute)")
					// is there a better/safer way to do this reliably?
					if let parentNode = value.parentNode {
						let property = class_getProperty(NSClassFromString("\(parentNode.view.dynamicType)"), attribute)
						if property != nil {
							if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
								if components.count >= 2 {
									propertyType = components[1]
		//							NSLog("propertyType: \(propertyType!)")
								}
							}
						}
					}
				}
			}
			
			// this should probably go in conversion, no? does this even have an effect anymore?
			
			if let stringValue = value.stringValue {
				var convertedValue: AnyObject? = nil//value.stringValue
				if let propertyType = propertyType {
					convertedValue = value.convert(propertyType)
				}
				
				if convertedValue != nil {
					value.objectValue = convertedValue
				}
			} else { // this is a node value
				// do we actually need to do this, or can we write UIView/UIViewController converters? if so they should naturally accept a node value, not a string value
				if let propertyType = propertyType {
					if let type = NSClassFromString(propertyType) {
						if type is UIView.Type {
							// TODO: implement
						} else if type is UIViewController.Type {
							// TODO: implement
						}
					}
				}
			}
		}
		
		public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
			NSLog("received change notification for node:\n\(context)")
		}
	}
}