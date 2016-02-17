//
//  GravityPlugin.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-13.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

/// Return one of these values from certain plugin functions to indicate whether the function fully handled the operation or whether it should defer handling to another subsystem. See the documentation for each plugin function to see how this value is interpreted for each case.
@objc
public enum GravityResult: Int {
	/// Return this value to indicate that the function was not able to completely handle the given operation, and that Gravity should continue to find a handler for the operation.
	case NotHandled = 0
	/// Return this value to indicate that the operation was successfully handled, and that further attempts to handle it should stop. See the documentation for each plugin function to see how this value is interpreted for each case.
	case Handled = 1
}

@available(iOS 9.0, *)
@objc public class GravityPlugin: NSObject {
	override required public init() {
		super.init()
	}
	
	/// Instantiate the view for a given node. The default behavior is to use the node name to look up a class and instantiate it with a parameterless initializer.
	///
	/// **Important:** You should not access the `view` property of the node at this stage, nor should you use the attributes of the node to set up the instance, *unless* you need the attribute for an initializer (e.g. UICollectionView). You can, however, configure the instance based on the node itself. E.g. `<H>` and `<V>` tags affect the `axis` of their instantiated `UIStackView`.
	public func instantiateElement(node: GravityNode) -> UIView? {
		// note: we should consider preventing access to the "view" property here
		return nil
	}
	
	/// This is the first-chance handler. Returning `Handled` means no more processing will take place *after* the pre-process phase completes.
	public func preprocessAttribute(node: GravityNode, attribute: String, inout value: String) -> GravityResult {
		return .NotHandled
	}
	
	/// This handler allows an attribute’s value to be transformed from a `String` to any other object type before it is delivered to the element handler.
	public func transformValue(node: GravityNode, attribute: String, input: String, inout output: AnyObject) -> GravityResult {
		return .NotHandled
	}
	
	/// This is the last-chance handler. This method will only be called if the attribute is not handled by any prior means.
	public func postprocessAttribute(node: GravityNode, attribute: String, value: AnyObject) {
	}
	
	// this is the last-chance handler
	public func postprocessElement(node: GravityNode) { // maybe rename this to something like elementCreated or postProcessElement
	}
	
	// add a hook for when the document is completely parsed?
}
