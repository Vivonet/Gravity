//
//  Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-20.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation
import ObjectiveC
import UIKit

// TODO: add identifiers for all added constraints

// the knobs! all in one place for easy dialing
internal struct GravityPriority {
	static let FillSizeHugging: UILayoutPriority = 50
	static let StackViewSpacerHugging: UILayoutPriority = 100 // must be higher than fill size hugging priority
	/// The generic containment constraint of an autosizing `UIView`. These constraints ensure that the view will automatically size to fit its contents, but are low priority so as to be easily overridden.
	static let HostViewContainment = Float(200) // the "bubble" priority to use when a parent is filled but not the child; we can think of this as a direction of force // TODO: rename DivergentContainment
	static let ViewContainment: UILayoutPriority = 300 // < 250 to delegate to intrisic size, but should be > 250 if we want to override intrinsic size
	static let Gravity: Float = 700
	static let BaseCompressionResistance: Float = 750
	/// This priority affects edge binding in a fill size scenario.
	static let FillSize: UILayoutPriority = 800
	/// This priority is used when a view is constrained to an explicit size in your gravity file by means of a `width`, `height`, `maxWidth`, etc.
	static let ExplicitSize: UILayoutPriority = 900 // was 800
}

@objc
public enum AttributeScope: Int {
	case Local = 0
	case Document
	case Global
}
// garbage swift makes you do:
public func < (lhs: AttributeScope, rhs: AttributeScope) -> Bool {
	return lhs.rawValue < rhs.rawValue
}
// more garbage swift makes you do (seriously, swift?):
extension AttributeScope: CustomStringConvertible {
	public var description: String {
		get {
			switch self {
				case .Local:
					return "Local"
				
				case .Document:
					return "Document"
				
				case .Global:
					return "Global"
			}
		}
	}
}

@available(iOS 9.0, *)
@objc public class Gravity: NSObject { // class or struct?
	internal static var plugins = [GravityPlugin.Type]()
	internal static var window: UIWindow? // a strong reference to a window when started from Gravity.start()
	
	public override class func initialize() {
		// it probably makes sense to put plugins with specifically registered identifiers last as they will be the quickest to check (when implemented)
		registerPlugin(Default) // default always runs last
		registerPlugin(Conversion) // this doesn't technically need to be a plugin anymore
		registerPlugin(Constants)
		registerPlugin(Layout)
		registerPlugin(Styling)
		registerPlugin(Appearance)
		registerPlugin(Templating) // should templating be much lower, so nodes can define dynamic definitions for gravity attributes??
		registerPlugin(Conditionals)
		registerPlugin(Adaptive)
		
		// Class Support
		UITableView.initializeGravity()
	}
	
//	public class func start(xml: String) {
//	
//	}

	// experimental: (used for dependency recording)
//	public static var currentNode: GravityNode? = nil

	internal static var syncDOMCycle = false
	
	private static var _domDependence = [NSThread : [(GravityNode, String)]]()
	internal static var domDependence: [(GravityNode, String)] { // what was the intention in allowing attribute to be optional here? dependencies should be specifically attribute-based in the dom cycle
		get {
			let thread = NSThread.currentThread()
			if _domDependence[thread] == nil {
				_domDependence[thread] = [(GravityNode, String)]()
			}
			return _domDependence[thread]!
			
			// TODO: to properly clean this up we should add a method to pop the node so we can remove the index entry when the stack reaches 0
		}
		set(value) {
			let thread = NSThread.currentThread()
			_domDependence[thread] = value
		}
	}
	internal static var viewDependence: (GravityNode, String?)? = nil // not thread-local because the view cycle always runs on the main thread (UIKit requirement)
//	internal static var viewStack = [(GravityNode, String?)]() // nil string means postprocess (generic) handler, which only applies to the view cycle (or does it?)
	
//		get {
//			return NSThread.currentThread().threadDictionary["Gravity_activeNode"] as? GravityNode
//		}
//		set(value) {
//			NSThread.currentThread().threadDictionary["Gravity_activeNode"] = value
//		}
//	}
	
	/// Essentially represents an atomic point in time, counting in changes made to the DOM.
	public static var currentToken: Int = 0 // TODO: make this thread-safe
	public static var processing = false
	
	private static var updateScheduled = false
	// i don't think we want to do this on the document level anymore.
//	public static var pendingDocuments = Set<GravityDocument>() {
//		didSet {
//			// TODO: add appropriate synchronization when we make this multithreaded
//			if !updateScheduled && pendingDocuments.count > 0 {
//				updateScheduled = true
//				dispatch_async(dispatch_get_main_queue()) {
//					updateScheduled = false
//					let startTime = NSDate()
//					let documentsToProcess = Gravity.pendingDocuments
//					Gravity.pendingDocuments.removeAll()
//					for document in documentsToProcess {
//						document.node.processView()
//					}
//					let endTime = NSDate()
//					print("⏱ View Cycle time: \(Int(round(endTime.timeIntervalSinceDate(startTime) * 1000))) ms")
//				}
//			}
//		}
//	}

	internal static var domCycle: Bool {
		get {
			return Gravity.syncDOMCycle || !NSThread.isMainThread()
		}
	}
	
	// experimental. reflects all nodes changed in the current dom cycle.
//	public static var changedNodes = Set<GravityNode>()
//		get {
//			if NSThread.currentThread().threadDictionary["Gravity_changedNodes"] == nil {
//				NSThread.currentThread().threadDictionary["Gravity_changedNodes"] = Set<GravityNode>()
//			}
//			return NSThread.currentThread().threadDictionary["Gravity_changedNodes"] as! Set<GravityNode>
//		}
//		set(value) {
//			NSThread.currentThread().threadDictionary["Gravity_changedNodes"] = value
//		}
//	}
	
	// the nodes that have been processed during this cycle (there's probably a better way to do this)
//	public static var processedNodes = Set<GravityNode>()
//		get {
//			if NSThread.currentThread().threadDictionary["Gravity_processedNodes"] == nil {
//				NSThread.currentThread().threadDictionary["Gravity_processedNodes"] = Set<GravityNode>()
//			}
//			return NSThread.currentThread().threadDictionary["Gravity_processedNodes"] as! Set<GravityNode>
//		}
//		set(value) {
//			NSThread.currentThread().threadDictionary["Gravity_processedNodes"] = value
//		}
//	}	
	
	// do we really want to pass a controller? wouldn't it be easier to make the root of the document a controller if we want that? we should pass model instead
	// we should provide an alternative that lets us specify a type as that will be handy for things like view controllers: Gravity.start(MyViewController.self)
	public class func start(name: String, model: AnyObject? = nil) -> GravityDocument {
		let document = GravityDocument(name)
		document.model = model
		self.start(document)
		return document
	}
	
	public class func start(document: GravityDocument) {
		let gvc = GravityViewController(document: document)
		Gravity.window = UIWindow(frame: UIScreen.mainScreen().bounds)
		Gravity.window!.rootViewController = gvc
		Gravity.window!.makeKeyAndVisible()
	}
	
	/// Instantiate a new instance of the named layout. You can omit the ".xml" from your layout name for brevity.
	public class func new<T: UIView>(name: String, model: AnyObject? = nil) -> T? {
		// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time.
		let document = GravityDocument(name, model: model)
		if document.error == nil {
			return document.view as? T // verify
		}
		
		return nil
	}
	
	public class func new<T: UIView>(type: T.Type, model: AnyObject? = nil) -> T? {
		return self.new("\(type)") as! T? // verify
	}
	
	/// The same as Gravity.new() but Objective-C friendly.
	public class func instantiate(name: String, model: AnyObject? = nil) -> UIView? {
		return new(name, model: model)
	}
	
	/// Register the given class as a gravity plugin. The class must be a subclass of `GravityPlugin` and have a parameterless initializer. Gravity will instantiate one instance of your plugin for each `GravityDocument` it parses and its lifetime will coincide with the lifetime of the document.
	public class func registerPlugin(type: GravityPlugin.Type) {
		plugins.insert(type, atIndex: 0) // plugins acts as a stack, this lets us iterate it forwards instead of having to reverse it each time
	}
}

extension Gravity {
	private static var swizzleIdentifiers = Set<String>()
	// make internal?
	public class func swizzle(type: AnyClass, original: Selector, override: Selector) {
		let swizzleIdentifier = "\(type).\(original).\(override)"
		if swizzleIdentifiers.contains(swizzleIdentifier) {
			NSLog("Warning: Method already swizzled! Identifier: \(swizzleIdentifier)")
			return
		}
		
		swizzleIdentifiers.insert(swizzleIdentifier)
		
		let originalImpl = class_getInstanceMethod(type, original)
		let swizzledImpl = class_getInstanceMethod(type, override)
		
		if class_addMethod(type, original, method_getImplementation(swizzledImpl), method_getTypeEncoding(swizzledImpl)) {
			class_replaceMethod(type, override, method_getImplementation(originalImpl), method_getTypeEncoding(originalImpl));
		} else {
			method_exchangeImplementations(originalImpl, swizzledImpl);
		}
	}
}

// TODO: create this and use it as the model for an ErrorView
enum GravityError: ErrorType {
	case InvalidParse
}