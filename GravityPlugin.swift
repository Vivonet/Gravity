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
	
	/// **NOT YET IN EFFECT**
	/// Provide an array of `String`s representing the attributes this plugin handles. If you return `nil`, the plugin will be called for every attribute. (There are many hooks so this can amount to a lot of calls if you do not provide a definition.)
	///
	/// You should only return `nil` if the plugin’s interpretation of the attribute is dynamic and not registrable.
	///
	/// **Important:** You should provide an accurate definition for this property for performance reasons. Only return `nil` if you need to.
	public var registeredAttributes: [String]? {
		get {
			preconditionFailure("This method must be overridden")
		}
	}
	
	/// **NOT YET IN EFFECT**
	/// Provide an array of `String`s representing the elements this plugin handles. If you return `nil`, the plugin will be called for every element. (There are many hooks so this can amount to a lot of calls if you do not provide a definition.)
	///
	/// You should only return `nil` if the plugin’s interpretation of the element is dynamic and not registrable.
	///
	/// **Important:** You should provide an accurate definition for this property for performance reasons. Only return `nil` if you need to.
	public var registeredElements: [String]? {
		get {
			preconditionFailure("This method must be overridden")
		}
	}
	
	public func preprocessElement(node: GravityNode) -> GravityResult {
		return .NotHandled
	}
	
	// This might best be repurposed to a generic first-chance node handler. For example, if the node represents something a plugin can attach to another node, like a gesture, we need to be able to fully handle and process the node without ever actually turning it into a view.
	
	/// Instantiate the view for a given node. The default behavior is to use the node name to look up a class and instantiate it with a parameterless initializer.
	///
	/// **Important:** You should not access the `view` property of the node at this stage, nor should you use the attributes of the node to set up the instance, *unless* you need the attribute for an initializer (e.g. UICollectionView). You can, however, configure the instance based on the node itself. E.g. `<H>` and `<V>` tags affect the `axis` of their instantiated `UIStackView`.
	public func instantiateElement(node: GravityNode) -> UIView? {
		// note: we should consider preventing access to the "view" property here
		return nil
	}
	
	
	public func preprocessValue(node: GravityNode, attribute: String, value: GravityNode) {
		// this is an experimental value-based function that is called on the plugin of the document wherein the value is defined, not the document that value ends up being used in
	}
	
	// Actually I'm wondering whether we need this to return a GravityResult. It's potentially confusing/misleading to do this along with string transformation. Returning Handled means stop processing, so to change the value and have it work you have to return NotHandled, which seems wrong.
	// But if we don't return a GravityResult, how will plugins be able to prevent attributes from being attempted? Do we really need that?
	
	/// This is the first-chance handler. Returning `Handled` means no more processing will take place *after* the pre-process phase completes.
	public func preprocessAttribute(node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult { // i don't think we need inout at all anymore since GravityNodes are object types and any changes to their textValue will be captured
	// no wait maybe we do, because the plugin could change the entire object completely, not just its textValue
		return .NotHandled
	}
	
	/// This handler allows an attribute’s value to be transformed from a `String` to any other object type before it is delivered to the element handler.
//	public func transformValue(node: GravityNode, attribute: String, input: GravityNode, inout output: AnyObject) -> GravityResult {
//		return .NotHandled
//	}
	
	// TODO: this should be renamed to something like lastChance
	
	/// This is the last-chance handler. This method will only be called if the attribute is not handled by any prior means.
	public func postprocessAttribute(node: GravityNode, attribute: String, value: GravityNode) {
	}
	
	// this is the last-chance handler
	public func postprocessElement(node: GravityNode) { // maybe rename this to something like elementCreated or postProcessElement
	}
	
	// add a hook for when the document is completely parsed?
}
