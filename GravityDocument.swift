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
	
	public var name: String? = nil
	public var rootNode: GravityNode?
	public weak var parentNode: GravityNode? = nil // if this document is an embedded node
	public var ids = [String : GravityNode]()
	public var plugins = [GravityPlugin]() // the instantiated plugins for this document
	
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
	public var rootNodeView: UIView? {
		get {
			if rootNode == nil {
				parseXML()
			}
			
			return rootNode?.view
		}
	}
	
	private var _view: UIView? = nil
	public var view: UIView? {
		get {
			if _view == nil {
				if let rootNodeView = rootNodeView {
					if let name = name {
						// TODO: handle the case where the root node is already a "self node"
						let outerNode = GravityNode(document: self, parentNode: nil, nodeName: name, attributes: [:])
						outerNode.childNodes.append(rootNode!)
//						rootNode!.parentNode = outerNode // this is experimental
						
//						_view = Gravity.instantiateView(outerNode)
//						_view?.addSubview(rootNodeView)
						_view = rootNodeView
					}
					
					postProcess()
				}
			}
			
			return _view
		}
	}
	
	public override init() {
		
	}
	
	public init?(name: String, model: AnyObject? = nil) {
		super.init()
//		defer { self.filename = filename } // defer allows didSet to be called

		// append ".xml" if the name doesn't end with it
		// TODO: we should improve this to check for the given name first
		self.name = name
		let effectiveName = name.rangeOfString(".xml", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil ? "\(name).xml" : name
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(effectiveName, isDirectory: false)
		do {
			self.xml = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
			parseXML()
			rootNode?.model = model
		} catch {
			return nil
		}
	}

	public init(xml: String) {
		super.init()
		self.xml = xml // really annoying that didSet doesn't work from initializers :(
		parseXML()
	}

	private func parseXML() {
		guard let data = self.xml.dataUsingEncoding(NSUTF8StringEncoding) else {
			return // TODO: print message or something
		}
		
//		Gravity.load() // make sure all of our plugins have been loaded (this is actually probably not necessary since we're accessing Gravity immediately after this)
		
		for pluginClass in Gravity.plugins {
			let pluginInstance = pluginClass.init()
			plugins.append(pluginInstance)
		}
		
		let parser = NSXMLParser(data: data)
		parser.delegate = self
		parser.parse()

		if rootNode == nil {
			NSLog("Error: Could not parse Gravity XML.")
			return
		}

		preProcess()
	}
	
	public func instantiateView(node: GravityNode) -> UIView? {
		var view: UIView? = nil
		
		for plugin in plugins {
			if let view = plugin.instantiateElement(node) {
				return view
			}
		}
		
		if let type = NSClassFromString(node.nodeName) as! UIView.Type? {
			tryBlock {
				view = type.init()
				view?.translatesAutoresizingMaskIntoConstraints = false // do we need this??
				// TODO: should we set clipsToBounds for views by default?
			}
			
			// TODO: determine if the instance is an instance of UIView or UIViewController and handle the latter by embedding a view controller
		}
		
		return view
	}
	
	// MARK: PRE-PROCESSING PHASE
	internal func preProcess() {
		for node in rootNode! {
			if let identifier = node["id"] {
				if ids[identifier] != nil {
					NSLog("Error: Duplicate definition of identifier ‘\(identifier)’. This will become a true error in the future.")
					continue
					// TODO: throw error
				}
				ids[identifier] = node
			}
			
			if let childDocument = GravityDocument(name: node.nodeName) {
				node.childDocument = childDocument // strong
				childDocument.parentNode = node // weak
			}
		}
	}
	
	// MARK: POST-PROCESSING PHASE
	internal func postProcess() { // post-process view hierarchy
		for node in rootNode! { // FIXME: should we start with outerNode?
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
			rootNode?.connectController(controller!)
		}
	}
	
	public override var description: String {
		get {
			return rootNode?.description ?? super.description
		}
	}
	
	public override var debugDescription: String {
		get {
			return rootNode?.debugDescription ?? description // super works here?
		}
	}
	
	// MARK: NSXMLParserDelegate
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
	
		let node = GravityNode(document: nodeStack.last?.document ?? self, parentNode: nodeStack.last, nodeName: elementName, attributes: attributeDict)
		rootNode = rootNode ?? node
		nodeStack.last?.childNodes.append(node)
		nodeStack.append(node)
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		nodeStack.popLast()
	}
}
