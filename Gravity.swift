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

// don't change these values unless you know what you are doing! ;)
struct GravityPriorities {
	static let FillSizeHugging: UILayoutPriority = 99
	/// The generic containment constraint of an autosizing `UIView`. These constraints ensure that the view will automatically size to fit its contents, but are low priority so as to be easily overridden.
	static let ViewContainment: UILayoutPriority = 300
	static let BaseCompressionResistance: Float = 750
	static let FillSize: UILayoutPriority = 800
	static let ExplicitSize: UILayoutPriority = 900 // was 800
}

// rename to GravityCore?
@available(iOS 9.0, *)
@objc public class Gravity: NSObject { // class or struct?
	internal static var plugins = [GravityPlugin.Type]()
	
	public override class func initialize() {
		// it probably makes sense to put plugins with specifically registered identifiers last as they will be the quickest to check (when implemented)
		registerPlugin(Default) // default always runs last
		registerPlugin(Conversion)
		// i'm actually not sure this is true anymore to be honest; conversion is now on-demand (it may not even need to be a plugin technically)
		registerPlugin(Templating) // important: templating MUST be processed before type conversion (these are backwards because plugins are processed in reverse order)
		registerPlugin(Constants)
		registerPlugin(Layout)
		registerPlugin(Styling)
		registerPlugin(Appearance)
	}
	
//	public class func start(xml: String) {
//	
//	}
	
	// really wish there were a way to actually set the app's window property
	public class func start(name: String, model: AnyObject? = nil) -> UIWindow {
		let window = UIWindow(frame: UIScreen.mainScreen().bounds)
		// i really wish we could assign UIApplication.sharedApplication().delegate.window from here; that would make this a lot more elegant
		
		window.rootViewController = GravityViewController(name: name, model: model)
		window.makeKeyAndVisible()

		return window
	}
	
	/// Instantiate a new instance of the named layout. You can omit the ".xml" from your layout name for brevity.
	public class func new<T: UIView>(name: String, model: AnyObject? = nil) -> T? {
		// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time.
		if let document = GravityDocument(name: name, model: model) {
			return document.view as? T // verify
		}
		
		return nil
	}
	
	public class func new<T: UIView>(type: T.Type, model: AnyObject? = nil) -> T? {
		return self.new("\(type)") as! T? // verify
	}
	
	/// The same as Gravity.new() but Objective-C friendly.
	public class func instantiate(name: String, forModel model: AnyObject? = nil) -> UIView? {
		return new(name, model: model)
	}
	
	/// Register the given class as a gravity plugin. The class must be a subclass of `GravityPlugin` and have a parameterless initializer. Gravity will instantiate one instance of your plugin for each `GravityDocument` it parses and its lifetime will coincide with the lifetime of the document.
	public class func registerPlugin(type: GravityPlugin.Type) {
		plugins.insert(type, atIndex: 0) // plugins acts as a stack, this lets us iterate it forwards instead of having to reverse it each time
	}
}

// MARK: -

@available(iOS 9.0, *)
@objc public protocol GravityElement { // MARK: GravityElement
	/// The main attribute handler for the element. You will receive *either* `stringValue` or `nodeValue` as the value for each attribute of your element, depending on the type of the attribute.
	/// - parameter node: The `GravityNode` the attribute applies to.
	/// - parameter attribute: The attribute to process. If you recognize this attribute, you should process its value and return `Handled`. If you do not recognize the attribute, return `NotHandled` to defer processing.
	/// - parameter value: The value of the attribute. The attribute may have a `textValue` or it may have child nodes.
	func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult
	
	optional func processElement(node: GravityNode) -> GravityResult // return true if you handled your own child nodes, otherwise false to handle them automatically
	
	optional func connectController(node: GravityNode, controller: NSObject) // return?
	// add a method to bind an id? or just use processAttribute?
}

// MARK: -

enum GravityError: ErrorType {
	case InvalidParse
}