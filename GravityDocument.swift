//
//  GravityView.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-28.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

/// The ‘D’ in DOM.
@available(iOS 9.0, *)
@objc public class GravityDocument: NSObject, NSXMLParserDelegate, GravityPlugin, CustomDebugStringConvertible {
	public var name: String? = nil
	private var nodeStack = [GravityNode]()
	private var widthIdentifiers = [String: [GravityNode]]()
	public var rootNode: GravityNode?
	public var ids: [String : GravityNode] = [:]
	
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

//	@IBInspectable public var filename: String = "" {
//		didSet {
//			// append ".xml" if the filename doesn't end with it
//			// TODO: we should improve this to check for the given name first
//			let effectiveName = filename.rangeOfString(".xml", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil ? "\(filename).xml" : filename
//			let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(effectiveName, isDirectory: false)
//			do {
//				xml = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
//			} catch {
//			}
//		}
//	}

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
						rootNode!.parentNode = outerNode // this is experimental
						
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
	
	public init?(name: String) {
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
		} catch {
			return nil
		}
	}

	public init(xml: String) {
		super.init()
//		self.init()
		self.xml = xml
		parseXML()
	}
	


//	required public init?(coder aDecoder: NSCoder) {
//	    super.init(coder: aDecoder)
//	}

	private func parseXML() {
		guard let data = self.xml.dataUsingEncoding(NSUTF8StringEncoding) else {
			return // TODO: print message or something
		}
		
		Gravity.load() // make sure all of our plugins etc. have been loaded (is this safe to call multiple times?) i think so
		
		let parser = NSXMLParser(data: data)
		parser.delegate = self
		parser.parse() // PARSE PHASE
//		NSLog("100%% reconsituted xml!\n" + (rootNode?.description ?? ""))

		if rootNode == nil {
			NSLog("Error: Could not parse Gravity XML.")
			return
		}
		
//		_ = rootNode!.view // make sure the view hierarchy is fully constructed
		
		// should we do this in a plugin? can we maintain state via begin and end events? or should we instantiate plugins for each parse?
		
		// this is probably broken now too; we should defer this to later

		preProcess()

////		let fitSize = rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
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
			
			if let subDocument = GravityDocument(name: node.nodeName) {
				node.subDocument = subDocument
				node.subDocument?.preProcess()
			}
		}
	}
	
	// MARK: POST-PROCESSING PHASE
	internal func postProcess() { // post-process view hierarchy
		for node in rootNode! { // FIXME: should we start with outerNode?
			NSLog("Post-processing node: \(node.nodeName)")
			for plugin in Gravity.plugins {
				plugin.processElement?(node) // post-process
			}
		}
		
//				rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
//				rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
		
//				autoSize()
		controllerChanged()
		
		// is this ok here?
		for (identifier, nodes) in widthIdentifiers {
			if ["fill", "auto"].contains(identifier) { // special keywords
				continue
			}
			
			let first = nodes[0]
			for var i = 1; i < nodes.count; i++ {
				nodes[i].view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: first.view)
			}
		}
	}
	
	// TODO: this function is temporary until i figure out how to do this properly
	public func autoSize() {
//		containerView.updateConstraints() // need this?
		if let view = view {
			view.layoutIfNeeded()
			
			// should these be constraints?
			view.frame.size.width = view.subviews[0].frame.size.width
			view.frame.size.height = view.subviews[0].frame.size.height
		}
	}
	
	private func controllerChanged() {
		if controller != nil {
			for (identifier, node) in ids {
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
	
	// MARK: GravityElement
	
//	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
//		return false
//	}
	
//	public func processElement(node: GravityNode) -> Bool {
//		self.translatesAutoresizingMaskIntoConstraints = false
//		return false
//	}
	
	// MARK: GravityPlugin
	
	public static func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
	
		// does this still make sense here?
	
		switch attribute {
			case "width":
				let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
				if value.rangeOfCharacterFromSet(charset) != nil {
					if node.document.widthIdentifiers[value] == nil {
						node.document.widthIdentifiers[value] = [GravityNode]()
					}
					node.document.widthIdentifiers[value]?.append(node)
//				if "\((value as NSString).floatValue)" != value {
					return true
				}
				return false
				
			default:
				return false
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
