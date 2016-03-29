//
//  GravityNode.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-11.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@objc
public enum GravityState: Int, Comparable {
	case Loading = 0
	case Loaded
	case Resolved
	case Processed
}
// it feels weird to me that i need to do this, but here it is:
public func < (lhs: GravityState, rhs: GravityState) -> Bool {
	return lhs.rawValue < rhs.rawValue
}

// TODO: implement a whole shit-ton of literal convertibles!! yeah!!
@available(iOS 9.0, *)
// TODO: split these protocols into extensions to follow Swift conventions
@objc
public class GravityNode: NSObject {
	public var state: GravityState = .Loading
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
//	public var isViewCycle {
//		get {
//			return NSThread.isMainThread()
//		}
//	}
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed tree; this must be the FULL depth of the tree, including all embedded subdocuments, and should happen in the preprocess phase.
	public var attributes = [String : GravityNode]() // the static dom attributes
	private var dynamicAttributes = [String : GravityNode]() // the dynamic dom attributes
	public var constraints = [String : NSLayoutConstraint]() // store constraints here based on their attribute name (width, minHeight, etc.) -- we should move this to a plugin, but only if we can put all or most of the constraint registering in there as well
	internal lazy var staticNodes = [GravityNode]() // make private if possible
	internal lazy var dynamicNodes = [GravityNode]()
//	private var dynamicChildNodes = [GravityNode]() // the child nodes of the dynamic dom (actually do we need this or should we just set a "contents" attribute during the dom cycle?)
	public var childNodes: [GravityNode] {
		get {
			return loaded ? contents.dynamicNodes : staticNodes // contents already returns self if it's an attribute node
		}
	}
//	private var contents: GravityNode!
	public var childDocument: GravityDocument? // if this node represents an external document
	/// The textual value of the node as a `String`, if the node is a text node (e.g. an inline attribute). Returns `nil` if the current node does not have a textual value.
	private var _contents: GravityNode! // only used by content nodes (aka element nodes)
	private var contents: GravityNode { // should this be public? maybe not
		get {
			if self.isAttributeNode {
				return self // no recursion allowed beyond this point ;)
			}
			// should this always return _contents during the load cycle? will it be accessed during the load cycle??
			return processed ? self["contents"]! : _contents
		}
	}
	
	public var staticStringValue: String?
	public var include = true // this only has an effect on the dynamic dom and allows nodes to be removed from the dom during processing
	
	// MARK: Privates
	// FIXME: we really need a better way to organize these
	internal var loaded = false // the node has been statically processed
	private var processed = false // the node has hit the DOM process stage once; this will probably need to change somehow to support updates
	private var viewProcessed = false // the view has been processed (again this will probably change when i figure out how best to represent the state of a node--state machine?)
	private var changed = false
	
	// TODO: set an internal flag when these are allowed to be set and fail if attempted at the wrong time
	
	private var _stringValue: String?
	public var stringValue: String? {
		get {
//			processValue()
			return loaded ? _stringValue : staticStringValue
		}
		set(value) {
			if loaded {
				_stringValue = value
			} else {
				staticStringValue = value
			}
		}
	}
	
	private var _objectValue: AnyObject?
	public var objectValue: AnyObject? {
		get {
//			processValue()
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
//			processValue()
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
//			processValue()
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
//			processValue()
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
			return loaded ? dynamicAttributes[attribute] : attributes[attribute]
		}
		set(value) {
			if value != nil {
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
	internal var _view: UIView? // should this actually be weak?? i would think that we would hang onto the view while we are using it, and if we lose our reference to that, we can always rebuild it again from the gravity on demand (may take some refactoring to keep _view alive while we need it)
	public var view: UIView {
		get {
			if _view == nil {
				if processed {
					processView()
				} else {
					process()
				}
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
		self.staticStringValue = stringValue
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
		if !self.isAttributeNode {
			_contents = GravityNode(document: document, parentNode: self, attributeName: "contents")
		}
	}
	
	/// Creates and returns a new document containing a copy of the remaining tree in the current node's document. This allows you to instantiate arbitrary sub-trees of a layout as new instances of their own layouts.
	public func instantiate(model: AnyObject? = nil) -> GravityDocument {
		let instance = GravityDocument()
		instance.parentNode = self // or self.parentNode??
		instance.xml = self.serialize() // this is probably not super efficient, but is reliable
		instance.model = model ?? instance.model
//		instance.node = self.copy(instance)
//		instance.preprocess() // TODO: verify this loads embedded documents
		return instance
	}
	
	// PG
	public func appendNode(node: GravityNode) {
		if !loaded { // in this case !processed means we're in the load cycle (building the static dom)
			staticNodes.append(node)
		} else {
			contents.dynamicNodes.append(node)
			node.process() // ok?? if we're adding a node during the dom cycle, it should be processed (if it is not already)
		}
		node.parentNode = self // is this safe?? should it actually be contents?
	}
	
	// TODO: we should rename to isViewLoaded to match UIViewController
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
	// we should extend it with options to support static vs dynamic dom
	// note: debugMode does not return valid xml, but includes memory addresses for all instantiated nodes for easier debugging
	// we should also add an option to sort attribute names, off by default for performance
	public func serialize(debugMode: Bool = false, indent: String = "  ") -> String {
		var attributeStrings = [String]()
		var attributeNodes = [GravityNode]()
		for (key, value) in attributes { // static
			if let stringValue = value.staticStringValue {
				// FIXME: add proper escaping for XML attribute value
				let escapedValue = stringValue.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(escapedValue)\"")
			} else {
				attributeNodes.append(value)
			}
		}
		
		let address = debugMode && self.viewIsInstantiated ? "(\(unsafeAddressOf(self)))" : "" // should we return the address of the view or the node?
		let childNodes = staticNodes + attributeNodes // verify
		
		if childNodes.count > 0 {
			// indent:
			var childNodeStrings = childNodes.map { // static
				return $0.serialize(debugMode, indent: indent).componentsSeparatedByString("\n").map {
					return "\(indent)\($0)"
				}.joinWithSeparator("\n")
			}
			
			if let stringValue = staticStringValue {
				childNodeStrings.append(stringValue)
			}
			
			return "<\(nodeName)\(address)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
		} else if staticStringValue != nil {
			return "<\(nodeName)\(address)>\(staticStringValue!)</\(nodeName)>"
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
	
	public func process() {
		process(nil)
	}
	
	/// Processes the current node’s attributes, 
	private func process(skipNode: GravityNode?) { // skipNode will work fine so long as there is at most one child that can already have been processed; if this changes we'll need to improve this
//		if attributeName == "contents" {
//			return // don't process contents nodes as they are handled specially
//		}
		let initialInclude = include
		let time1 = NSDate()
		processDOM()
		let time2 = NSDate()
		
		if let parentNode = parentNode where include != initialInclude {
			parentNode.process(self)
		} else {
			print("⏱ DOM Cycle time:  \(Int(round(time2.timeIntervalSinceDate(time1) * 1000))) ms")
//			NSLog("process() changed: \(changed)")
			// eventually this will only happen if it's changed
			processView()
			let time3 = NSDate()
			print("⏱ View Cycle time: \(Int(round(time3.timeIntervalSinceDate(time2) * 1000))) ms")
		}
	}
	
	// II. The DOM Cycle
	private func processDOM() {
		if processed {
			return // do we want this?
		}
		
		loaded = true // i'm not sure where the best place for this is, but by this point we are definitely loaded (i think there are some issues with attribute nodes)
		// copy the static dom into the dynamic dom; this is experimental
		dynamicAttributes = attributes//[String: GravityNode]()
		// FIXME: this is breaking with embedded content (dynamic content is explicitly set before this point and this is clearing it)
		if isAttributeNode && attributeName != "contents" {
			dynamicNodes = staticNodes
		}
		if !isAttributeNode {
			// TODO: activate this:
//			_view = _view ?? instantiateView() // good here? make sure embedded templates do NOT make it to the dom cycle (they should be treated as document values)
			
			// TODO: add precedence to recursive nodes (i.e. nodes that actually contain children) to account for failed template references and to fall back on valid contents
			if dynamicAttributes["contents"] == nil {
				contents.dynamicNodes = staticNodes // the static (direct) content (maybe this should happen elsewhere?)
				dynamicAttributes["contents"] = contents
			} else {
				NSLog("existing contents found!")
			}
		}
		_stringValue = staticStringValue // need better naming convention here
		// should we also reset the dynamic values of the node here? man i'm really thinking we need to split the classes...
		
		include = true // included until proven excluded
		
		changed = !processed // default changed to true if we have never processed this node, otherwise reset it to false
		processed = true // avoid processing twice (when should we reset this?)
		
		if contents !== self {
			contents.processDOM()
		}
		// TODO: verify that contents attributes override physical contents
		
		// process *direct* contents first (the *actual* contents supplied to handleContents will depend on the "contents" attribute)
		if isAttributeNode { // exp: only do this for attribute nodes (forces contents to be processed as attributes)
			for childNode in contents.dynamicNodes { // which means this will === self.dynamicNodes
	//			if !contents.dynamicNodes.contains(childNode) { // is this possible with conditionals?
	//				continue
	//			}
	//			if childNode === skipNode // TODO: finish this
				childNode.processDOM()
				if !childNode.include {
					// add the child node to the dynamic dom of the direct contents node
	//				dynamicNodes.append(childNode)
					contents.dynamicNodes = contents.dynamicNodes.filter { $0 != childNode }
				}
			}
		}
		
		for (attribute, value) in dynamicAttributes {
			// we might also iterate over keys and look it up each time (seems simpler)
			if dynamicAttributes[attribute] !== value {
				assert(dynamicAttributes[attribute]?.processed == true)
				continue // make sure the attribute is still the same (it may have been overwritten; e.g. by a conditional)
				// we might also implement this by just updating the current value to dynamicAttributes[attribute]; if it is already processed it will be skipped
			}
			if !value.processed {
				value.processDOM()
				changed = changed || value.changed
			}
			// is it possible for a value to be already processed and include == false? yes i think so
			if !value.include {
				dynamicAttributes.removeValueForKey(attribute)
			}
		}
		
//		var include = true // this might need to be an instance variable, and it may need to be tracked by the parent, not us
		for plugin in document.plugins {
			if self.isAttributeNode {
				plugin.processValue(self)
			} else {
				plugin.processNode(self) // do we actually need this? weirdly nothing is using it
			}
			
			if !include {
				return // no point doing any further processing as this entire branch is excluded from the dynamic dom
			}
		}
		
		// this is presently after contents processing so child documents can include their origin's contents
		if let childDocument = childDocument { // childDocument is set in the pre-processing phase
			childDocument.node.processDOM()
		}
	}
	
	// III. The View Cycle
	private func processView() {
		if viewProcessed {
			return
		}
		viewProcessed = true
		
		// TODO: move view instantiation to the dom cycle
		_view = _view ?? instantiateView() // this lets plugins have a chance to see every view node, in some capacity (won't blow away existing view instances)
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
				childDocument.node.processView() // recurse
			}
			
			// set up the deterministic defaults for the new node; this ensures that a node's state will always be deterministic even when disabling nodes
//			if firstViewCycle {
			// we now actually want to do this every time regardless; we can't just process single attribute changes because we can't know what effect a scoped attribute higher-up might have on other nodes in the document; it may affect their defaults
				for plugin in document.plugins {
					plugin.handleAttribute(self, attribute: nil, value: nil)
				}
//			}
		}
		
		
		// TODO: make sure that GEs are given a chance to process values, and also that if a plugin or a GE recognizes an attribute but returns .NotHandled for it then that should still go to the default handler before processNode. (which means we might want to do it up a few lines)
		
		
		// use the dynamic dom for this!
		for (attribute, value) in dynamicAttributes {
			if attribute == "contents" {
				continue // we don't want to handle "contents" attributes like other attributes as it has special meaning and no plugin/ge will handle it anyway
			}
			var handled = false
			for plugin in document.plugins { // must be done in plugin order
				handled = plugin.handleAttribute(self, attribute: attribute, value: value) == .Handled
				if handled {
					NSLog("\(nodeName) handled by plugin \(plugin.dynamicType).")
					break
				}
			}
			
			if !handled {
				NSLog("Warning: Node <\(value.nodeName)> was not explicitly handled.")
			}
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
		value.parentNode = self // won't need this if we unify with appendNode()
		
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
			if loaded {
				// TODO: store this in a temporary array that we can use to compute changes, or back up the previous array somewhere first
				dynamicAttributes[attribute] = value
				// FIXME: this needs to do the same processing that unrecognized attributes go through
				
				// TODO: this should be done in one place by appendNode and it should only process if the node is not already processed (for the given wave)
				if !value.processed {
					value.process() // experimental
				}
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
		for childNode in childNodes { // is dynamic right? i assume we will be working with views here
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
	
	// this allows us to reference node attributes using key path notation, however this implementation has the unfortunate side effect of giving precedence to objective properties on the GravityNode class over attributes of the same name
	public override func valueForUndefinedKey(key: String) -> AnyObject? {
		return self[key]
	}
}

@available(iOS 9.0, *)
extension GravityNode: SequenceType {
	public func generate() -> AnyGenerator<GravityNode> {
		var childGenerator = childNodes.generate() // static or dynamic?? switch on processed?
		var subGenerator : AnyGenerator<GravityNode>?
		var returnedSelf = false

		return AnyGenerator {
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
