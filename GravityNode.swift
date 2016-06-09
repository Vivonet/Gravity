//
//  GravityNode.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-11.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

//@objc
//public enum GravityState: Int, Comparable {
//	/// The first and initial state of a node. The static dom is being constructed by means of an XML file or programmatic Gravity.
//	case Load = 0
//	/// The node’s static dom is set up, but the state of the dynamic dom is not valid and still needs to be resolved.
////	case Loaded
//	/// The dynamic dom is being constructed.
//	case Resolve
//	/// The dynamic dom is valid, but the changes have not yet been processed.
////	case Resolved
//	/// The view hierarchy is being updated to reflect the state of the dynamic dom.
//	case Process
//	/// The last (though not necessarily final) state. The view hierarchy has been updated to the state of the dynamic dom.
//	case Complete // do we need this?
//}
//// it feels weird to me that i need to do this, but here it is:
//public func < (lhs: GravityState, rhs: GravityState) -> Bool {
//	return lhs.rawValue < rhs.rawValue
//}

// TODO: implement a whole shit-ton of literal convertibles!! yeah!!
@available(iOS 9.0, *)
// TODO: split these protocols into extensions to follow Swift conventions
@objc
public class GravityNode: NSObject, BooleanLiteralConvertible {
	// we might want to rename this NodeValue or something now, considering the latest design
	internal struct NodeValue: Equatable {
//		var token: Int = -1 // the token (i.e. timeframe) this state represents
		var node: GravityNode! = nil // it doesn't make sense for this to be weak. if we are storing this state somewhere, there's no reason to allow the parent node to disappear
//		weak var parentNode: GravityNode? = nil
		// TODO: it's stupid to split this up in state i think; get rid of attributeName in here and just have a flag (if that even)
		// i'm not sure nodeName should be part of state anymore
//		var nodeName: String? = nil {
//			didSet {
//				if nodeName?.isEmpty == false {
//					attributeName = nil
//				}
//			}
//		}
//		var attributeName: String? = nil {
//			didSet {
//				if attributeName?.isEmpty == false {
//					nodeName = nil
//				}
//			}
//		}

		/// This field is dual-purpose depending on the cycle. In the DOM cycle it represents a value that needs to be re-evaluated. It does not necessarily mean it has changed (though it's likely). In the view cycle, however, it represents a definite change, which we use to know which attributes need to be view processed. So it's analogous, but note the above distinctions.
//		var changed = false // set to true to invalidate the state (when a dependency changes) in the dom cycle
		
//		var attributes = [String : GravityNode]() // this now needs to support optional values so the dynamic state can cache scoped attribute results, including nils--actually scoped attributes should be cached elsewhere
//		var cachedAttributes = [String : GravityNode?]()
//		var dependencies = [String : [(GravityNode, String)]]() // should this be in state?
//		var childNodes = [GravityNode]()
		var stringValue: String? = nil
		
		// dynamic only (should we subclass?)
		// perhaps if we set one of these on a static node we could convert it into a stringValue
		var objectValue: AnyObject? = nil
		var boolValue: Bool? = nil
		var intValue: Int? = nil
		var floatValue: Float? = nil
		
		init(node: GravityNode) {
			self.node = node
		}
		
		// == implemented at bottom
	}

	// MARK: Privates (move these to the top)
	// FIXME: we really need a better way to organize these
	/// The node is in the loading stage. You can set this value to `true` to explicitly put a node into an editable state. Changes made to the node while in this state will be captured in the static DOM and will be reflected in future updates.
	public var loading = true // we should perhaps rename this back to "processing" since it can be used for both dom and view cycles; basically this tells us which dom to affect (loading => static dom, not loading => dynamic dom)
//	internal var processed = false // the node has hit the DOM process stage once; this will probably need to change somehow to support updates
//	private var viewProcessed = false // the view has been processed (again this will probably change when i figure out how best to represent the state of a node--state machine?)
	private var changeToken: Int = -1
	private var processToken: Int = -1
	private var viewProcessedToken: Int = -1
	internal var processed: Bool {
		get {
			return processToken == Gravity.currentToken
		}
	}
	internal var unprocessed: Bool { // the nomenclature here is confusing; we should use either processed or unprocessed, not both
		get {
			return processToken == -1
		}
	}
	internal var changed: Bool {
		get {
			return changeToken == Gravity.currentToken
		}
	}
	
	var include = true
	
	public var attributes = [String : GravityNode]() { // the node's static attributes (can contain conditionals)
		didSet {
			// TODO: handle changes made to the static attributes array
		}
	}
	private var dynamicAttributes = [String : GravityNode]() // the current token's resolution and evaluation of local attributes (conditionals have been resolved)
//	private var scopedAttributes = [String : GravityNode?]() // the resolution of inherited scoped attributes
	
	// TODO: one or both of these should store weak references (how do we do that?)
//	private lazy var dependants = Set<GravityNode>() // experimental
//	private lazy var dependencies = Set<GravityNode>() // or [GravityNode]
	private var dependencies = [String : [(GravityNode, String)]]() // it's a bit complicated to use tuples; maybe refactor this
	private var dependants = [String : [(GravityNode, String)]]()
	private lazy var viewState = [String : (NodeValue?, AttributeScope)]() // viewState records the state (value) of *all* perceived attributes depended-on by the node in the view cycle
	private lazy var viewDependencies = [String : Set<String>]() // this records which other local attributes a given view attribute depends on (use empty string to represent the generic node handler)
	
	private var childrenProcessed = false // temp until we figure out contents change
	
//	private var snapshot: NodeValue? = nil // represents the state of the node when it was last view-processed (make non-optional?)
//	private var inheritedAttributes = [String : NodeValue]() // record the value (dynamic state) of each attribute accessed during procesing 

//	public var state: GravityState = .Load // do we want to add a didSet and handle state change initialization/reset here?
	public var document: GravityDocument! // should this be weak?
	public var parentNode: GravityNode? //{
//		get {
//			return state.parentNode
//		}
//		set(value) {
//			state.parentNode = value
//		}
//	}
	private var _nodeName: String? = nil
	public var nodeName: String { // should we compute this automatically if empty?
		get {
			if attributeName != nil {
				assert(parentNode != nil)
				return "\(parentNode!.nodeName).\(attributeName!)"
			} else {
				return _nodeName!
			}
		}
	}
	
	// these are slightly weird because they need to refence `self` and are therefore loaded in lazy closures:
//	internal lazy var staticState: NodeValue = { NodeValue(node: self) }()
//	internal lazy var dynamicState: NodeValue = { NodeValue(node: self) }()
//	internal lazy var viewState: NodeValue = { NodeValue(node: self) }()
	
	internal var childrenLoaded = false
	internal var isCondition = false // a condition is an attribute that starts with : and does not represent a configuration that must be handled, but rather is depended on by other attributes (it essentially means ignore unless explicitly requested)
	private var currentAttribute: String? // represents the currently processing attribute for this node
	
//	private var state: NodeValue = NodeValue()
	internal lazy var state: NodeValue = { NodeValue(node: self) }()
//	internal var state: NodeValue {
//		get {
////			return loading ? staticState : dynamicState
//			
//			// experimental:
//			if Gravity.currentNode != nil {
//				return dynamicState
//			} else {
//				return staticState
//			}
//		}
//		set(value) {
//			// we can actually trap all changes to state here, if we need to
//			if loading {
//				staticState = value
//			} else {
//				dynamicState = value
//			}
//		}
//	}
	
	// FIXME: this needs to change; since attributes can actually be moved around, we should instead dynamically compute the nodeName based on the parent node rather than stripping the attribute name out of a hard-coded parent string.
	// nodeName itself should be computed with a private optional backing store
	// a node must therefore have either a node name *or* an attribut ename
	// OR, we could consider the attribute name the node name, and have a boolean indicate whether the node should be treated as a value node or not.
	/// Returns the name of the attribute this node is defining, if it is an attribute node, or `nil` otherwise.
	public var attributeName: String? //{
//		get {
//			return state.attributeName
////			if nodeName.containsString(".") {
////				return nodeName.componentsSeparatedByString(".").last
////			} else { // not an attribute node
////				return nil
////			}
//		}
//	}
	public var baseAttributeName: String? {
		get {
			// is it possible for attributeName to start with : or should that be abstracted by this point?
			guard var baseAttribute = attributeName else {
				return nil
			}
			if baseAttribute.hasPrefix(":") == true {
				baseAttribute = baseAttribute.substringFromIndex(baseAttribute.startIndex.advancedBy(1))
			}
			
			return baseAttribute.componentsSeparatedByString(":").first
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
	
	// The number of nodes deep this node is in the immediate document.
	
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
//	public var attributes = [String : GravityNode]() // the static dom attributes
//	private var dynamicAttributes = [String : GravityNode]() // the dynamic dom attributes
	public var constraints = [String : NSLayoutConstraint]() // store constraints here based on their attribute name (width, minHeight, etc.) -- we should move this to Layout, the problem is it is node-based, not document based. do we have a solution for node-based plugin storage?
//	internal lazy var staticNodes = [GravityNode]() // make private if possible
//	internal lazy var dynamicNodes = [GravityNode]()
	// these keep track of the state of the dom as of the last view-process (we may also want to do this for values)
//	internal lazy var previousDynamicNodes = [GravityNode]()
//	internal lazy var previousDynamicAttributes = [String : GravityNode]()
//	private var dynamicChildNodes = [GravityNode]() // the child nodes of the dynamic dom (actually do we need this or should we just set a "contents" attribute during the dom cycle?)
	private lazy var _childNodes = [GravityNode]()
	public var childNodes: [GravityNode] {
		get {
			// is it considered a dependency to access a node's child nodes, or will we just be a dependency on the eventual child?
			// unlike scoped attributes, we can't really depend on children can we? what about contents?
//			return loading ? staticNodes : contents.dynamicNodes
//			if loading {
//				return contents.staticState.childNodes
//			}
			
			if contents === self {
				return _childNodes
			} else {
				return contents.childNodes
			}
//			return loaded ? contents.dynamicNodes : staticNodes // contents already returns self if it's an attribute node
		}
		set(value) {
			if contents === self {
				_childNodes = value
			} else {
				contents.childNodes = value
			}
		}
	}
//	private var contents: GravityNode!
	public var childDocument: GravityDocument? // if this node represents an external document
	/// The textual value of the node as a `String`, if the node is a text node (e.g. an inline attribute). Returns `nil` if the current node does not have a textual value.
	internal var contentsNode: GravityNode! // why don't we just *set* the contentsNode to self?? duh, why did it take me so long to think of that
	internal var contents: GravityNode { // should this be public? maybe not
		get {
			if self.isAttributeNode {
				return self // no recursion allowed beyond this point ;) attribute nodes hold their contents directly (and should not be dom-processed)
			}
			return contentsNode
			
			// not sure what to do here, is this still right:
//			return loading ? contentsNode : self["contents"]
		}
	}
	
//	public var staticStringValue: String?
//	private var _include = true
//	public var include: Bool { // this only has an effect on the dynamic dom and allows nodes to be removed from the dom during processing
//		get {
//			return state.include
//		}
//		set(value) {
//			if value != state.include {
//				changeToken = Gravity.currentToken
//			}
//			state.include = value
//		}
//	}
	
	// make public?
	internal var gravityElement: GravityElement? {
		get {
			return _view as? GravityElement ?? controller as? GravityElement
		}
	}
	
	// TODO: set an internal flag when these are allowed to be set and fail if attempted at the wrong time
	
//	private var _stringValue: String?
	public var stringValue: String? {
		get {
//			Gravity.currentNode?.addDependency(self)
//			return loading ? staticStringValue : _stringValue
			return state.stringValue
		}
		set(value) {
			// TODO: we need to handle explicit value changes to the static DOM and kick off a DOM cycle
			if !loading && value != state.stringValue { // does it actually even matter if we're not loading?
				changeToken = Gravity.currentToken
			}
			state.stringValue = value
			
			
			
//			if loading {
//				staticStringValue = value
//			} else {
//				if value != _stringValue {
//					changeToken = Gravity.currentToken
//					_stringValue = value
//				}
//			}
		}
	}
	
	// the rest of these only apply to the dynamic dom, so state is not checked (add better validation later)
	
//	private var _objectValue: AnyObject?
	public var objectValue: AnyObject? {
		get {
//			Gravity.currentNode?.addDependency(self)
			return state.objectValue ?? state.stringValue // or nil?? or self?? with transformation this shouldn't happen
		}
		set(value) {
			if !loading && !(value != nil && state.objectValue != nil && state.objectValue!.isEqual(value)) { // TODO: test that isEqual works properly
				changeToken = Gravity.currentToken
			}
//			if !(_objectValue != nil && value != nil && _objectValue! == value!) {
//				changed = true
//			}
			state.objectValue = value // broken!! (wtf)
		}
	}
	
//	private var _boolValue: Bool?
	public var boolValue: Bool? {
		get {
//			Gravity.currentNode?.addDependency(self)
			return state.boolValue ?? (state.stringValue as NSString?)?.boolValue
		}
		set(value) {
			if !loading && value != state.boolValue {
				changeToken = Gravity.currentToken
			}
			state.boolValue = value
		}
	}
	
//	private var _intValue: Int?
	public var intValue: Int? {
		get {
//			Gravity.currentNode?.addDependency(self)
			if state.intValue != nil {
				return state.intValue
			}
			// should we move this up to NodeValue?
			if state.stringValue != nil && state.stringValue!.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "-0123456789.").invertedSet) == nil {
				return (state.stringValue as NSString?)?.integerValue
			} else {
				return nil
			}
		}
		set(value) {
			if !loading && value != state.intValue {
				changeToken = Gravity.currentToken
			}
			state.intValue = value
			state.floatValue = value != nil ? Float(value!) : nil // keep numeric values in sync // this is ugly in swift :( why don't nils propagate?? honestly
			// should we set boolValue here too? for now, no
		}
	}
	
//	private var _floatValue: Float?
	public var floatValue: Float? {
		get {
//			Gravity.currentNode?.addDependency(self)
			if state.floatValue != nil {
				return state.floatValue
			}
			if state.stringValue != nil && state.stringValue!.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "-0123456789.").invertedSet) == nil {
				return (state.stringValue as NSString?)?.floatValue
			} else {
				return nil
			}
		}
		set(value) {
			if !loading && value != state.floatValue {
				changeToken = Gravity.currentToken
			}
			state.floatValue = value
			state.intValue = value != nil ? Int(value!) : nil // keep numeric values in sync
		}
	}
	
	 // MARK: Subscript
	subscript(attribute: String) -> GravityNode? {
		get {
			// should we support dot notation for attributes accessed through subscript? e.g. "titleLabel.text"?
			// ideally yes, since we support it for setting we should also for getting
			
//			Gravity.currentNode?.addDependency(self)
//			if let activeNode = Gravity.currentNode {
//				// double link (figure out how to make this weak)
//				dependants.insert(activeNode)
//				activeNode.dependencies.insert(self)
//			}
//			return loading ? attributes[attribute] : dynamicAttributes[attribute]

			// do we want to record the dependency here?
//			if let currentNode = Gravity.nodeStack.last {
//				currentNode.
//			}
			
			return getAttribute(attribute, scope: .Local)
		}
		set(value) {
			if value != nil {
				setAttribute(attribute, value: value!)
			}
			// TODO: do we want to allow setting an attribute to nil to remove it? or must that be done via .include? do we even need include if we allow this??
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
			if _view == nil { // why is this still here? aren't we instantiating _view right away now? (only if we've been processed once though)
				if processed {
					processView()
				} else {
					process(true) // if we end up here while in the view phase something's wrong
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
		self.stringValue = "\(objectValue)" // ok??
		setup()
	}
	
//	public init(boolValue: Bool) {
//	public typealias BooleanLiteralType = Bool
	required public init(booleanLiteral value: Bool) {
		super.init()
		self.boolValue = value
		self.stringValue = "\(value)"
		setup()
	}
	
	public init(intValue: Int) {
		super.init()
		self.intValue = intValue
		self.stringValue = "\(intValue)"
		setup()
	}
	
	public init(floatValue: Float) {
		super.init()
		self.floatValue = floatValue
		self.stringValue = "\(floatValue)"
		setup()
	}
	
	internal init(document: GravityDocument, parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.document = document
		super.init()
		
		// here or in setup()?
		if let parentNode = parentNode where nodeName.containsString(".") {
//			assert(parentNode != nil)
			// this is actually not true anymore: we can have nodes with dots at the top, but they just aren't attribute nodes
//			guard let parentNode = parentNode else {
//				// apply to parent document? that breaks containment.
//				preconditionFailure("Attribute node found at top of document. Attribute nodes must have a parent.")
//			}
			
			// TODO: allow _ shorthand?
			let parentElementIndex = nodeName.startIndex.advancedBy(parentNode.nodeName.characters.count) // wow Swift, wow. :|
			if nodeName.substringToIndex(parentElementIndex) == parentNode.nodeName && nodeName.characters[parentElementIndex] == "." {
				let attributeName = nodeName.substringFromIndex(parentElementIndex.advancedBy(1))
//				staticState.attributeName = attributeName
				// surprisingly this actually seems to work:
				parentNode.contents.childNodes = parentNode.contents.childNodes.filter { $0 != self }
//					parentNode.staticState.attributes[attributeName] = childNode

				// what if parentNode already has an attribute defined in text notation?
				if parentNode.attributes[attributeName] != nil {
					// actually what we should consider doing is *combine* the definitions; this would allow attributes to have a string value but also be customized with more information (such as animation metadata?)
					preconditionFailure("Illegal redefinition of attribute in element notation.")
				}
				parentNode.setAttribute(attributeName, value: self)
				// we are converting a non-attribute node into an attribute node; we currently have to handle changing its contents manually (this probably indicates we need some tweaks to the design)
//					childNode.staticState.childNodes = childNode.contentsNode.staticState.childNodes
			} else {
				preconditionFailure("Invalid attribute node notation. Element name must start with parent element (expected ‘\(parentNode.nodeName)’).")
			}
			
			// TODO: make sure this works recursively; i.e. we can have multiple levels of attribute nodes affecting each other

		} else {
			_nodeName = nodeName
		}
		
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
		attributeName = attribute
//		_nodeName = "\(parentNode.nodeName).\(attribute)"
		self.parentNode = parentNode
		super.init()
		state.stringValue = stringValue
		setup()
	}
	
	internal init(document: GravityDocument, parentNode: GravityNode, attributeName: String) {
		self.document = document
		self.attributeName = attributeName
//		_nodeName = "\(parentNode.nodeName).\(attributeName)"
		self.parentNode = parentNode
		super.init()
		setup()
	}
	
	/// **Note:** May be called before the node has been added to the DOM.
	private func setup() {
//		self.depth = (parentNode?.depth ?? 0) + 1
//		attributes = staticState.attributes ?? [String: GravityNode]()
		if document != nil && !self.isAttributeNode {
			contentsNode = GravityNode(document: document, parentNode: self, attributeName: "contents")
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
		// note: this doesn't currently differentiate between attribute nodes or not
		if loading { // in this case !processed means we're in the load cycle (building the static dom)
			contents.childNodes.append(node)
		} else {
			preconditionFailure("Can we still append nodes dynamically?")
			contents.childNodes.append(node)
			node.processNode() // ok?? if we're adding a node during the dom cycle, it should be processed (if it is not already)
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
			return attributeName != nil && parentNode != nil // the root node of a document can appear like an attribute node even though it technically isn't since it's an instantiated document
		}
	}
	
	/// Finds and returns the most recent definition of the given attribute. Scoped attributes are inherited.
	///
	/// *Note:* Scoped attributes do not pass through document boundaries (unless they are conditions!)
	public func getAttribute(attribute: String, scope: AttributeScope = .Local) -> GravityNode? {
		precondition(!attribute.containsString(":"), "Explicitly requested attributes must be atomic (no conditions).")
		
//		var baseAttribute = attribute
//		var extendedScope = false
//		if attribute.hasPrefix(":") {
//			extendedScope = true
//			baseAttribute = attribute.substringFromIndex(attribute.startIndex.advancedBy(1))
//		}

		if loading { // maybe we should make cycle a global enum and add .Load
			return attributes[attribute]
		}
		
		var value = dynamicAttributes[attribute]
//		let local = value != nil
		
		if value == nil && scope != .Local { // no locally-defined attribute
			value = parentNode?.getAttribute(attribute, scope: scope)
		}
		
		if value == nil && scope == .Global {
			value = document.parentNode?.getAttribute(attribute, scope: scope)
		}
		
//		if !local && Gravity.currentNode === self {
//			dependencies[baseAttribute] = value?.dynamicState
//		}
		
		registerAsDependency(attribute, value: value, scope: scope)
		
		return value
	}
	
	internal func instantiateView() {
//		var instantiatedView: UIView? = nil
		for plugin in document.plugins {
			_view = plugin.instantiateView(self)
			if _view != nil {
				break
			}
		}
		
		_view = _view ?? UIView()
		
		// initialize the newly created view to the deterministic defaults as provided by each plugin/ge
		let node = attributeName == "contents" ? self.parentNode! : self
		if let gravityElement = gravityElement {
			gravityElement.handleAttribute(node, attribute: nil, value: nil)
		}
		for plugin in document.plugins {
			plugin.handleAttribute(node, attribute: nil, value: nil)
		}
	}
	
	/// Kicks off a process cycle and queues a view cycle if necessary.
	public func process(synchronous: Bool = false) {
//		var synchronous = synchronous // swift is fucking retarded sometimes
		assert(!Gravity.processing)
//		Gravity.processing = true
//		if attributeName == "contents" {
//			return // don't process contents nodes as they are handled specially
//		}
		
		// we want to start processing on the closest content ancestor
//		var target = self
//		while target.isAttributeNode {
//			target = target.parentNode!
//		}
//		changed = true // by calling process() we are telling this node that it has changed; it is essentially invalidating it
//		let initialInclude = include
		let time1 = NSDate()
		// TODO: schedule this on a bg thread
		// this would also be a good place to reset any thread-local storage
//		Gravity.currentNode = nil
		assert(Gravity.domDependence.count == 0, "Node stack should be empty here!")
//		Gravity.changedNodes.removeAll()
		Gravity.currentToken += 1
//		Gravity.processedNodes = nil

//		assert(processToken == -1)
		// presumably this function is only called once during the initial setup?
//		dynamicState = staticState
//		dynamicState.attributes = []()

		let synchronous = true // temp until we implement async updates

		if synchronous {
			Gravity.syncDOMCycle = true
		}
		
		
		processNode() // this should recursively process the effects of the change as necessary
		
		
		Gravity.syncDOMCycle = false
		
		let time2 = NSDate()
		
//		if let parentNode = parentNode where include != initialInclude {
//			parentNode.process(self)
//		} else {
		print("⏱ DOM Cycle time:  \(Int(round(time2.timeIntervalSinceDate(time1) * 1000))) ms")
////			NSLog("process() changed: \(changed)")
//			// eventually this will only happen if it's changed
//			processView()
//		}
		
		// TODO: change this to iterate the tree in exactly the same order as when it was built, and simply ignore nodes that aren't in the set
		// we'll probably have to flip it so the function itself does the recursion still but doesn't do anything unless it's in the change set
//		for node in Gravity.changedNodes {
//			node.processView() // is this all we need??
//		}
		
		// TODO: wrap this in an async_dispatch so that multiple changes enacted on a single run loop iteration collapse into a single view update
		// find the top-most document
		if synchronous {
			if isAttributeNode {
				parentNode!.processView() // this is not presently recursive; technically it should do the while parentNode thingy
			} else {
				processView() // and kick it off
			}
			
			let time3 = NSDate()
			print("⏱ View Cycle time: \(Int(round(time3.timeIntervalSinceDate(time2) * 1000))) ms")
		} else {
			// TODO: implement
//			Gravity.pendingDocuments.insert(document)
		}
//		Gravity.processing = false
	}
	
	
	// II. The DOM Cycle
	
	// we could rename this processNode() since it's technically not just the value but rather the recursive entry point for the node
	private func processNode() {
		assert(processToken != Gravity.currentToken)
		// presumably this function is only called once during the initial setup?
//		dynamicState = staticState
//		dynamicState.attributes = []()
//		dynamicAttributes

		processToken = Gravity.currentToken

		if _view == nil && !isAttributeNode {
			instantiateView() // this lets plugins have a chance to see every view node, in some capacity (won't blow away existing view instances)
		}
//		assert(_view != nil)
		_view?.gravityNode = self // this is now strong (should this be in instantiateView?)
		
		// compile base attributes
		var baseAttributes = Set<String>()
		for attribute in attributes.keys {
			let baseAttribute = attribute.componentsSeparatedByString(":").first!
			
			if baseAttribute != "" {
				baseAttributes.insert(baseAttribute)
			}
		}
		
		for baseAttribute in baseAttributes {
			// should we check if the attribute has already been processed here?
			processAttribute(baseAttribute)
		}
		
		for plugin in document.plugins {
			plugin.processValue(self)
			
			if !include {
				break
			}
		}
		
		for childNode in childNodes {
			if childNode.unprocessed {
				childNode.processNode()
			}
		}
		
		// this is presently after contents processing so child documents can include their origin's contents
		if let childDocument = childDocument {
			if childDocument.node.unprocessed {
				childDocument.node.processNode() // should this be here or earlier?
			}
		}
	}
	
	private func processAttribute(attribute: String) {
		precondition(!attribute.containsString(":"), "Only base attributes should be passed to `processAttribute`, no qualifiers or conditionals.")
		
//		assert(dynamicAttributes[attribute]?.state.token != Gravity.currentToken, "Attribute already processed this token.")
		
		// this is used to follow the path of change in the view cycle, it does NOT anymore represent a completely processed node (we could rename to touchToken)
		processToken = Gravity.currentToken
		
		var value: GravityNode? = nil
		// is this the right way to get previous state?
		let previousValue = dynamicAttributes[attribute]?.state
		
		// or should this be in an assert and it is the caller's responsibility?
//		if previousValue?.token == Gravity.currentToken {
//			return // the attribute has already been processed for this token
//		}
		
		// since we are re-processing an attribute, we need to remove ourself as a dependant from any dependencies from the previous evaluation
		for dependency in dependencies[attribute] ?? [] { // fucking lovely Swift >:/
			// this is kinda hard to wrap your head around
			if let dependants = dependency.0.dependants[dependency.1] {
				dependency.0.dependants[dependency.1] = dependants.filter { $0 != dependency }
				if dependency.0.dependants[dependency.1]?.count == 0 {
					dependency.0.dependants.removeValueForKey(dependency.1)
				}
			}
		}
		dependants.removeValueForKey(attribute)
		
		// set up the active attribute
		Gravity.domDependence.append((self, attribute))
		defer {
			let currentNode = Gravity.domDependence.popLast()
			assert(currentNode?.0 == self && currentNode?.1 == attribute, "Popped current node does not match pusher.")
		}
		
		// first, identify the value node for the attribute
		for plugin in document.plugins { // TODO: eventually this (and every other instance) will enumerate a specialized culled index that contains only plugins that have not returned .NotImplemented
			if plugin.selectAttribute(self, attribute: attribute, value: &value) == .Handled {
				break
			}
		}
		
		// actually we don't want this; we need to call processDom (?) on value, but only if necessary
		
		// next, process its value if it has one
		value?.processNode()
//		if let value = value {
//			for plugin in document.plugins {
//				plugin.processValue(value)
//				
//				if !value.include {
//					break
//				}
//			}
//		}
		
		// determine if the attribute has changed, and if so, update  recursively call processAttribute on each dependency
		let changed = value?.state != previousValue
		if changed {
//			attributes[attribute].token = Gravity.currentToken // the state has changed so update its token
			for dependant in dependants[attribute] ?? [] { // so fucking lame; there's got to be a more functional way to do this
				// we should assert that the target dependency has NOT been processed to make sure that we don't attempt to read a value for a token and then change it later making the initial read stale/invalid
				dependant.0.processAttribute(dependant.1)
			}
		}
		
		dynamicAttributes[attribute] = value
	}
	
//	private func oldProcessValue() {
////		print("\n\n\nProcessing:\n\(self)\n\n")
//		assert(processToken != Gravity.currentToken)
////		let unprocessed = processToken == -1
//		processToken = Gravity.currentToken
//		
//		loading = false // i'm not sure where the best place for this is, but by this point we are definitely not loading anymore (i think there are some issues with attribute nodes)
//		defer {
//			loading = true // experimental (we want this to reset when a node is done dom-processing)
//		}
//		//		let previousContents = contents.dynamicNodes // should we only do this for content nodes?
////		let previousAttributes = dynamicAttributes
//		let previousState = dynamicState // struct copy, yay!
////		if changed { // FIXME: i'm really not sure about this: how do we modify an attribute during the dom cycle and have its parent re-evaluate itself without completely trashing the change we just made?
//			// either we don't reset the DOM each time, or we make a special consideration for the attribute that started the process()
//			dynamicState = staticState
//			
//			// NEW IDEA! instead of copying the static attributes, rebuild them each time
//			dynamicState.attributes = []() // clear attributes
//			
////		}
////		dynamicState.attributes = staticState.attributes // reset the attributes to the static state and recompute
//		
//
//		// FIXME: this is breaking with embedded content (dynamic content is explicitly set before this point and this is clearing it)
////		if isAttributeNode && attributeName != "contents" {
////			dynamicState.childNodes = staticState.childNodes // is this correct? do we need to do anything else to handle content attribute nodes?
////		}
//		
////		for dependency in dependencies {
////			assert(dependency.dependants.contains(self))
////			dependency.dependants.remove(self)
////		}
////		dependencies.removeAll()
////		document.dependants.remove(self) // i'm not sure we want document dependants anymore
//		
//		include = true // included until proven excluded
//		
//		// FIXME: this is temp until we figure out contents change
////		changed = !childrenProcessed//false//!processed // default changed to true if we have never processed this node, otherwise reset it to false
////		processed = true // avoid processing twice (when should we reset this?)
//		
//		// moved-up from DOM phase so we can reference it via an alias
//		if _view == nil && !isAttributeNode {
//			instantiateView() // this lets plugins have a chance to see every view node, in some capacity (won't blow away existing view instances)
//		}
////		assert(_view != nil)
//		_view?.gravityNode = self // this is now strong (should this be in instantiateView?)
//		// if we can't do this here, move it back to processView and just set a viewInitialized flag or something:
//
//		
//		// process the immediate node's attributes first, so that child nodes can properly inherit scoped attributes that are properly computed
//		
//		
//		// 30 years i've been programming and still no one's created a loop construct to handle this situation. it can't be that uncommon.
//		while true {
//			let unprocessedAttributes = dynamicState.attributes.filter { !$0.1.processed && $0.0 != "contents" }
//			
//			if unprocessedAttributes.count == 0 {
//				break
//			}
//			
//			for (attribute, value) in unprocessedAttributes {
////				guard let value = dynamicState.attributes[attribute] else {
////					continue
////				}
//
//				// we might also iterate over keys and look it up each time (seems simpler)
//	//			if dynamicState.attributes[attribute] !== value {
//	//				preconditionFailure("can this still happen?")
//	////				assert(dynamicAttributes[attribute]?.state == .Resolve)
//	//				continue // make sure the attribute is still the same (it may have been overwritten; e.g. by a conditional)
//	//				// we might also implement this by just updating the current value to dynamicAttributes[attribute]; if it is already processed it will be skipped
//	//			}
//				
//	//			addDependency(value) // verify
//				
////				if !value.processed {
//					value.processDOM() // we have to reevaluate every attribute (at least unless/until we introduce attribute-specific change notification)
////				}
//
//				if value.changed {
//					changeToken = Gravity.currentToken
//				}
//				// is it possible for a value to be already processed and include == false? yes i think so
//				if !value.include && dynamicState.attributes[attribute] === value {
//					dynamicState.attributes.removeValueForKey(attribute)
//				}
//			}
//		}
//		
//		// compare the before and after attribute states
//		
////		if dynamicState.attributes.count != previousState.attributes.count {
////			changeToken = Gravity.currentToken
////		} else {
////			for (attribute, value) in dynamicState.attributes {
////				// is serialization a safe measure of attribute value? (seems like in theory it should be)
////				// FIXME: NO it isn't, because by this time the attributes may have object values and we can't rely on them being serializable
////				if value.serialize() != previousState.attributes[attribute]?.serialize() { // TODO: implement == if necessary
////					changeToken = Gravity.currentToken
////					break
////				}
////			}
////		}
//		
//		// this is probably more reliable for now, even though it can result in false positives
//		// do we need to compare the before and after attribute arrays here?
//		if dynamicState.attributes != previousState.attributes {
////			NSLog("Attributes have changed!!")
//			changeToken = Gravity.currentToken
//		}
//		
//		
//		if contents !== self {
//			if true || unprocessed {
//				contents.processDOM() // this will process the direct contents (always do this since it's really part of this node) -- I don't think this is true anymore!
//			}
//			// verify that this processes the effective contents, including if overridden as a dynamic attribute
//			
////			if previousContents != contents.dynamicNodes {
////				
////			}
////			for childNode in contents.dynamicNodes {
////				
////			}
//		}
//		// TODO: verify that contents attributes override physical contents
//
//		// FIXME: this is broken because flow needs to happen top-down; the child attribute needs to be processed *while* the parent is building its DOM, not processed first and then passed back up, because the parent resets when it starts processing
////		if changed && isAttributeNode {
////			if parentNode?.processed == false {
////				parentNode!.processDOM()
////			}
////		}
//		
//		// process *direct* contents first (the actual contents supplied to handleContents will depend on the "contents" attribute)
//		// note: if the contents attribute is overridden, it will happen either direclty on this node or from a higher node during the load cycle (a child cannot override the contents of a parent)
//		// changes to contents don't result in a change to the parent
//		if attributeName == "contents" { // only process contents if they are in a contents node (otherwise we assume it must be instantiated first) (verify) // exp: only do this for attribute nodes (forces contents to be processed as attributes)
//			for childNode in dynamicState.childNodes {
//	//			if !contents.dynamicNodes.contains(childNode) { // is this possible with conditionals?
//	//				continue
//	//			}
////				if !childNode.processed {
//					childNode.processDOM()
////				}
//				if !childNode.include {
//					// this isn't currently supported anymore (order needs to be solved)
//					contents.dynamicState.childNodes = contents.dynamicState.childNodes.filter { $0 != childNode }
//				}
//			}
//		}
//		
//		Gravity.currentNode = self // this is stored in thread-local storage (or will be)
//		defer {
//			Gravity.currentNode = nil
//		}
//		for plugin in document.plugins {
//			if self.isAttributeNode {
//				plugin.processValue(self)
//			} else {
////				plugin.processNode(self) // do we actually need this? weirdly nothing is using it
//			}
//			
//			if !include {
//				return // no point doing any further processing as this entire branch is excluded from the dynamic dom
//			}
//		}
////		Gravity.currentNode = nil
//		
//		// this is presently after contents processing so child documents can include their origin's contents
//		if let childDocument = childDocument { // childDocument is set in the pre-processing phase
//			if !childDocument.node.processed {
//				childDocument.node.processDOM()
//			}
//		}
//	}
	
	
	// III. The View Cycle
	
	internal func processView() {
//		let changed = true//changeToken > viewProcessedToken
		let lastViewProcessToken = viewProcessedToken
		viewProcessedToken = Gravity.currentToken // not sure if we need this anymore? it's not like we will ever call processView twice for the same change will we?
		
		loading = false // experimentally adding to view cycle as well
		defer {
			loading = true // experimental (we want this to reset when a node is done processing)
		}
		
		// TODO: do we need to process child documents if they themselves have not changed? should we only process child documents if we change?
		if let childDocument = childDocument { // childDocument is set in the pre-processing phase
			childDocument.node._view = view // perhaps there is a better place for this
			// FIXME: i'm really not sure if this should be up here or after we process ourself. we're only updating views, so we're probably ok
			// all the attributes will be deterministic at this point
			
			// TODO: only do this if childDocument.node has been touched
//			if childDocument.node.processToken > lastViewProcessToken
			childDocument.node.processView() // recurse
		}
		
		// TODO: make sure that GEs are given a chance to process values, and also that if a plugin or a GE recognizes an attribute but returns .NotHandled for it then that should still go to the default handler before processNode. (which means we might want to do it up a few lines)

		// First we need to figure out what attributes have changed. If we discover any new attributes at this point we can add them to the list.
		var changedAttributes = Set<String>()
		var newAttributes = Set<String>()//Set(dynamicAttributes.keys)
		
		for attribute in attributes {
			let baseAttribute = attribute.0.componentsSeparatedByString(":").first!
			
			if !attribute.1.isCondition { // this feels ugly, improve this
				newAttributes.insert(baseAttribute)
			}
		}
		
		for (attribute, (previousValue, scope)) in viewState { // make sure this copies (and safe to modify collection)
			newAttributes.remove(attribute) // is this enough? is it possible for an existing attribute to NOT appear in viewState? i don't believe so. it is quite possible for the attribute to 
			
			let currentValue = getAttribute(attribute, scope: scope)?.state
			if previousValue != currentValue {
				changedAttributes.insert(attribute)
//				viewState[attribute] = currentValue // this should no longer be necessary as accessing the value will now record its viewState (verify)
			}
		}
		
		// At this point, currentAttributes will contain only local attributes that are new since the last view cycle, which we process in the same way as changed attributes. So add them to the set.
		
		changedAttributes.unionInPlace(newAttributes)
		
		for attribute in newAttributes.union(viewDependencies.keys) {
			assert(attribute != "contents")
			
			if attribute == "" { // an empty attribute represents the postprocess (generic) handler which is handled below
				continue
			}
			
			let dependencies = viewDependencies[attribute] // if nil it is a new node
			
			// do we need to reset viewState[attribute] here?
			
			if attribute.containsString(":") {
				preconditionFailure("There should not be any conditionals left in the dom by this point!")
			}
			
			if dependencies == nil || dependencies?.intersect(changedAttributes).count > 0 {
			
				// At this point the attribute is determined to have changed and needs to be (re)processed.
				
				viewDependencies[attribute] = Set() // reset dependencies
				
				Gravity.viewDependence = (self, attribute)
				defer {
					assert(Gravity.viewDependence?.0 === self && Gravity.viewDependence?.1 == attribute, "Incorrect current view dependence.")
					Gravity.viewDependence = nil
				}
				
				// moved the value access below the viewDependence setup so it will be considered as a dependency for the current evaluation
				// note: we could optimize this a bit if we didn't pre-evaluate the value to pass as an argument and instead delegate this responsibility to the plugin, however that comes at a cost to convenience for the plugin hook and really would not likely actually offer any real performance (just a slightly more accurate depiction of dependence)
				// actually what we can do though is remove the dependence if the attribute is not handled
				let value = self[attribute] // viewState should be updated here (verify)
				if value?.isCondition == true {
					preconditionFailure("I don't think this is even possible. Colon-prefixed attributes should be ignored shouldn't they? This is more of a DOM-cycle thing.")
	//					NSLog("Condition found. Skipping handling:\n\(value)")
					continue
				}
				
//				viewState[attribute] = value?.state // record dependency state (see above)
				
				var handled = false
				if let gravityElement = gravityElement {
					handled = gravityElement.handleAttribute(self, attribute: attribute, value: value) == .Handled
					if handled {
						NSLog("\(value) handled by class \(gravityElement.dynamicType)")
					}
				}
				
				if !handled {
					for plugin in document.plugins { // must be done in plugin order
						handled = plugin.handleAttribute(self, attribute: attribute, value: value) == .Handled
						if handled {
							NSLog("\(value!) handled by plugin \(plugin.dynamicType).")
							break
						}
					}
				}
				
				if !handled {
					// TODO: enable this:
//					viewDependencies[attribute]?.remove(attribute) // experimental! this is purely an optimization
					NSLog("Warning: Attribute \"\(attribute)\" was not handled for node \(nodeName).")
				}
				
				if viewDependencies[attribute]?.count > 1 {
					NSLog("Node <\(nodeName)> recorded \(viewDependencies[attribute]!.count) dependencies for attribute \"\(attribute)\".")
				}
				
//				assert(viewDependencies[attribute]?.contains(attribute) == true, "Attributes should always be dependent upon themselves.")
				
			}
		}
		
		// Finally, iterate over our child nodes and see if we need to potentially process them as well.
		
		// TODO: is that the processToken, touchToken, or else?
		
		
		
		// we need to change how we do this; 
//		let removedAttributes = Array(Set(viewState.attributes.values).subtract(dynamicState.attributes.values))
////		let addedAttributes = Array(Set(dynamicState.attributes).subtract(previousState.attributes))
////		assert(removedAttributes.count == 0 || changed)//testing 
//		// should we process additions/removals before or after processing the attributes?
////		var handled = false
//		for removed in removedAttributes {
//			if let gravityElement = gravityElement {
//				if gravityElement.handleAttribute(self, attribute: removed.attributeName!, value: nil) == .Handled {
//					continue
//				}
//			}
//			for plugin in document.plugins {
//				if plugin.handleAttribute(self, attribute: removed.attributeName!, value: nil) == .Handled {
//					break
//				}
//			}
//		}
		
//		viewState = dynamicState // ok here? has to be after we check removedAttributes
		
//		if changed { // || removedAttributes.count?
			// TODO: double-check that there are indeed changes (changes to a single dom cycle does not necessarily mean a change here since they could be undone)
//			for (attribute, value) in attributes {
//				if attribute == "contents" {
//					continue // we don't want to handle "contents" attributes like other attributes as it has special meaning and no plugin/ge will handle it anyway
//				}
//				
//				if value.isCondition {
////					NSLog("Condition found. Skipping handling:\n\(value)")
//					continue
//				}
//				
//				// we currently have to do this to put the attribute back in a "dynamic" state for reading values; i'm not sure this is ideal, it feels kludgy
//				value.loading = false
//				defer {
//					value.loading = true
//				}
//				
//				if attribute.containsString(":") {
//					
////					preconditionFailure("There should not be any conditionals left in the dom by this point!")
//				}
//				
//				var changed = previousState.attributes[attribute] != viewState.attributes[attribute] // first compare the attribute's value itself
//				if !changed {
//					for dependency in value.dependencies {
//						if dependency.1 != value.getScopedAttribute(dependency.0)?.state {
//							NSLog("Dependency change detected!")
//							changed = true
//							break
//						}
//					}
//				}
//				
//				if !changed {
////					NSLog("\(value.nodeName) unchanged. Skipping handling.")
//					continue
//				}
//				
//				value.dependencies = [String : NodeValue?]()
//				Gravity.currentNode = value
//				defer {
//					Gravity.currentNode = nil
//				}
				
//				var handled = false
//				if let gravityElement = gravityElement {
//					handled = gravityElement.handleAttribute(self, attribute: attribute, value: value) == .Handled
//					if handled {
//						NSLog("\(nodeName) handled by class \(gravityElement.dynamicType)")
//					}
//				}
//				
//				if !handled {
//					for plugin in document.plugins { // must be done in plugin order
//						handled = plugin.handleAttribute(self, attribute: attribute, value: value) == .Handled
//						if handled {
//							NSLog("\(value) handled by plugin \(plugin.dynamicType).")
//							break
//						}
//					}
//				}
//				
//				if value.dependencies.count > 0 {
//					NSLog("Node \(value.nodeName) recorded \(value.dependencies.count) dependencies:\n\(value.dependencies)")
//				}
//				
//				if !handled {
//					NSLog("Warning: Node \(value.nodeName) was not handled.")
//				}
//			}
//		}
		
		for childNode in childNodes {
			// not sure if this should be before or after (pre/post order)
			
			// TODO: add some kind of touch token check for optimization:
			childNode.processView() // this should recurse in the order of the tree, depth-first
//			if childNode.view.superview == nil {
//				if gravityElement?.addChild != nil {
//					gravityElement!.addChild!(childNode)
//				} else {
//					for plugin in document.plugins {
//						if plugin.addChild(self, child: childNode) == .Handled {
//							break
//						}
//					}
//				}
//			}
		}
		
		// we need to figure out when/how best to do postprocessing on a node; for example, the layout stuff only needs to happen once during initial setup of the node, not every view cycle (that should be handled in processContents though no?)
//		if changed { // before or after contents?
			// i suppose we should probably do this for plugins too (maybe pre and post)
		Gravity.viewDependence = (self, nil)
		if lastViewProcessToken == -1 || viewDependencies[""]?.intersect(changedAttributes).count > 0 {
			if gravityElement?.postprocessNode != nil {
				gravityElement!.postprocessNode!(self)
			}
		}
		
		if !childrenProcessed { // temp (figure out contents change)
			childrenProcessed = true
		
			if let gravityElement = gravityElement {
//				gravityElement.processElement(self)
				if gravityElement.processContents != nil {
					gravityElement.processContents?(self)
					return //view // handled
				}
			}
			var handled = false
			for plugin in document.plugins { // this has nothing to do with attributes
				// only if we have contents?
				if plugin.processContents(self) == .Handled {
					handled = true
					break
				}
			}
			
			if !handled {
				NSLog("Warning: Node \(nodeName)’s children not handled!")
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

	// this should be based on the current node/attribute stored on domDependence or viewDependence (depending on cycle)
	internal func registerAsDependency(attribute: String, value: GravityNode?, scope: AttributeScope) { // rename recordDependency?
		// double link (verify)
//		assert(node !== self)
		guard let currentNode = Gravity.domCycle ? Gravity.domDependence.last?.0 : Gravity.viewDependence?.0 else {
			return
		}
		let currentAttribute = (Gravity.domCycle ? Gravity.domDependence.last?.1 : Gravity.viewDependence?.1) ?? ""
		
		if Gravity.domCycle {
			if currentNode.dependencies[currentAttribute] == nil {
				currentNode.dependencies[currentAttribute] = []
			}
			currentNode.dependencies[currentAttribute]!.append((self, attribute))
			if dependants[attribute] == nil {
				dependants[attribute] = []
			}
			dependants[attribute]!.append((currentNode, currentAttribute))
		} else {
			if currentNode.viewDependencies[currentAttribute] == nil {
				currentNode.viewDependencies[currentAttribute] = Set()
			}
			currentNode.viewDependencies[currentAttribute]?.insert(attribute)
			
			// FIXME: this is broken:
			// in theory this will keep setting the viewState to nil until we find a valid value at which point we will stop
			// the result should be the correct value of the attribute as perceived by the requester
//			let value = dynamicAttributes[attribute]?.state
//			assert(!(value == nil && currentNode.viewState[attribute]?.0 != nil))//test
//			currentNode.viewState[attribute] = (value, scope) // verify (we could also pass this in as an argument instead)
			// maybe check to see if currentNode == self??
			
			// new attempt:
			if currentNode === self {
				viewState[attribute] = (value?.state, scope)
			}
		}
	}

	internal func postprocess() {
		if let gravityElement = gravityElement {
			gravityElement.postprocessNode?(self)
		}
		for plugin in document.plugins {
			plugin.postprocessNode(self)
		}
		
		if _view?.hasAmbiguousLayout() == true {
			print("WARNING: View \(unsafeAddressOf(_view!)) has ambiguous layout:\n\(self)")
		}
	}
	
	// this shouldn't be called externally; use subscript notation to set attributes on a node
	internal func setAttribute(attribute: String, value: GravityNode) { // should we allow an attribute to be removed from the static dom by setting it to nil?
//		if loading { // see comment below; i don't like having both of these
//			staticState.attributes.removeValueForKey(attribute) // wait won't this completely blow away change determination? no i guess that's based on the dynamic state
//		}

		var attribute = attribute
		if attribute.hasPrefix(":") {
			// this is temp until we re-implement conditions
			attribute = attribute.substringFromIndex(attribute.startIndex.advancedBy(1))
		}
		
		// experimental (may nullify above):
		// (can we assume attributeName is not nil here? is it possible to set an attribute to a non-attribute node?)
		// this doesn't work for attributes that have been moved during load (subdoc refs)
		// we might need to have two kinds of parent reference (original parent and current parent? what about putting parent in state?) what we really need is a reliable way to ensure a node is only ever used once
		if value.parentNode?.attributes[value.attributeName!] === value {
			value.parentNode?.attributes.removeValueForKey(value.attributeName!)
		}
		
		value.document = value.document ?? document // should we allow specifying document when creating a value node?
//		value.state.nodeName = "\(self.nodeName).\(attribute)" // needed?
		value.attributeName = attribute // do we need this anymore?
//		assert(value.state.attributeName == attribute)// ^
		value.parentNode = self // won't need this if we unify with appendNode()
		
		// TODO: we need to split on conditions and treat them as a set (not order dependent)
		
//		let classParts = attribute.componentsSeparatedByString(":") // is this safe? should we split on "." first to handle parent.class:child?
//		let classPart = classParts.count > 1 ? classParts.last : nil
//		let attributePart = classParts.last!
		let attributeParts = attribute.componentsSeparatedByString(".")
		
		if attributeParts.count > 1 { // recursive case
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
		} else { // base case
			// this should maybe be moved into an initializer:
//			var attribute = attribute
//			if attribute.hasPrefix(":") {
//				assert(attribute.componentsSeparatedByString(":").count == 2, "Condition attributes must be atomic.")
//				value.isCondition = true
//				attribute = attribute.substringFromIndex(attribute.startIndex.advancedBy(1))
//				value.attributeName = attribute
//			}
			
			// also experimental--do static preprocessing here, but only on first load
			if loading && value.unprocessed {
				for plugin in document.plugins {
					// or perhaps we should call this from setAttribute so that we can recursively process nodes with multiple conditions by removing a piece and re-adding the attribute
					if plugin.preprocessValue(value) == .Handled {
						return // we've already removed the attr above; nothing left to do
						
						// but what happens if we change the attribute? what if we repurpose it and call setAttribute from preprocessValue?
					}
				}
			}
			
			if loading { // can we just roll this up into Gravity.processing? do we need a node-specific loading flag still? actually perhaps we can roll this up into loading; after a node is processed it should go back into a loading state
				attributes[attribute] = value
				if processToken != -1 { // ok? we want to avoid calling process() during the initial load cycle
					value.process()
				}
			} else {
				// i'm not sure we can get here anymore; dynamicAttributes should be set by the processAttribute function now I think
				
				assert(false)
				
				// TODO: store this in a temporary array that we can use to compute changes, or back up the previous array somewhere first
				dynamicAttributes[attribute] = value
				// FIXME: this needs to do the same processing that unrecognized attributes go through
				
				// TODO: this should be done in one place by appendNode and it should only process if the node is not already processed (for the given wave)
//				if !value.processed{
//					if Gravity.processing {
//						value.processDOM() // experimental
//					} else {
//						value.process()
//					}
//				}
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
	public func serialize(debugMode: Bool = false, indent: String = "  ", dynamic: Bool = false) -> String {
		let attrs = dynamic ? dynamicAttributes : attributes
		var attributeStrings = [String]()
		var attributeNodes = [GravityNode]()
		for (key, value) in attrs {
			if let stringValue = value.stringValue {
				// FIXME: add proper escaping for XML attribute value
				let escapedValue = stringValue.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(escapedValue)\"")
			} else {
				attributeNodes.append(value)
			}
		}
		
		let address = debugMode && self.viewIsInstantiated ? "(\(unsafeAddressOf(view)))" : "" // should we return the address of the view or the node?
		let childNodes = dynamic ? contents.childNodes : contents.childNodes + attributeNodes // verify
		
		if childNodes.count > 0 {
			// indent:
			var childNodeStrings = childNodes.map { // static
				return $0.serialize(debugMode, indent: indent).componentsSeparatedByString("\n").map {
					return "\(indent)\($0)"
				}.joinWithSeparator("\n")
			}
			
			if let stringValue = state.stringValue {
				childNodeStrings.append(stringValue)
			}
			
			return "<\(nodeName)\(address)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
		} else if state.stringValue != nil {
			return "<\(nodeName)\(address)>\(state.stringValue!)</\(nodeName)>"
		} else {
			return "<\(nodeName)\(address) \(attributeStrings.joinWithSeparator(" "))/>"
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

// this affects array equality --change to NodeValue if necessary
//public func ==(lhs: GravityNode, rhs: GravityNode) -> Bool {
//	if lhs._stringValue != rhs._stringValue
//		|| lhs._boolValue != rhs._boolValue
//		|| lhs._intValue != rhs._intValue
//		|| lhs._floatValue != rhs._floatValue {
//		return false
//	}
//	
//	if lhs._objectValue?.isEqual(rhs._objectValue) == false { // i think i'm missing something here
//		return false
//	}
//	
//	if lhs.childNodes.count != rhs.childNodes.count {
//		return false
//	}
//	
//	// verify
//	for i in 0 ..< lhs.childNodes.count {
//		if lhs.childNodes[i] !== rhs.childNodes[i] {
//			return false
//		}
//	}
//	
//	return true
//}

internal func ==(lhs: GravityNode.NodeValue, rhs: GravityNode.NodeValue) -> Bool {
	if lhs.stringValue != rhs.stringValue
		|| lhs.boolValue != rhs.boolValue
		|| lhs.intValue != rhs.intValue
		|| lhs.floatValue != rhs.floatValue {
		return false
	}
	
	if (lhs.objectValue != nil && rhs.objectValue == nil) || (lhs.objectValue == nil && rhs.objectValue != nil) {
		return false
	}
	
	if lhs.objectValue?.isEqual(rhs.objectValue) == false {
		return false
	}
	
	// TODO: improve this; only check for attribute nodes with content
//	if lhs.attributeName != nil && rhs.attributeName != nil && lhs.serialize() != rhs.serialize() {
//		return false
//	}
	
	return true
}

@available(iOS 9.0, *)
extension GravityNode: SequenceType {
	public func generate() -> AnyGenerator<GravityNode> {
		var childGenerator = childNodes.generate() // static or dynamic?? switch on processed?
		var subGenerator: AnyGenerator<GravityNode>?
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
