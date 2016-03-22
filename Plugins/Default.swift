//
//  Default.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// do we really need/want this class? maybe rename?

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Default: GravityPlugin {
//		private static let keywords = ["id", "zIndex", "gravity"] // add more? move?
		// TODO: these should ideally be blocked at the same location they are used (e.g. zIndex and gravity in Layout, id should be blocked in the kernel.
		
		public override var recognizedAttributes: [String]? {
			get {
				return nil // all attributes
			}
		}
		
		public override func instantiateView(node: GravityNode) -> UIView? {
			let type: AnyClass? = NSClassFromString(node.nodeName)
			if let type = type as? GravityElement.Type where type.instantiateView != nil {
				return type.instantiateView!(node)
			} else if let type = type as? UIView.Type {
//				var view: UIView
//				tryBlock {
				let view = type.init()
				view.translatesAutoresizingMaskIntoConstraints = false // do we need this? i think so
				// TODO: should we set clipsToBounds for views by default?
//				}
				return view
				
				// TODO: determine if the instance is an instance of UIView or UIViewController and handle the latter by embedding a view controller
			} else if let type = type as? UIViewController.Type {
				let vc = type.init()
				node.controller = vc // this might be a problem since node.view is not set at this point (dispatch_async?)
				return vc.view
				//node._view = vc.view
//				let container = UIView()
//				container.addSu
			}
			return nil
		}
		
//		public override func preprocessAttribute(inout value: GravityNode) -> GravityResult {
//			if Default.keywords.contains(attribute) {
//				return .Handled
//			}
//			
//			return .NotHandled
//		}
		
		// this is really a singleton; should we provide a better way for this to be overridden?
		// we should turn this into processValue()
		public override func processValue(value: GravityNode) -> GravityResult {
			guard let node = value.parentNode else {
				return .NotHandled
			}
			guard let attribute = value.attributeName else {
				return .NotHandled
			}
//			NSLog("KeyPath \(attribute) converted 
			
			if let value = value.objectValue {
				if tryBlock({
					NSLog("Setting property \(attribute) to value: \(value)")
					node.view.setValue(value, forKeyPath: attribute)
				}) != nil {
					NSLog("Warning: Key path '\(attribute)' not found on object \(node.view).")
					return .NotHandled
				}
			} else {
				return .NotHandled
			}
			
			return .Handled
		}
		
//		public override func postprocessValue(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
		
//			// TODO: if value is a node, check property type on target and potentially convert into a view (view controller?)
//
//			var propertyType: String? = nil
//			
//			// this is string.endsWith in swift. :| lovely.
//			if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
//				propertyType = "UIColor" // bit of a hack because UIView.backgroundColor doesn't seem to know its property class via inspection :/
//			}
//			
//			if propertyType == nil {
////				NSLog("Looking up property for \(node.view.dynamicType) . \(attribute)")
//				// is there a better/safer way to do this reliably?
//				let property = class_getProperty(NSClassFromString("\(node.view.dynamicType)"), attribute)
//				if property != nil {
//					if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
//						if components.count >= 2 {
//							propertyType = components[1]
////							NSLog("propertyType: \(propertyType!)")
//						}
//					}
//				}
//			}
//			
//			var convertedValue: AnyObject? = value.stringValue
//			
//			if let propertyType = propertyType {
//				convertedValue = value.convert(propertyType)
////				if let converter = Conversion.converters[propertyType!] {
////					var newOutput: AnyObject? = output
////					if converter(input: input, output: &newOutput) == .Handled {
////						output = newOutput! // this feels ugly
////						return .Handled
////					}
////				}
//			}
//			
////			NSLog("KeyPath \(attribute) converted 
//			
//			if tryBlock({
//				node.view.setValue(convertedValue, forKeyPath: attribute)
//			}) != nil {
//				NSLog("Warning: Key path '\(attribute)' not found on object \(node.view).")
//			}
//		}

//		public override func postprocessElement(node: GravityNode) -> GravityResult {
//		}
	}
}