//
//  GravityNode.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-11.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
// TODO: split these protocols into extensions to follow Swift conventions
@objc public class GravityNode: NSObject, CustomDebugStringConvertible {
	public var document: GravityDocument! // should this be weak?
	public weak var parentNode: GravityNode?
	public var nodeName: String
	// FIXME: i think depth is broken for attribute nodes; does that matter? (should fix anyway if it's not a huge effort)
	
	/// The number of nodes deep this node is in the immediate document.
	
	/// The number of nodes deep this node is in the fully composed tree.
	public var recursiveDepth: Int { // rename recursiveDepth?
		get {
			// we can optimize this later
			var depth = 0
			var parent = self.parentNode
			while parent != nil {
				depth++
				parent = parent?.parentNode ?? parent?.document.parentNode
			}
//			NSLog("depth of \(self.nodeName): \(depth)")
			return depth
		}
	}
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed tree; this must be the FULL depth of the tree, including all embedded subdocuments, and should happen in the preprocess phase.
	public var attributes = [String: GravityNode]()
//	public var stringValues: [String: String]
//	public var nodeValues: [String: GravityNode]
	public var constraints = [String: NSLayoutConstraint]() // store constraints here based on their attribute name (width, minHeight, etc.) -- we should move this to a plugin, but only if we can put all or most of the constraint registering in there as well
	public var childNodes = [GravityNode]()
	public var childDocument: GravityDocument? = nil // if this node represents an external document
	/// The textual value of the node as a `String`, if the node is a text node (e.g. an inline attribute). Returns `nil` if the current node does not have a textual value.
	public var textValue: String?
	
	public var boolValue: Bool? {
		get {
			return (textValue as NSString?)?.boolValue
		}
	}
	
	public var intValue: Int? {
		get {
			return (textValue as NSString?)?.integerValue
		}
	}
	
	public var floatValue: Float? {
		get {
			return (textValue as NSString?)?.floatValue
		}
	}
	
	/// An attribute’s value will always be either a `String` or a `GravityNode`.
	subscript(attribute: String) -> GravityNode? {
		get {
			return attributes[attribute]
		}
	}
	
//	public var attributes: [String: AnyObject] {
//		get {
//			return Dictionary<String, AnyObject>(stringValues) + Dictionary<String, AnyObject>(nodeValues)
//		}
//	}
	
	public var controller: NSObject? = nil {
		didSet {
			if let controller = controller {
				connectController(controller)
			}
		}
	}
		
	// oh but it would be sweet if we could do this!
//	subscript<T>(attribute: String) -> T? {
//		get {
//			return Gravity.convert(attribute) as T?
//		}
//	}
	
	// i think view should actually be UIView? because not all nodes are views
	// either we throw an exception or we just make this optional
	private var _view: UIView? // should this actually be weak?? i would think that we would hang onto the view while we are using it, and if we lose our reference to that, we can always rebuild it again from the gravity on demand (may take some refactoring to keep _view alive while we need it)
	public var view: UIView {
		get {
			if _view == nil {
				processNode()
			}
			return _view!
		}
	}
	
	public var _model: AnyObject?
	/// The model object that this node is viewing. Sometimes called a data context.
	public var model: AnyObject? { // should we force this to be NSObject?
		get {
			let value = _model ?? parentNode?.model ?? document.model // recursion is beautiful.
			if value == nil && parentNode == nil {
				return document.parentNode?.model // up a document (models pass through document barriers)
			}
			return value
		}
		set(value) {
			_model = value
		}
	}
	
	public init(document: GravityDocument, parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.document = document
		self.nodeName = nodeName
		super.init()
		for (attribute, textValue) in attributes {
			self.attributes[attribute] = GravityNode(document: document, parentNode: self, nodeName: self.nodeName + "." + attribute, textValue: textValue)
		}
//		self.attributes = attributes
//		self.constraints = [String: NSLayoutConstraint]()
		self.parentNode = parentNode
		setup()
//		self.ids = self.parentNode?.ids ?? [String: GravityNode]() // make sure this is copied by ref
	}
	
	// string nodes must have a parent (?)
	public init(document: GravityDocument, parentNode: GravityNode?, nodeName: String, textValue: String) {
		self.document = document
		self.nodeName = nodeName
		self.parentNode = parentNode
		self.textValue = textValue
		super.init()
		setup()
	}
	
	private func setup() {
//		self.depth = (parentNode?.depth ?? 0) + 1
		self.attributes = self.attributes ?? [String: GravityNode]()
	}
	
	public func instantiate(model: AnyObject? = nil) -> GravityDocument {
		// TODO: return an instantiated document (or possibly view); to be used for row/item templating
		preconditionFailure()
	}
	
	public func isViewInstantiated() -> Bool {
		return _view != nil
	}
	
	/// Returns the value of the given scoped attribute, if it is a `String`.
	///
	/// *Note:* Scoped attributes do not pass through document boundaries.
	public func getScopedAttribute(attribute: String) -> GravityNode? {
		return attributes[attribute] ?? parentNode?.getScopedAttribute(attribute)
	}
	
	public override var description: String {
		get {
			return getDescription(false)
		}
	}
	
	public override var debugDescription: String {
		get {
			return getDescription(true)
		}
	}
	
	internal func getDescription(debug: Bool = false) -> String {
		var attributeStrings = [String]()
		var attributeNodes = [GravityNode]()
		for (key, value) in attributes {
			if let textValue = value.textValue {
				// FIXME: add proper escaping for XML attribute value
				let escapedValue = textValue.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(escapedValue)\"")
			} else {
				attributeNodes.append(value)
			}
		}
		
		let address = debug && self.isViewInstantiated() ? "(\(unsafeAddressOf(view)))" : ""
		let childNodes = self.childNodes + attributeNodes // verify
		
		if childNodes.count > 0 {
			var childNodeStrings = [String]()
			// TODO: add attributeNodes?
			for childNode in childNodes {
				childNodeStrings.append(childNode.getDescription(debug))
			}
			
			if let textValue = textValue {
				childNodeStrings.append(textValue)
			}
			
			return "<\(nodeName)\(address)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
		} else if textValue != nil {
			return "<\(nodeName)\(address)>\(textValue!)</\(nodeName)>"
		} else {
			return "<\(nodeName)\(address) \(attributeStrings.joinWithSeparator(" "))/>"
		}
	}
	
	public func processNode() {
		let className = self.nodeName
		
		_view = _view ?? document.instantiateView(self) // this lets plugins have a chance to see every node, in some capacity
		view.gravityNode = self // this is now strong (ok?)
//		view.clipsToBounds = true
		
		// childDocument is set in the pre-processing phase
		if let childDocument = childDocument {
			childDocument.node._view = _view // perhaps there is a better place for this
			childDocument.node.processNode() // recurse
//			childDocument.postprocess() // experimental (all we need is for the view to be attached so in theory this should be fine)
		}
		
		for attribute in attributes.keys {
			processAttribute(attribute) // look up the value in an index
		}
		
		// TODO: set a flag and disallow access to the "controller" property? can it even be accessed from processElement anyway? presumably only from GravityView, so it's probably not a big deal
		
		if let gravityElement = view as? GravityElement {
			if gravityElement.processElement?(self) == .Handled { // handled here means completely, child nodes included
				return //view // handled
			}
		}
		
		for plugin in document.plugins {
			if plugin.handleChildNodes(self) == .Handled {
				return // ?
			}
		}
	}
	
	public func processAttribute(attribute: String) {
		// FIXME: make sure this works for node values
		guard let rawValue = attributes[attribute] else { // do we need rawValue if this can be an object now?
			return
		}
		
		var value: GravityNode = rawValue
//		var stringValue: String = rawValue ?? "\(value)" // if value is a node, this will represent the xml of the node
		var handled = false
		
		for plugin in value.document.plugins { // ooh, a *value*-based plugin hook!
			plugin.preprocessValue(self, attribute: attribute, value: value)
		}
		
		// 1. First-chance handling by plugins
		for plugin in document.plugins {
			var newValue = value // value must be a String here
			// TODO: make sure the order here is correct!!
			if plugin.preprocessAttribute(self, attribute: attribute, value: &newValue) == .Handled {
				handled = true
			}
			value = newValue // do this regardless of whether the call returns Handled or not
		}
		
		if handled {
			return
		}
		
		// 3. GravityElement handling
		if let gravityElement = view as? GravityElement {
			if gravityElement.processAttribute(self, attribute: attribute, value: value) == .Handled {
				return
			}
		}
		
		var finalValue: AnyObject = value
		for plugin in value.document.plugins { // experimental second value-based hook!!
			if plugin.postprocessValue(self, attribute: attribute, input: value, output: &finalValue) == .Handled {
				break
			}
		}
		
		// 4. Post-process handling by plugins
		// this is really just a last-chance handler, we should rename it; postprocess is stupid
		
		for plugin in document.plugins {
			if plugin.postprocessAttribute(self, attribute: attribute, value: finalValue) == .Handled {
				return
			}
		}
	}
	
	// TODO: figure out what to do about this (i say move to preprocess)
	public func setAttribute(attribute: String, value: GravityNode) {
		let attributeParts = attribute.componentsSeparatedByString(".")
		
		if attributeParts.count > 1 {
			if let subDoc = self.childDocument {
				let identifier = attributeParts.first!
				let remainder = attributeParts.suffixFrom(1).joinWithSeparator(".")
				if let child = subDoc.ids[identifier] {
					child.setAttribute(remainder, value: value)
				}
			} else {
				NSLog("Error: Cannot use dot notation for an attribute on a node that is not an external gravity file.")
			}
		} else {
			attributes[attribute] = value // we may need to record some information about the document this attribute came from (wait, that's in the value node!)
//			processAttribute(attribute) // this may be a bad idea
		}
	}
	
	internal func connectController(controller: NSObject) {
		if isViewInstantiated() {
			(view as? GravityElement)?.connectController?(self, controller: controller)
		}
		for childNode in childNodes {
			childNode.connectController(controller)
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode: SequenceType {
	public func generate() -> AnyGenerator<GravityNode> {
		var childGenerator = childNodes.generate()
		var subGenerator : AnyGenerator<GravityNode>?
		var returnedSelf = false

		return anyGenerator {
			if !returnedSelf {
				returnedSelf = true
				return self
			}

			if let subGenerator = subGenerator,
				let next = subGenerator.next() {
					return next
			}

			if let child = childGenerator.next() {
				subGenerator = child.generate()
				return subGenerator!.next()
			}

			return nil
		}
	}
}
