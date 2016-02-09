//
//  GravityView.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-28.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@IBDesignable
@objc(GravityView)
public class GravityView: UIView, NSXMLParserDelegate, GravityElement, GravityPlugin {
	private var nodeStack = [GravityNode]()
	private var widthIdentifiers = [String: [GravityNode]]()
	
	public var rootNode: GravityNode?
	
	public var controller: NSObject? = nil {
		didSet {
			controllerChanged()
		}
	}

	@IBInspectable public var xml: String = "" {
		didSet {
			parseXML()
		}
	}

	@IBInspectable public var filename: String = "" {
		didSet {
			// if filename doesn't end with .xml (and can't be found as specified) append .xml
			let effectiveName = filename.rangeOfString(".xml", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil ? "\(filename).xml" : filename
			NSLog("GravityView filename changed!")
			let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(effectiveName, isDirectory: false)
			do {
				xml = try String(contentsOfURL: url, encoding: NSUTF8StringEncoding)
			} catch {
			}
		}
	}
	
	public var ids: [String : UIView] = [:]
	
	required public init() {
		super.init(frame: CGRectZero)
		// TODO: this actually breaks when we do this, figure out why:
//		translatesAutoresizingMaskIntoConstraints = false
	}
	
	convenience public init(xml: String) {
		self.init()
		defer { self.xml = xml } // defer allows didSet to be called
	}
	
	convenience public init(filename: String) {
		self.init()
		defer { self.filename = filename } // defer allows didSet to be called
	}

	required public init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}

	private func parseXML() {
		guard let data = self.xml.dataUsingEncoding(NSUTF8StringEncoding) else {
			return // TODO: print message or something
		}
		
		let parser = NSXMLParser(data: data)
		parser.delegate = self
		parser.parse()
//		NSLog("100%% reconsituted xml!\n" + (rootNode?.description ?? ""))

		if rootNode == nil {
			NSLog("Error: Could not parse Gravity XML.")
			return
		}
		
		_ = rootNode!.view // make sure the view hierarchy is fully constructed
		
		for (identifier, nodes) in widthIdentifiers {
			if identifier == "fill" || identifier == "auto" { // special keywords
				continue
			}
			
			let first = nodes[0]
			for var i = 1; i < nodes.count; i++ {
				nodes[i].view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: first.view)
			}
		}

		for subview in subviews {
			subview.removeFromSuperview()
		}
		addSubview(rootNode!.view)
		
		for node in rootNode! {
			NSLog("ITERATING NODE: \(node.nodeName)")
			for plugin in Gravity.plugins {
				plugin.processElement?(node) // post-process
			}
		}
		
		rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
		rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
		
		autoSize()
		controllerChanged()
		
//		// TODO: add more convenient support for instantiating a view within an interface (such as via another view or view controller)
//		// perhaps we should write this as an extension on UIView and then we can simply check the size of the parent view
////		let fitSize = rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
	}
	
	// TODO: this function is temporary until i figure out how to do this properly
	public func autoSize() {
//		containerView.updateConstraints() // need this?
		layoutIfNeeded()
		
		// should these be constraints?
		frame.size.width = subviews[0].frame.size.width
		frame.size.height = subviews[0].frame.size.height
	}
	
	private func controllerChanged() {
		if controller != nil {
			rootNode?.connectController(controller!)
		}
	}
	
	// MARK: GravityElement
	
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		return false
	}
	
	public func processElement(node: GravityNode) -> Bool {
		self.translatesAutoresizingMaskIntoConstraints = false
		return false
	}
	
	// MARK: GravityPlugin
	
	public static func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		switch attribute {
			case "width":
				let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
				if value.rangeOfCharacterFromSet(charset) != nil {
					if node.gravityView!.widthIdentifiers[value] == nil {
						node.gravityView!.widthIdentifiers[value] = [GravityNode]()
					}
					node.gravityView!.widthIdentifiers[value]?.append(node)
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
	
		let node = GravityNode(gravityView: nodeStack.last?.gravityView ?? self, parentNode: nodeStack.last, nodeName: elementName, attributes: attributeDict)
		rootNode = rootNode ?? node
		nodeStack.last?.childNodes.append(node)
		nodeStack.append(node)
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		nodeStack.popLast()
	}
}
