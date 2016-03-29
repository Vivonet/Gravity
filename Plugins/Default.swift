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
		
		var defaultValues = [GravityNode: [String: AnyObject?]]() // when should we purge this?
		
		// deprecated
//		public override var recognizedAttributes: [String]? {
//			get {
//				return nil // all attributes
//			}
//		}
		
		static var swizzleToken: dispatch_once_t = 0
		
		// we should abstract this to a function in core that just swaps two selectors on a class like swizzle(UIView.self, selector1, selector2)
		public override class func initialize() {
			dispatch_once(&swizzleToken) {
				// method swizzling:
				let loadView_orig = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.loadView))
				let loadView_swiz = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.grav_loadView))
				
				if class_addMethod(UIViewController.self, #selector(UIViewController.loadView), method_getImplementation(loadView_swiz), method_getTypeEncoding(loadView_swiz)) {
					class_replaceMethod(UIViewController.self, #selector(UIViewController.grav_loadView), method_getImplementation(loadView_orig), method_getTypeEncoding(loadView_orig));
				} else {
					method_exchangeImplementations(loadView_orig, loadView_swiz);
				}
			}
		}
		
		public override func instantiateView(node: GravityNode) -> UIView? {
			var type: AnyClass? = NSClassFromString(node.nodeName)
			
			if type == nil { // couldn't find type; try Swift style naming
				if let appName = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleName") as? String {
					type = NSClassFromString("\(appName).\(node.nodeName)")
				}
			}
			
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
				vc.gravityNode = node
				node.controller = vc // this might be a problem since node.view is not set at this point (dispatch_async?)
				// FIXME: there is a design issue here: accessing vc.view calls viewDidLoad on the vc; we should think of a way to avoid doing this until the very end, which may involve wrapping it in an extra view, or swizzling viewDidLoad
				return UIView() // this will be bound to the node; is a plain UIView enough?
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
		public override func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
//			guard let node = value.parentNode else {
//				return .NotHandled
//			}
			guard let attribute = attribute else {
				return .NotHandled
			}
//			NSLog("KeyPath \(attribute) converted
			var objectValue: AnyObject?
			
			if value != nil {
				objectValue = value!.objectValue
				
				tryBlock {
					let defaultValue = node.view.valueForKeyPath(attribute)
					if self.defaultValues[node] == nil {
						self.defaultValues[node] = [String: AnyObject?]()
					}
					self.defaultValues[node]![attribute] = defaultValue
				}
			} else {
				if let nodeIndex = defaultValues[node] {
					if let defaultValue = nodeIndex[attribute] {
						NSLog("Default value found for attribute \(attribute): \(defaultValue)")
						objectValue = defaultValue
					}
				}
			}
			
			if let objectValue = objectValue {
				if tryBlock({
					NSLog("Setting property \(attribute) to value: \(objectValue)")
					node.view.setValue(objectValue, forKeyPath: attribute)
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

@available(iOS 9.0, *)
extension UIViewController {
	public func grav_loadView() {
		if self.gravityNode != nil {
			self.view = self.gravityNode?.view
			// TODO: make sure this works for all levels of embedded VCs
		}
		
		if !self.isViewLoaded() {
			grav_loadView()
		}
	}
}