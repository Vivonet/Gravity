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
public class GravityView: UIView, NSXMLParserDelegate, GravityElement {
	private var nodeStack = [GravityNode]()
	public var rootNode: GravityNode?

	@IBInspectable public var xml: String = "" {
		didSet {
			parseXML()
		}
	}

	@IBInspectable public var filename: String = "" {
		didSet {
			// if filename doesn't end with .xml (and can't be found as specified) append .xml
			NSLog("GravityView filename changed!")
			let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(filename, isDirectory: false)
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
		self.xml = xml
	}
	
	convenience public init(filename: String) {
		self.init()
		self.filename = filename
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
		NSLog("100%% reconsituted xml!\n" + (rootNode?.description ?? ""))
//		}

		for subview in subviews {
			subview.removeFromSuperview()
		}
		addSubview(rootNode!.view)
		
		rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
		rootNode!.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
		
		autoSize()
		
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
	
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		return false
	}
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
	
		let node = GravityNode(parentNode: nodeStack.last, nodeName: elementName, attributes: attributeDict)
		rootNode = rootNode ?? node
		nodeStack.last?.childNodes.append(node)
		nodeStack.append(node)
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		nodeStack.popLast()
	}
}
