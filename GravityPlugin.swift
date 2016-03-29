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

//@objc
//public enum GravityInclusion: Int {
//	case Exclude = 0
//	
//	case Include = 1
//}
// consider changing the above to a different metaphor like "Claimed", which would mean that the plugin claims ownership of the handling of the attribute, and will continue to process it at all stages.

@available(iOS 9.0, *)
@objc public protocol GravityElement { // MARK: GravityElement
	optional static func instantiateView(node: GravityNode) -> UIView? // experimental
	
//	var recognizedAttributes: [String]? { get } // good riddance
	
	/// The main attribute handler for the element. You will receive *either* `stringValue` or `nodeValue` as the value for each attribute of your element, depending on the type of the attribute.
	/// - parameter node: The `GravityNode` the attribute applies to.
	/// - parameter attribute: The attribute to process. If you recognize this attribute, you should process its value and return `Handled`. If you do not recognize the attribute, return `NotHandled` to defer processing.
	/// - parameter value: The value of the attribute. The attribute may have a `stringValue` or it may have child nodes.
//	func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult
	
	func processElement(node: GravityNode) // return true if you handled your own child nodes, otherwise false to handle them automatically
	
//	optional func handleChildNodes(node: GravityNode) // if this is implemented we assume they are handled
	optional func processContents(node: GravityNode)
	
	// should we add an explicit handleChildNodes? that way we can avoid returning a gravityresult above
	
	optional func connectController(node: GravityNode, controller: UIViewController) // return?
	// add a method to bind an id? or just use processAttribute?
}

@available(iOS 9.0, *)
@objc public class GravityPlugin: NSObject {
	override required public init() {
		super.init()
	}
	
	/// Provide an array of `String`s representing the elements this plugin handles. If you return `nil`, the plugin will be called for every element. (There are many hooks so this can amount to a lot of calls if you do not provide a definition.)
	///
	/// You should only return `nil` if the plugin’s interpretation of the element is dynamic and not registrable.
	///
	/// **Important:** You should provide an accurate definition for this property for performance reasons. Only return `nil` if you need to.
//	public var registeredElements: [String]? {
//		get {
//			return nil
////			preconditionFailure("This property must be overridden.")
//		}
//	}
	
	// this is now an OPTIONAL array
	/// Provide an array of `String`s representing the attributes this plugin handles. If you return `nil`, the plugin will be called for every attribute. (There are many hooks so this can amount to a lot of calls if you do not provide a definition.)
	///
	/// You should only return `nil` if the plugin’s interpretation of the attribute is dynamic and not registrable.
	///
	/// **Note:** The default implementation returns an empty array, which is equivalent to matching no attributes.
	///
	/// **Important:** You should provide an accurate definition for this property for performance reasons. Only return `nil` if you need to.
	public var handledAttributes: [String]? { // maybe rename to claimedAttributes or back to handledAttributes
		get {
			return nil // test
//			preconditionFailure("This property must be overridden.")
		}
	}
	
	// MARK: PROCESS PHASE
	
	// This might best be repurposed to a generic first-chance node handler. For example, if the node represents something a plugin can attach to another node, like a gesture, we need to be able to fully handle and process the node without ever actually turning it into a view.
	
	/// Instantiate the view for a given node. The default behavior is to use the node name to look up a class and instantiate it with a parameterless initializer.
	///
	/// **Important:** You should not access the `view` property of the node at this stage, nor should you use the attributes of the node to set up the instance, *unless* you need the attribute for an initializer (e.g. UICollectionView). You can, however, configure the instance based on the node itself. E.g. `<H>` and `<V>` tags affect the `axis` of their instantiated `UIStackView`.
	public func instantiateView(node: GravityNode) -> UIView? {
		// note: we should consider preventing access to the "view" property here
		return nil
	}
	
//	public func preprocessElement(node: GravityNode) -> GravityResult {
//		return .NotHandled
//	}
	
	// MARK: DOM Phase

	// TODO: convert this to dom- and view-based calls. add a note that the view-based processNode should *not* depend on any state of the view, and should get all of its information solely from the node. it should be fully deterministic based on the provided dynamic dom.
	
	// since this is explicitly for values, should we also pass parentNode and attributName?
	/// This function is called for each (recognized?) attribute in a node, before the node is passed to its general handler. You may handle or modify the node’s value(s) as necessary.
	///
	/// **Important:** This is a *value*-based plugin call. The instance of your plugin that is called will belong to the document where the value is actually defined, which is not necessarily the same document where the parent element is defined.
	///
	/// **Note:** This function may be called multiple times, but the constraints will be reset upon each call, so you don't have to worry about removing or updating constraints. You are, however, responsible for maintaining any other state.
	public func processValue(value: GravityNode) {
//		return .Include
	}
	
	// TODO: we could consider adding another value hook that acts as an initializing call, called only once per value
	// but even then consider what happens if say a width value changes. we need to handle that.
	
	// can we wrap this into a default processValue??
//	public func fallbackHandleAttribute(node: GravityNode, attribute: String) -> GravityResult { // no value--access it dynamically
//		return .NotHandled
//	}
	
	/// This is the primary node handler function that typically houses most of the behavior of a typical plugin. You should examine the supplied node object for any attributes your plugin recognizes, and handle them accordingly.
	///
	/// This function may be called multiple times on the same node.
	public func processNode(node: GravityNode) { // rename processElement?
//		return .Include
	}
	
	// MARK: View Phase
	// TODO: rename these as appropriate
	
//	public func handleValue(value: GravityNode) -> GravityResult {
//		return .NotHandled
//	}
	
	/// The main attribute handler in the view cycle.
	///
	/// - node: The node.
	public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
		return .NotHandled
	}
	
	// do we need a handleNode call? that would probably be confusing and might lead to developers just attempting to handle all attributes there
	
	/// Pre-process value transformation. Overload this method if you want to transform or otherwise process the value of an attribute relative to the *value’s* DOM before it is handled, and are not changing the type of the value to something other than a `GravityNode`.
	///
	/// This function is called whenever an attribute's value is accessed and therefore may be called multiple times for the same value.
	///
	/// **Important:** This is a *value*-based plugin call. The plugin instance called will belong to the document where `value` is defined, not necessarily `node`.
//	public func preprocessValue(value: GravityNode) {
//		// this is an experimental value-based function that is called on the plugin of the document wherein the value is defined, not the document that value ends up being used in
//	}
	
	// to cache or not to cache...
	// NOTE: we may not even need/want this anymore since all attributes will have to be declaratively computed in the DOM phase
	/// This function is called on demand whenever an attribute’s value is accessed on a node. You may modify any of the **value** properties on the node (`stringValue`, `objectValue`, etc.) that correspond to the expected interpretation of the attribute by its handler.
//	public func transformValue(value: GravityNode) {
//	}
	
	// similar to processNode, but called on value nodes
	// this is for *handling* attributes at the value level (e.g. widthIdentifiers), no transformations should take place
	// should these be filtered by recognizedAttributes (based on attributeName)?
	// should we only call this on plugins that pass the first wave?
	
	// Actually I'm wondering whether we need this to return a GravityResult. It's potentially confusing/misleading to do this along with string transformation. Returning Handled means stop processing, so to change the value and have it work you have to return NotHandled, which seems wrong.
	// But if we don't return a GravityResult, how will plugins be able to prevent attributes from being attempted? Do we really need that? Yes, we do need a way to break the chain.
	
	/// This is the first-chance handler. Returning `Handled` means no more processing will take place *after* the pre-process phase completes.
//	public func preprocessAttribute(node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult { // i don't think we need inout at all anymore since GravityNodes are object types and any changes to their stringValue will be captured
//	// no wait maybe we do, because the plugin could change the entire object completely, not just its stringValue
//		return .NotHandled
//	}
	
	/// This handler allows an attribute’s value to be transformed from a `String` to any other object type before it is delivered to the element handler.
//	public func transformValue(node: GravityNode, attribute: String, input: GravityNode, inout output: AnyObject) -> GravityResult {
//		return .NotHandled
//	}

	// i wonder if we should rename this postprocessValue and make it a value-based call?
	
	// TODO: this should be renamed to something like lastChance or attributeFallback or defaultHandler or something
	// defaultHandler... what if we used blocks for plugins? would that be insane?
	
	/// Post-process value transformation. Overload this method if you want to transform the value of an attribute before it is passed to the default handler. You can change the value to any type.
	///
	/// **Important:** This is a *value*-based plugin call. The plugin instance called will belong to the document where `value` is defined, not necessarily `node`.
//	func postprocessValue(value: GravityNode) -> Any? { // could rename transformValue
//		return nil//.NotHandled
//	}
	
//	func postprocessAttribute(node: GravityNode, attribute: String, value: AnyObject) -> GravityResult {
//		return .NotHandled
//	}

//	func postprocessElement(node: GravityNode) {
////		return .NotHandled
//	}
	

	/// Implement this function if you want to handle child nodes explicitly and do not want Gravity’s default view embedding.
	///
	/// For example, a custom view container like a `UIStackView` will handle its child views differently from a normal `UIView`.
	///
	/// **Note:** If your handling of child nodes affects only the configuration of the current node and does not result in views being added to the view hierarchy, you should do that processing in `processNode` instead so that it is called whenever the node needs to be updated. You will probably still want to provide an empty definition of this method to avoid the default handling, however.
	public func processContents(node: GravityNode) -> GravityResult {
		return .NotHandled
	}
	
	// MARK: POST-PROCESS PHASE
	
	// this is a post-process wave that runs after everything ran through once during the initial attribute parsing phase. you can use this phase to check for identifiers that were registered and be sure that the tree has been fully parsed.
	public func postprocessNode(node: GravityNode) {
	}
	
	// add a hook for when the document is completely parsed?
	public func postprocessDocument(document: GravityDocument) {
	}
}
