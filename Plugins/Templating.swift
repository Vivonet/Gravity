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
		
		public override func preprocessAttribute(var node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult {
			guard var textValue = value.textValue else {
				return .NotHandled
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
					let markerValue = node.valueForKeyPath(keyPath)
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
					
					node.addObserver(self, forKeyPath: keyPath, options: [.Initial], context: &node) // is it safe to pass node in an unsafe pointer?
				}
				
//				if matches.count > 0 {
//					return .Handled
//				}
			} catch {
			}
			
			return .NotHandled
		}
		
		public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
			NSLog("received change notification for node:\n\(context)")
		}
	}
}