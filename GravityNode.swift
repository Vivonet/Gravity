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
@objc public class GravityNode: NSObject {
	public var document: GravityDocument! // should this be weak?
	public weak var parentNode: GravityNode?
	public var nodeName = "" // should we compute this automatically if empty?
	/// Returns the name of the attribute this node is defining, if it is an attribute node, or `nil` otherwise.
	
	// FIXME: this needs to change; since attributes can actually be shared, we should instead dynamically compute the nodeName based on the parent node rather than stripping the attribute name out of a hard-coded parent.
	// nodeName itself should be computed with a private optional backing store
	// a node must therefore have either a node name *or* an attribut ename
	// OR, we could consider the attribute name the node name, and have a boolean indicate whether the node should be treated as a value node or not.
	public var attributeName: String? {
		get {
			if nodeName.containsString(".") {
				return nodeName.componentsSeparatedByString(".").last
			} else { // not an attribute node
				return nil
			}
		}
	}
	
	private var _controller: UIViewController? = nil
	public var controller: UIViewController? {
		get {
			return _controller ?? parentNode?.controller // scoped for now, until i discover a good reason otherwise
		}
		set(value) {
			_controller = value
			
			if let controller = _controller {
				connectController(controller) // TODO: should this be called for every child node?
			}
		}
	}
	// FIXME: i think depth is broken for attribute nodes; does that matter? (should fix anyway if it's not a huge effort)
	
	/// The number of nodes deep this node is in the immediate document.
	
	/// The number of nodes deep this node is in the fully composed tree.
	public var recursiveDepth: Int { // rename recursiveDepth?
		get {
			// we can optimize this later
			var depth = 0
			var parent = self.parentNode
			while parent != nil {
				depth += 1
				parent = parent?.parentNode ?? parent?.document.parentNode
			}
//			NSLog("depth of \(self.nodeName): \(depth)")
			// what about return depth + document.parentNode.depth?

			return depth
		}
	}
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed tree; this must be the FULL depth of the tree, including all embedded subdocuments, and should happen in the preprocess phase.
	public var attributes = [String: GravityNode]()
	private var computedAttributes = [String: GravityNode]() // "composited"? or perhaps just [GravityNode]? // these are the dynamically-computed (temporary) attributes
	public var effectiveAttributes: [String: GravityNode] {
		get {
			var effectiveAttributes = attributes // this better make a copy
			for (key, value) in computedAttributes {
				effectiveAttributes[key] = value
			}
			return effectiveAttributes
		}
	}
//	public var stringValues: [String: String]
//	public var nodeValues: [String: GravityNode]
	public var constraints = [String: NSLayoutConstraint]() // store constraints here based on their attribute name (width, minHeight, etc.) -- we should move this to a plugin, but only if we can put all or most of the constraint registering in there as well
	internal lazy var _childNodes = [GravityNode]() // make private if possible
	public var childNodes: [GravityNode] {
		get {
			if isAttributeNode {
				return _childNodes
			} else {
				return contents.childNodes
			}
		}
	}
	public var childDocument: GravityDocument? // if this node represents an external document
	/// The textual value of the node as a `String`, if the node is a text node (e.g. an inline attribute). Returns `nil` if the current node does not have a textual value.
	public var contents: GravityNode {
		get {
//			if self["contents"] == nil {
//				
//			}
			// should we guarantee this exists, or should it be nil if there are no child nodes?
			if isAttributeNode { // attribute nodes act as their own contents
				return self
			}
			assert(self["contents"] != nil)
			return self["contents"]! // TODO: implement
		}
	}
	
	public var rawStringValue: String?
	
	// MARK: Privates
	private var processed = false // the node has been processed via processNode or processValue (we might not actually need this anymore)
	private var valueProcessed = false // the final value(s) of this attribute node have been computed (this nomenclature is confusing, consider renaming)
	private var changed = false
	
	// TODO: this will be changing; i don't think we want any on-demand transformation anymore outside of converters which much be deterministic
	private func processValue() {
		if valueProcessed {
			return
		}
		
		valueProcessed = true
		for plugin in document.plugins {
			plugin.transformValue(self)
		}
	}
	
	// TODO: set an internal flag when these are allowed to be set and fail if attempted at the wrong time
	
	private var _stringValue: String?
	public var stringValue: String? {
		get {
			processValue()
			return _stringValue ?? rawStringValue
		}
		set(value) {
			if processed {
				_stringValue = value
			} else {
				rawStringValue = value // do we want this?
			}
		}
	}
	
	private var _objectValue: AnyObject?
	public var objectValue: AnyObject? {
		get {
			processValue()
			return _objectValue ?? stringValue // or nil?? or self?? with transformation this shouldn't happen
		}
		set(value) {
			if !(_objectValue != nil && value != nil && _objectValue!.isEqual(value)) { // TODO: should this actually use == ? What about something like UIColor? (test this)
				changed = true
			}
//			if !(_objectValue != nil && value != nil && _objectValue! == value!) {
//				changed = true
//			}
			_objectValue = value
		}
	}
	
	private var _boolValue: Bool?
	public var boolValue: Bool? {
		get {
			processValue()
			return _boolValue ?? (stringValue as NSString?)?.boolValue
		}
		set(value) {
			if value != _boolValue {
				changed = true
			}
			_boolValue = value
		}
	}
	
	private var _intValue: Int?
	public var intValue: Int? {
		get {
			processValue()
			if _intValue != nil {
				return _intValue
			}
			if stringValue != nil && stringValue!.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "-0123456789.").invertedSet) == nil {
				return (stringValue as NSString?)?.integerValue
			} else {
				return nil
			}
		}
		set(value) {
			if value != _intValue {
				changed = true
			}
			_intValue = value
			floatValue = value != nil ? Float(value!) : nil // keep numeric values in sync // this is ugly in swift :( why don't nils propagate?? honestly
			// should we set boolValue here too?
		}
	}
	
	private var _floatValue: Float?
	public var floatValue: Float? {
		get {
			processValue()
			if _floatValue != nil {
				return _floatValue
			}
			if stringValue != nil && stringValue!.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "-0123456789.").invertedSet) == nil {
				return (stringValue as NSString?)?.floatValue
			} else {
				return nil
			}
		}
		set(value) {
			if value != _floatValue {
				changed = true
			}
			_floatValue = value
			intValue = value != nil ? Int(value!) : nil // keep numeric values in sync
		}
	}
	
	 // MARK: subscript
	subscript(attribute: String) -> GravityNode? {
		get {
//			return processAttributeValue(attribute) //attributes[attribute]
			if let value = computedAttributes[attribute] ?? attributes[attribute] { // effective (computed) attributes override normal attributes
				for plugin in value.document.plugins { // ooh, a *value*-based plugin hook!
					plugin.transformValue(value)
				}
				return value
			} else {
				return nil
			}
		}
		set(value) {
			if value != nil {
				// TODO: handle "contents" attributes specially
				setAttribute(attribute, value: value!)
			}
		}
	}
		
	// oh but it would be sweet if we could do this!
//	subscript<T>(attribute: String) -> T? {
//		get {
//			return self[attribute].convert() as T?
//		}
//	}
	
	// i think view should actually be UIView? because not all nodes are views
	// either we throw an exception or we just make this optional
	private var _view: UIView? // should this actually be weak?? i would think that we would hang onto the view while we are using it, and if we lose our reference to that, we can always rebuild it again from the gravity on demand (may take some refactoring to keep _view alive while we need it)
	public var view: UIView {
		get {
			if _view == nil {
				processNode()
				assert(_view != nil)
			}
			return _view!
		}
		// should we allow view to be set, and do this in instantiateView instead of returning a view?
	}
	
	public var _model: AnyObject?
	/// The model object that this node is viewing. Sometimes called a data context.
	public var model: AnyObject? { // should we force this to be NSObject?
		get {
			let value = _model ?? parentNode?.model ?? document.model // recursion is beautiful.
			if value == nil && parentNode == nil {
				return document.parentNode?.model // up a document (models pass through document boundaries)
			}
			return value
		}
		set(value) {
			_model = value
		}
	}
	
	private override init() {
		super.init()
		setup()
	}
	
	public init(stringValue: String) {
		super.init()
		self.stringValue = stringValue // or rawStringValue?
		setup()
	}
	
	public init(objectValue: AnyObject) {
		super.init()
		self.objectValue = objectValue
		setup()
	}
	
	public init(boolValue: Bool) {
		super.init()
		self.boolValue = boolValue
		setup()
	}
	
	public init(intValue: Int) {
		super.init()
		self.intValue = intValue
		setup()
	}
	
	public init(floatValue: Float) {
		super.init()
		self.floatValue = floatValue
		setup()
	}
	
	internal init(document: GravityDocument, parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.document = document
		self.nodeName = nodeName
		super.init()
		for (attribute, stringValue) in attributes {
			self.attributes[attribute] = GravityNode(document: document, parentNode: self, attribute: attribute, stringValue: stringValue)
		}
//		self.attributes = attributes
//		self.constraints = [String: NSLayoutConstraint]()
		self.parentNode = parentNode
		setup()
//		self.ids = self.parentNode?.ids ?? [String: GravityNode]() // make sure this is copied by ref
	}
	
	// do we even need/want this anymore?
	internal init(document: GravityDocument, parentNode: GravityNode, attribute: String, stringValue: String) {
		self.document = document
		self.nodeName = "\(parentNode.nodeName).\(attribute)"
		self.parentNode = parentNode
		self.rawStringValue = stringValue
		super.init()
		setup()
	}
	
	internal init(document: GravityDocument, parentNode: GravityNode, attributeName: String) {
		self.document = document
		self.nodeName = "\(parentNode.nodeName).\(attributeName)"
		self.parentNode = parentNode
		super.init()
		setup()
	}
	
	/// **Note:** May be called before the node has been added to the DOM.
	private func setup() {
//		self.depth = (parentNode?.depth ?? 0) + 1
		self.attributes = self.attributes ?? [String: GravityNode]()
		if self.attributeName == nil {
			self["contents"] = GravityNode(document: document, parentNode: self, attributeName: "contents")
		}
	}
	
	/// Creates and returns a new document containing a copy of the remaining tree in the current node's document. This allows you to instantiate arbitrary sub-trees of a layout as new instances of their own layouts.
	public func instantiate(model: AnyObject? = nil) -> GravityDocument {
		let instance = GravityDocument()
		instance.parentNode = self
		instance.xml = self.serialize()
		instance.model = model ?? instance.model
//		instance.node = self.copy(instance)
//		instance.preprocess() // TODO: verify this loads embedded documents
		return instance
	}
	
	public func appendNode(node: GravityNode) {
//		if self["contents"] == nil {
//			self["contents"] = GravityNode(document: document, parentNode: self, attributeName: "contents")
//		}
		self.contents._childNodes.append(node)
		node.parentNode = self
	}
	
	public var viewIsInstantiated: Bool {
		get {
			return _view != nil
		}
	}
	
	public var isAttributeNode: Bool {
		get {
			return attributeName != nil
		}
	}
	
	/// Finds and returns the most recent definition of the given attribute. Scoped attributes are inherited.
	///
	/// *Note:* Scoped attributes do not pass through document boundaries.
	public func getScopedAttribute(attribute: String) -> GravityNode? {
		return self[attribute] ?? parentNode?.getScopedAttribute(attribute)
	}
	
	public override var description: String {
		get {
			return serialize()
		}
	}
	
	public override var debugDescription: String {
		get {
			return serialize(true)
		}
	}
	
	// this presently reflects the initial parsed and preprocessed state of the node
	// we should extend it with options to support optionally retruning the current (computed) state
	// note: debugMode does not return valid xml, but includes memory addresses for all instantiated nodes for easier debugging
	public func serialize(debugMode: Bool = false, indent: String = "  ") -> String {
		var attributeStrings = [String]()
		var attributeNodes = [GravityNode]()
		for (key, value) in attributes {
			if let stringValue = value.rawStringValue {
				// FIXME: add proper escaping for XML attribute value
				let escapedValue = stringValue.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(escapedValue)\"")
			} else {
				attributeNodes.append(value)
			}
		}
		
		let address = debugMode && self.viewIsInstantiated ? "(\(unsafeAddressOf(self)))" : "" // should we return the address of the view or the node?
		let childNodes = self.childNodes + attributeNodes // verify
		
		if childNodes.count > 0 {
			var childNodeStrings = contents.childNodes.map {
				return $0.serialize(debugMode, indent: indent).componentsSeparatedByString("\n").map {
					return "\(indent)\($0)"
				}.joinWithSeparator("\n")
			}
			
			if let stringValue = rawStringValue {
				childNodeStrings.append(stringValue)
			}
			
			return "<\(nodeName)\(address)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
		} else if rawStringValue != nil {
			return "<\(nodeName)\(address)>\(rawStringValue!)</\(nodeName)>"
		} else {
			return "<\(nodeName)\(address) \(attributeStrings.joinWithSeparator(" "))/>"
		}
	}
	
	internal func instantiateView() -> UIView {
		for plugin in document.plugins {
			if let view = plugin.instantiateView(self) {
				return view
			}
		}
		// should we check to see if the view or controller is a gravityelement?
		return UIView()
	}
	
	/// Processes the current node’s attributes, 
	public func processNode() { // rename to just process()? this is public-facing and we're already a node, plus we already have a plugin method called processNode
		if attributeName == "contents" {
			return // don't process contents nodes as they are handled specially
		}
		
//		document.processing = true // do we need this still?
		self.changed = !processed // default changed to true if we have never processed this node, otherwise reset it to false
		self.processed = true // avoid processing twice (when should we reset this?)
		
		computedAttributes = [String: GravityNode]() // reset computed attributes
		self.valueProcessed = false
		
		_view = _view ?? instantiateView() // this lets plugins have a chance to see every view node, in some capacity
		if let view = _view {
			view.gravityNode = self // this is now strong (ok?)

			// FIXME: should we do this at all? if so it should be only if the node has changed and needs processing
			
//			if let superview = view.superview {
//				view.removeFromSuperview()
//				assert(view.constraints.count == 0) // verify
//				superview.addSubview(view) // FIXME: this might fuck up zIndex (where should we process that?)
//			}
			
			if let childDocument = childDocument { // childDocument is set in the pre-processing phase
				childDocument.node._view = view // perhaps there is a better place for this
				childDocument.node.processNode() // recurse
			}
		}
		
		let sortedAttributes = effectiveAttributes.keys.sort { (attributeName, _) -> Bool in // do we need to iterate effective? shouldn't this be == attributes here?
//			NSLog("Compare: \($0) with \($1)")
//			let attributeName: String = $0
			return attributeName.containsString(":") // this should sort attributes with a : to the front
		}
		
		// MARK: Process attributes
		
		for attributeName in sortedAttributes {
			if let attribute = effectiveAttributes[attributeName] {
				// FIXME: this won't work for updates as we are not presently clearing processed ever
				// we might use a document flag, or another flag here
				if !attribute.processed {
					attribute.processNode()
					changed = changed || attribute.changed
				}
			}
		}
		
		// FIXME: we need to default changed to true on the first time processing
		
		if !changed && !isAttributeNode {
			NSLog("Node \(nodeName) is unchanged. Skipping further processing.")
			return // no need to process further (note: attribute nodes will always be processed since they establish a value)
		}
		
		// MARK: Determine applicable plugins
		
		// this could really be cleaned up
		var applicablePlugins = Set<GravityPlugin>()
		var effectiveKeys = Set(effectiveAttributes.keys) // we *do* want to check effective here, because there could have been some added above
		
		if isAttributeNode {
//			effectiveKeys = Set([attributeName!])
			effectiveKeys.unionInPlace([attributeName!])
		}
		
		for attribute in effectiveKeys {
			applicablePlugins.unionInPlace(document.pluginsForAttribute(attribute))
		}
		
		// don't do this if the attribute is handled by a gravityelement
		if applicablePlugins.isEmpty && (!isAttributeNode || (parentNode?._view as? GravityElement)?.recognizedAttributes?.contains(attributeName!) != true) { // verify holy shit
			NSLog("Processing unrecognized node: \(self)")
			applicablePlugins = Set(document.genericPlugins())
		}
		
		var handled = false
		
		// TODO: make sure that GEs are given a chance to process values, and also that if a plugin or a GE recognizes an attribute but returns .NotHandled for it then that should still go to the default handler before processNode. (which means we might want to do it up a few lines)
		
		for plugin in document.plugins { // this ensures this is done in plugin order (Set is unordered)
			if !applicablePlugins.contains(plugin) {
				continue
			}
			
			if isAttributeNode { // we might want to improve this condition; what about view attribute values like templates? actually i think we want to treat those like value nodes anyway
				handled = plugin.processValue(self) == .Handled // attribute node
				if handled {
					break
				}
			} else {
				plugin.processNode(self)// == .Handled // element node
			}
			
			if handled {
				NSLog("\(nodeName) handled by plugin \(plugin.dynamicType).")
				break
			}
		}
		
		if !handled {
			NSLog("Warning: Node <\(nodeName)> was not explicitly handled.")
		}
		
		if viewIsInstantiated { // is this good?
			if let gravityElement = view as? GravityElement ?? controller as? GravityElement {
				gravityElement.processElement(self)
				if gravityElement.processContents != nil {
					gravityElement.processContents?(self)
					return //view // handled
				}
			}
		}
		
		for plugin in document.plugins { // this has nothing to do with attributes
			// only if we have contents?
			if plugin.processContents(self) == .Handled {
				return
			}
		}
	}
	
//	internal func processAttributeValue(attribute: String) -> GravityNode? {
//		// FIXME: make sure this works for node values
//		guard let rawValue = attributes[attribute] else { // do we need rawValue if this can be an object now?
//			return nil
//		}
//		
//		var value: GravityNode = rawValue
////		var stringValue: String = rawValue ?? "\(value)" // if value is a node, this will represent the xml of the node
////		var handled = false
//		
//		for plugin in value.document.plugins { // ooh, a *value*-based plugin hook!
//			// can we rename this to transformValue? or just processValue?
//			plugin.preprocessValue(value: value)
//		}
		
		
		// 1. First-chance handling by plugins
//		for plugin in document.plugins {
//			var newValue = value // value must be a String here
//			// TODO: make sure the order here is correct!!
//			if plugin.preprocessAttribute(self, attribute: attribute, value: &newValue) == .Handled {
//				handled = true
//			}
//			value = newValue // do this regardless of whether the call returns Handled or not
//		}
//		
//		if handled {
//			return
//		}
		
		// 3. GravityElement handling
//		if let gravityElement = view as? GravityElement {
//			if gravityElement.processAttribute(self, attribute: attribute, value: value) == .Handled {
//				return
//			}
//		}
		
//		var finalValue: AnyObject = value
//		for plugin in value.document.plugins { // experimental second value-based hook!!
//			if plugin.postprocessValue(self, attribute: attribute, input: value, output: &finalValue) == .Handled {
//				break
//			}
//		}
		
		// 4. Post-process handling by plugins
		// this is really just a last-chance handler, we should rename it; postprocess is stupid
		
//		for plugin in document.plugins {
//			if plugin.postprocessAttribute(self, attribute: attribute, value: finalValue) == .Handled {
//				return
//			}
//		}
//	}
	
	public func setAttribute(attribute: String, value: GravityNode) {
//		let classParts = attribute.componentsSeparatedByString(":") // is this safe? should we split on "." first to handle parent.class:child?
//		let classPart = classParts.count > 1 ? classParts.last : nil
//		let attributePart = classParts.last!
		let attributeParts = attribute.componentsSeparatedByString(".")
		
		value.document = value.document ?? document // should we allow specifying document when creating a value node?
		value.nodeName = "\(self.nodeName).\(attribute)" // needed?
		value.parentNode = self
		
		if attributeParts.count > 1 {
			if let subDoc = self.childDocument {
				let identifier = attributeParts.first!
				let remainder = attributeParts.suffixFrom(1).joinWithSeparator(".")
//				if classPart != nil {
//					remainder = "\(classPart!):\(remainder)"
//				}
				if let child = subDoc.ids[identifier] {
					child.setAttribute(remainder, value: value)
				} else {
					NSLog("Error: Identifier ‘\(identifier)’ not found in document \(subDoc.name).")
				}
			} else {
				NSLog("Error: Cannot use dot notation for an attribute on a node that is not an externalized gravity file.")
			}
		} else {
			// FIXME: document.processing is not true for subdocuments
			if processed {
				// TODO: store this in a temporary array that we can use to compute changes, or back up the previous array somewhere first
				computedAttributes[attribute] = value
				// FIXME: this needs to do the same processing that unrecognized attributes go through
				value.processNode() // experimental
			} else {
				attributes[attribute] = value
			}
		}
	}
	
//	public func setAttribute(attribute: String, stringValue: String) {
//		setAttribute(attribute, value: GravityNode(document: document, parentNode: self, attribute: attribute, stringValue: stringValue))
//	}
	
	internal func connectController(controller: UIViewController) {
		if viewIsInstantiated {
			(view as? GravityElement)?.connectController?(self, controller: controller)
		}
		for childNode in childNodes {
			childNode.connectController(controller)
		}
	}
	
//	internal func copy(document: GravityDocument, parentNode: GravityNode? = nil) -> GravityNode {
//		// copying kinda sucks, but it's safer for now; downside is these have to be updated when the class's properties change
//		
//		let copy = GravityNode()
//		copy.document = document
//		copy.parentNode = parentNode
//		copy.nodeName = self.nodeName
//		copy._controller = self._controller // should we do this later?
//		copy.rawStringValue = self.rawStringValue
//		
//		for (key, value) in attributes {
//			copy.attributes[key] = value.copy(document, parentNode: copy)
//		}
//		
//		for childNode in childNodes {
//			copy.childNodes.append(childNode.copy(document, parentNode: copy))
//		}
//		
//		return copy
//	}
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
