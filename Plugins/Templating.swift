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
		
		// should `value` be inout here so we can replace it with a node?
		public override func preprocessValue(var node: GravityNode, attribute: String, value: GravityNode) {
//		public override func preprocessAttribute(var node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult {
			guard var textValue = value.textValue else {
				return //.NotHandled
			}
			
			do { // <- fix this
				// this is the sad, sad state of regular expressions in Swift, apparently :(
				let regex = try NSRegularExpression(pattern: "\\{([_a-zA-Z\\.]*)\\}", options: NSRegularExpressionOptions.CaseInsensitive) // TODO: support unicode characters
				let matches = regex.matchesInString(textValue, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, textValue.characters.count))
				var newValue: NSString = textValue as NSString

				for match in matches.reverse() { // work from the back of the string so the ranges don't get clobbered
					let outerRange = match.rangeAtIndex(0)
					let innerRange = match.rangeAtIndex(1)
					var keyPath = (textValue as NSString).substringWithRange(innerRange) // experimental
					let keyPathParts = keyPath.componentsSeparatedByString(".")
					if keyPathParts[0] != "model" {
						keyPath = (["model"] + keyPathParts).joinWithSeparator(".")
					}
					let markerValue = node.valueForKeyPath(keyPath) // here is an interesting question: do we access this on the node node or on the value node?
//					if matches.count == 1 && innerRange.location == 0 && innerRange.length == value.characters.count { // FIXME: this may be wrong
//						value = markerValue
//						return .Handled
//					}
					newValue = newValue.stringByReplacingCharactersInRange(outerRange, withString: "\((markerValue ?? "")!)")
	//				newValue.replaceRange(, with: "\(node.model?.valueForKeyPath(keyPath))")
					textValue = newValue as String
					NSLog("keyPath: \(keyPath)")
	//				node.model?.valueForKeyPath(keyPath)
	//				var nodePointer = UnsafeMutablePointer<GravityNode>()
					value.textValue = textValue
					
					node.addObserver(self, forKeyPath: keyPath, options: [.Initial], context: &node) // is it safe to pass node in an unsafe pointer?
				}
				
//				if matches.count > 0 {
//					return .Handled
//				}
			} catch {
			}
			
			return //.NotHandled
		}
		
		public override func postprocessValue(node: GravityNode, attribute: String, input: GravityNode, inout output: AnyObject) -> GravityResult {
			// TODO: if value is a node, check property type on target and potentially convert into a view (view controller?) -- we should be able to write a very simple converter for that, no? (does that mean templating and conversion both need to have a chance?)
			if let textValue = input.textValue {
				var regex: NSRegularExpression? = nil
				do {
					regex = try NSRegularExpression(pattern: "\\^{([_a-zA-Z\\.]*)\\}$", options: NSRegularExpressionOptions.CaseInsensitive) // TODO: support unicode characters
				} catch {
				}
				if let match = regex?.matchesInString(textValue, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, textValue.characters.count)).first {
					let outerRange = match.rangeAtIndex(0)
					let innerRange = match.rangeAtIndex(1)
					var keyPath = (textValue as NSString).substringWithRange(innerRange) // experimental
					let keyPathParts = keyPath.componentsSeparatedByString(".")
					if keyPathParts[0] != "model" {
						keyPath = (["model"] + keyPathParts).joinWithSeparator(".")
					}
					NSLog("postprocessValue keyPath: \(keyPath)")
					
					// TODO: if we find a value, set output and return
				}
			}
			
			var propertyType: String? = nil
			
			// this should really probably be in Conversion:
			// this is string.endsWith in swift. :| lovely.
			if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
				propertyType = "UIColor" // bit of a hack because UIView.backgroundColor doesn't seem to know its property class via inspection :/
			}
			
			if propertyType == nil {
//				NSLog("Looking up property for \(node.view.dynamicType) . \(attribute)")
				// is there a better/safer way to do this reliably?
				let property = class_getProperty(NSClassFromString("\(node.view.dynamicType)"), attribute)
				if property != nil {
					if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
						if components.count >= 2 {
							propertyType = components[1]
//							NSLog("propertyType: \(propertyType!)")
						}
					}
				}
			}
			
			if let textValue = input.textValue {
				var convertedValue: AnyObject? = input.textValue
				if let propertyType = propertyType {
					convertedValue = input.convert(propertyType)
				}
				
				if convertedValue != nil {
					output = convertedValue!
					return .Handled
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
			
			return .NotHandled // temp!
		}
		
		// this is really a singleton; should we provide a better way for this to be overridden?
		override func postprocessAttribute(node: GravityNode, attribute: String, value: AnyObject) -> GravityResult {

			
//			NSLog("KeyPath \(attribute) converted 
			
			if tryBlock({
				node.view.setValue(value, forKeyPath: attribute)
			}) != nil {
				NSLog("Warning: Key path '\(attribute)' not found on object \(node.view).")
				return .NotHandled
			}
			
			return .Handled
		}
		
		public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
			NSLog("received change notification for node:\n\(context)")
		}
	}
}