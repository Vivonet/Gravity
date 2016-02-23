//
//  GravityDocument.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-28.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

/// The ‘D’ in DOM. This class represents a single instance of a gravity layout file.
@available(iOS 9.0, *)
@objc public class GravityDocument: NSObject, NSXMLParserDelegate, CustomDebugStringConvertible {
	private var nodeStack = [GravityNode]() // for parsing
	
	public var node: GravityNode! // i'm assuming this will be filled in quickly
	public var name: String? = nil
//	public lazy var childNodes = [GravityNode]()
//	public var rootNode: GravityNode?
	public weak var parentNode: GravityNode? = nil // if this document is an embedded node
	public lazy var ids = [String : GravityNode]()
	public lazy var plugins = [GravityPlugin]() // the instantiated plugins for this document
	public var model: AnyObject? = nil
	
	public var controller: NSObject? = nil {
		didSet {
			controllerChanged()
		}
	}

	public var xml: String = "" {
		didSet {
			parseXML()
		}
	}

	// TODO: this feels kinda gross, improve
//	public var rootNodeView: UIView? {
//		get {
//			if rootNode == nil {
//				parseXML()
//			}
//			
//			return rootNode?.view
//		}
//	}
	
//	private var _view: UIView? = nil
	public var view: UIView {
		get {
			return node.view
		}
	}
	
	subscript(identifier: String) -> GravityNode? {
		get {
			return ids[identifier]
		}
	}
	
	public override init() {
		
	}
	
	convenience init?(name: String, model: AnyObject? = nil) {
		self.init(name: name, model: model, parentNode: nil)
	}
	
	private init?(name: String, model: AnyObject? = nil, parentNode: GravityNode?) {
		super.init()
		
		// TODO: if this is an embedded node, use the parent node
		self.node = GravityNode(document: self, parentNode: parentNode, nodeName: name, attributes: [:])
		self.nodeStack.append(self.node)

//		defer { self.filename = filename } // defer allows didSet to be called

		// append ".xml" if the name doesn't end with it
		// TODO: we should improve this to check for the given name first
		self.name = name
		self.model = model
		let effectiveName = name.rangeOfString(".xml", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil ? "\(name).xml" : name
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(effectiveName, isDirectory: false)
		do {
			self.xml = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
			parseXML()
			// FIXME: instead of setting the root node's model, let's set the model at the document and simply inherit it from the node's perspective
//			rootNode?.model = model
		} catch {
			return nil
		}
	}

	public init(xml: String, model: AnyObject? = nil) {
		super.init()
		self.xml = xml // really annoying that didSet doesn't work from initializers :(
		self.model = model
		parseXML()
//		rootNode?.model = model // ok?
	}
	
	/// Instantiates a new view using the current document as a template. The document associated with the returned view will be a clone of the current document. Instantiating a `GravityDocument` does *not* establish the receiver’s `view` property.
	public func instantiate(model: AnyObject? = nil) -> GravityDocument {
		// should this return a UIView or a GravityDocument?
		return GravityDocument(xml: self.description, model: model)
	}

	private func parseXML() {
		guard let data = self.xml.dataUsingEncoding(NSUTF8StringEncoding) else {
			return // TODO: print message or something
		}
		
//		Gravity.load() // make sure all of our plugins have been loaded (this is actually probably not necessary since we're accessing Gravity immediately after this)
		
		for pluginClass in Gravity.plugins {
			let plugin = pluginClass.init()
			plugins.append(plugin)
		}
		
		let parser = NSXMLParser(data: data)
		parser.delegate = self
		parser.parse()

		if node.childNodes.isEmpty {
			NSLog("Error: Could not parse gravity file.")
			return
		}

		preprocess()
	}
	
	// this may belong in GravityNode
	public func instantiateView(node: GravityNode) -> UIView? {
//		var view: UIView? = nil
		
		for plugin in plugins {
			if let view = plugin.instantiateElement(node) {
				return view
			}
		}
		
		return nil
	}
	
	// MARK: PRE-PROCESSING PHASE
	internal func preprocess() {
		for node in self.node { // sloppy i know
			if node == self.node { // skip self!
				continue
			}
			
			if let identifier = node["id"]?.textValue {
				if ids[identifier] != nil {
					preconditionFailure("Duplicate definition of identifier ‘\(identifier)’.")
				}
				ids[identifier] = node
			}
			
			
			if let childDocument = GravityDocument(name: node.nodeName, model: nil, parentNode: node) {
				node.childDocument = childDocument // strong
				childDocument.parentNode = node // weak
			}
			
			// identify and transform attribute nodes into actual attributes with node values
			if node.nodeName.containsString(".") {
				guard let parentNode = node.parentNode else {
					// apply to parent document? that breaks containment.
					preconditionFailure("Attribute node found at top of document. Attribute nodes must have a parent.")
				}
				// TODO: allow _ shorthand?
				let parentElementIndex = node.nodeName.startIndex.advancedBy(parentNode.nodeName.characters.count) // wow Swift, wow. :|
				if node.nodeName.substringToIndex(parentElementIndex) == parentNode.nodeName && node.nodeName.characters[parentElementIndex] == "." {
					let attributeName = node.nodeName.substringFromIndex(parentElementIndex.advancedBy(1))
					NSLog("Valid attribute node found; attribute: '\(attributeName)'")
					
					// surprisingly this actually seems to work:
					parentNode.childNodes = parentNode.childNodes.filter { $0 != node }
					parentNode.attributes[attributeName] = node
				} else {
					preconditionFailure("Invalid attribute node notation. Element name must start with parent element (expected ‘\(parentNode.nodeName)’).")
				}
				
				// TODO: make sure this works recursively; i.e. we can have multiple levels of attribute nodes affecting each other
			}
			
			for (attribute, value) in node.attributes {
				if attribute.containsString(".") {
					node.attributes.removeValueForKey(attribute) // verify
					node.setAttribute(attribute, value: value)
				}
			}
		}
	}
	
	// MARK: POST-PROCESSING PHASE
	internal func postprocess() { // post-process view hierarchy
		for node in self.node { // FIXME: should we start with outerNode?
//			NSLog("Post-processing node: \(node.nodeName)")
			for plugin in plugins {
				plugin.postprocessElement(node)
			}
		}
		
		controllerChanged()
	}
	
	// TODO: this function is temporary until i figure out how to do this properly
//	public func autoSize() {
////		containerView.updateConstraints() // need this?
//		if let view = view {
//			view.layoutIfNeeded()
//			
//			// should these be constraints?
//			view.frame.size.width = view.subviews[0].frame.size.width
//			view.frame.size.height = view.subviews[0].frame.size.height
//		}
//	}
	
	private func controllerChanged() {
		if controller != nil {
			for (identifier, node) in ids {
//				if !node.isViewInstantiated() {
//					continue
//				}
				tryBlock {
					self.controller?.setValue(node.view, forKey: identifier)
				}
			}
			node.connectController(controller!)
		}
	}
	
	public override var description: String {
		get {
			return node.description
		}
	}
	
	public override var debugDescription: String {
		get {
			return node.debugDescription
		}
	}
	
	// MARK: NSXMLParserDelegate
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		
		let node = GravityNode(document: self, parentNode: nodeStack.last, nodeName: elementName, attributes: attributeDict)
//		rootNode = rootNode ?? node
//		if nodeStack.isEmpty {
//			childNodes.append(node)
//		} else {
		nodeStack.last?.childNodes.append(node)
//		}
		nodeStack.append(node)
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		nodeStack.popLast()
	}
	
	public func parser(parser: NSXMLParser, var foundCharacters string: String) {
		// trim string?
		string = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		if string == "" {
			return
		}
		// TODO: treat this as a text value if the parent is an attribute node
		// or would it make more sense to do the implicit label thing, since really, why would you ever want to use an attribute node for a text value? (actually you might for a very large block of text, so it's reasonable)
		if let parentNode = nodeStack.last {
			if parentNode.nodeName.containsString(".") {
				parentNode.textValue = string
				return
			}
		}
		
		// if the parent is not an attribute node, should we implicitly treat it as a UILabel with text set? that would be cool. it'll (eventually) inherit font, color, etc. already
		// experimental:
		let node = GravityNode(document: self, parentNode: nodeStack.last, nodeName: "UILabel", attributes: ["text": string])
		// FIXME: maybe offload this to a private addNode function
//		rootNode = rootNode ?? node
		nodeStack.last?.childNodes.append(node)
//		nodeStack.append(node) // don't append because it will never be popped
	}
}
