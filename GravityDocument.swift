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
	
	/// The `GravityNode` that represents this document in the child tree.
	public var node: GravityNode!
	public var name: String? = nil
	/// The `GravityNode` that represents this document in the parent tree.
	public weak var parentNode: GravityNode? = nil // if this document is an embedded node
	public lazy var ids = [String : GravityNode]()
	public lazy var plugins = [GravityPlugin]() // the instantiated plugins for this document
	public var model: AnyObject? = nil
	private var postprocessed = false
	
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
	
	public var view: UIView {
		get {
//			if node.isViewInstantiated() {
//				return node.view
//			} else {
				defer {
					postprocess() // we could also just set a flag and call this each time
				}
				return node.view
//			}
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
		
		self.node = GravityNode(document: self, parentNode: parentNode, nodeName: name, attributes: [:])
		self.nodeStack.append(self.node)

		// append ".xml" if the name doesn't end with it
		// TODO: we should improve this to check for the given name first
		self.name = name
		self.model = model
		let effectiveName = name.rangeOfString(".xml", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil ? "\(name).xml" : name
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(effectiveName, isDirectory: false)
		do {
			self.xml = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
			parseXML()
		} catch {
			return nil
		}
	}

	public init(xml: String, model: AnyObject? = nil) {
		super.init()
		self.xml = xml // really annoying that didSet doesn't work from initializers :(
		self.model = model
		parseXML()
	}
	
	/// Instantiates a new document using the current document as a template. The returned document will be a clone of the current document. Instantiating a `GravityDocument` does *not* establish the receiver’s `view` property.
	public func instantiate(model: AnyObject? = nil) -> GravityDocument {
		// should this return a UIView or a GravityDocument?
		return GravityDocument(xml: self.description, model: model)
	}

	private func parseXML() {
		guard let data = self.xml.dataUsingEncoding(NSUTF8StringEncoding) else {
			return // TODO: print message or something
		}
		
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
	internal func instantiateView(node: GravityNode) -> UIView {
		for plugin in plugins {
			if let view = plugin.instantiateView(node) {
				return view
			}
		}
		return UIView()
	}
	
	// MARK: PRE-PROCESSING PHASE
	internal func preprocess() {
		for childNode in self.node { // sloppy i know
			if childNode == self.node { // skip self!
				continue
			}
			
			if let identifier = childNode["id"]?.textValue {
				if ids[identifier] != nil {
					preconditionFailure("Duplicate definition of identifier ‘\(identifier)’.")
				}
				ids[identifier] = childNode
			}
			
			
			if let childDocument = GravityDocument(name: childNode.nodeName, model: nil, parentNode: childNode) {
				childNode.childDocument = childDocument // strong
				childDocument.parentNode = childNode // weak
			}
			
			// identify and transform attribute nodes into actual attributes with node values
			if childNode.nodeName.containsString(".") {
				guard let parentNode = childNode.parentNode else {
					// apply to parent document? that breaks containment.
					preconditionFailure("Attribute node found at top of document. Attribute nodes must have a parent.")
				}
				// TODO: allow _ shorthand?
				let parentElementIndex = childNode.nodeName.startIndex.advancedBy(parentNode.nodeName.characters.count) // wow Swift, wow. :|
				if childNode.nodeName.substringToIndex(parentElementIndex) == parentNode.nodeName && childNode.nodeName.characters[parentElementIndex] == "." {
					let attributeName = childNode.nodeName.substringFromIndex(parentElementIndex.advancedBy(1))
					
					// surprisingly this actually seems to work:
					parentNode.childNodes = parentNode.childNodes.filter { $0 != childNode }
					parentNode.attributes[attributeName] = childNode
				} else {
					preconditionFailure("Invalid attribute node notation. Element name must start with parent element (expected ‘\(parentNode.nodeName)’).")
				}
				
				// TODO: make sure this works recursively; i.e. we can have multiple levels of attribute nodes affecting each other
			}
		}
		
		// this is done in a separate loop so all parent-referencing attribute nodes are handled first; this can be optimized later
		for childNode in self.node {
			for (attribute, value) in childNode.attributes {
				if attribute.containsString(".") {
					childNode.attributes.removeValueForKey(attribute) // verify
					childNode.setAttribute(attribute, value: value)
				}
			}
		}
	}
	
//	var processed = false
	
	// MARK: POST-PROCESSING PHASE
	internal func postprocess() { // post-process view hierarchy
		if postprocessed {
//			NSLog("twice?!")
			return
		}
		postprocessed = true
		// should we set some processed flag so we only do it once?
		assert(node.isViewInstantiated())
		for childNode in self.node { // we weren't calling postprocess on sub-documents
			if let childDocument = childNode.childDocument {
				childDocument.postprocess() // verify
			} else {
	//			NSLog("postprocess: \(childNode)")
				for plugin in plugins {
					plugin.postprocessElement(childNode)
				}
			}
			
			if childNode.view.hasAmbiguousLayout() {
				NSLog("WARNING: Node has ambiguous layout:\n\(childNode)")
			}
			
			if childNode.view.translatesAutoresizingMaskIntoConstraints {
				NSLog("WARNING: View has translatesAutoresizingMaskIntoConstraints set.")
				childNode.view.translatesAutoresizingMaskIntoConstraints = false
			}
		}
		
		controllerChanged()
	}
	
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
		
		nodeStack.last?.childNodes.append(node)
		nodeStack.append(node)
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		nodeStack.popLast()
	}
	
	public func parser(parser: NSXMLParser, var foundCharacters string: String) {
		string = string.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
		if string == "" {
			return
		}
		// TODO: treat this as a text value if the parent is an attribute node
		// or would it make more sense to do the implicit label thing, since really, why would you ever want to use an attribute node for a text value? (actually you might for a very large block of text, so it's reasonable)
		// TODO: rather than set parent.textValue right away, set a temp string to see if there are any more sibling nodes; if not, set parent.textValue
		// if so, treat all nodes (including the stored string) as child nodes/labels
		if let parentNode = nodeStack.last {
			if parentNode.nodeName.containsString(".") {
				parentNode.textValue = string
				return
			}
		}
		
		// if the parent is not an attribute node, should we implicitly treat it as a UILabel with text set? that would be cool. it'll (eventually) inherit font, color, etc. already
		// experimental:
		let node = GravityNode(document: self, parentNode: nodeStack.last, nodeName: "UILabel", attributes: ["text": string, "wrap": string.containsString("\n") ? "true" : "false"])
		nodeStack.last?.childNodes.append(node)
		// don't append to nodeStack because it will never be popped
	}
}
