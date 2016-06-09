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
		
//		public override var recognizedAttributes: [String]? {
//			get {
//				return []
//			}
//		}
		
		public override func processValue(value: GravityNode) {
			guard let stringValue = value.stringValue else {
				return
			}
			
			// TODO: if value is a node, check property type on target and potentially convert into a view (view controller?) -- we should be able to write a very simple converter for that, no? (does that mean templating and conversion both need to have a chance?)
			var regex: NSRegularExpression? = nil
			do {
				// TODO: improve this regex to properly support objc identifiers (e.g. unicode)
				regex = try NSRegularExpression(pattern: "\\{([@_a-zA-Z0-9\\.]*)\\}", options: NSRegularExpressionOptions.CaseInsensitive)
			} catch {
			}
			
			// TODO: implement context aliases using the @ symbol; default is @model
			
			if let matches = regex?.matchesInString(stringValue, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, stringValue.characters.count)) {
				var nsString: NSString = stringValue as NSString
				for match in matches.reverse() { // work from the back of the string so the ranges don't get clobbered
					let outerRange = match.rangeAtIndex(0)
					let innerRange = match.rangeAtIndex(1)
					var keyPath = (stringValue as NSString).substringWithRange(innerRange)
					let keyPathParts = keyPath.componentsSeparatedByString(".")
					var alias = "@model"
					var context: AnyObject?
					let totalTemplate = matches.count == 1 && outerRange.location == 0 && outerRange.length == stringValue.characters.count
					
					if keyPathParts[0].hasPrefix("@") {
						alias = keyPathParts[0]
						keyPath = keyPathParts.suffixFrom(1).joinWithSeparator(".")
					}
					
					// TODO: allow registering of custom aliases
					switch alias {
						case "@model":
							context = value.model
							break
						
						case "@node":
							context = value.parentNode
							break
						
						case "@self":
							context = value.parentNode?._view // we need some way to reference view without instantiating it
							break
						
						case "@origin": // need a better name
							context = value.document.parentNode
							break
						
						default:
							break
					}
					
					if var templateValue = keyPath.characters.count > 0 ? context?.valueForKeyPath(keyPath) : context { // change to isEmpty
						// TODO: if templateValue is a value node, figure out the best value to use (or is objectValue always reliable?)
						if let nodeValue = templateValue as? GravityNode {
							// if the value is a content node, instantiate it into a document
							templateValue = nodeValue.objectValue ?? nodeValue.instantiate() // precedence here good or flip it?
						}
						// verify this works with text node values
						if totalTemplate {
							value.objectValue = templateValue
						}
						nsString = nsString.stringByReplacingCharactersInRange(outerRange, withString: "\(templateValue)")
						value.stringValue = nsString as String
					} else {
						// the value could not be found
						if totalTemplate {
							value.include = false // experimental but should work
						}
					}
					
					var varValue = value
					value.addObserver(self, forKeyPath: keyPath, options: [.Initial], context: &varValue) // is it safe to pass node in an unsafe pointer?
				}
			}
		}
		
		public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
//			NSLog("received change notification for node:\n\(context)")
		}
	}
}