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
	public var depth: Int // the number of nodes deep this node is in the tree
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed tree
	public var attributes: [String: String]
	public var constraints: [String: NSLayoutConstraint] // store constraints here based on their attribute name (width, minHeight, etc.) -- we should move this to a plugin, but only if we can put all or most of the constraint registering in there as well
	public var childNodes = [GravityNode]()
	public var childDocument: GravityDocument? = nil // if this node represents an external document
	
	subscript(attribute: String) -> String? {
		get {
			return attributes[attribute]
		}
	}
	// add Int-indexed subscript for child nodes too? or is that supported by SequenceType? probably we need CollectionType or something for that
	
	// oh but it would be sweet if we could do this!
//	subscript<T>(attribute: String) -> T? {
//		get {
//			return Gravity.convert(attribute) as T?
//		}
//	}
	
	private var _view: UIView?
	public var view: UIView {
		get {
			if _view == nil {
				processNode()
				// arch: we could move a bit of the outer conditionals up here and split processNode() into phases, just to split up the logic a bit and keep function bodies small
			}
			return _view ?? UIView() // probably want to think of something better here
		}
//		set(value) {
//			_view = value
//		}
	}
	
	// MARK: Attribute Helpers
	
	public var _model: AnyObject? // the data context; i prefer just "context" over "dataContext" as it's simple and it truly is what it means: the context to which the view applies; ooh but what about "model"? that fits much more perfectly into the MVC paradigm!
	public var model: AnyObject? {
		get {
			let value = _model ?? parentNode?.model // recursion is beautiful.
			if value == nil && parentNode == nil {
				return document.parentNode?.model // up a document (models pass through document barriers)
			}
			return value
		}
		set(value) {
			_model = value
		}
	}
	
	public var gravity: GravityDirection {
		get {
			return GravityDirection(getScopedAttribute("gravity") ?? "top left")
		}
	}
	
	public var color: UIColor {
		get {
			return Gravity.Conversion.convert(getScopedAttribute("color") ?? "#000")!
		}
	}
	
	// TODO: font should totally be a scoped parameter as well
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"] ?? "0")!
		}
	}
	
	public init(document: GravityDocument, parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.document = document
		self.nodeName = nodeName
		self.depth = (parentNode?.depth ?? 0) + 1
		self.attributes = attributes
		self.constraints = [String: NSLayoutConstraint]()
		super.init()
		self.parentNode = parentNode
//		self.ids = self.parentNode?.ids ?? [String: GravityNode]() // make sure this is copied by ref
	}
	
	public func isViewInstantiated() -> Bool {
		return _view != nil
	}
	
	public func isFilledAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		switch axis {
			case UILayoutConstraintAxis.Horizontal:
				let width = attributes["width"]?.lowercaseString
				if width == "fill" {
					return true
				} else if width != nil && width != "auto" { // "auto" is the default and is the same as not specifying
					return false
				}
				
				for childNode in childNodes {
					if childNode.isFilledAlongAxis(axis) {
						return true
					}
				}
				
				return false
			
			case UILayoutConstraintAxis.Vertical:
				let height = attributes["height"]?.lowercaseString
				if height == "fill" {
					return true
				} else if height != nil && height != "auto" { // "auto" is the default and is the same as not specifying
					return false
				}
				
				for childNode in childNodes {
					if childNode.isFilledAlongAxis(axis) {
						return true
					}
				}
				
				return false
		}
	}
	
	// TODO: shit, i'm not actually sure we want things like gravity and color to be scoped across documents... that actually seems wrong
	// i think *just* model.
	public func getScopedAttribute(attribute: String) -> String? {
		// why isn't this recursive? :/ i must have been tired. here you go:
		return attributes[attribute] ?? parentNode?.getScopedAttribute(attribute)
//		var currentNode: GravityNode? = self
//		while currentNode != nil {
//			if let value = currentNode!.attributes[attribute] {
//				return value
//			}
//			
//			currentNode = currentNode?.parentNode
//			
////			if currentNode == nil {
////				currentNode = document.parentNode
////			}
//		}
	}
	
	public override var description: String {
		get {
			var attributeStrings = [String]()
			for (key, var value) in attributes {
				// TODO: proper escaping for XML attribute value
				value = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(value)\"")
			}
			
			if childNodes.count > 0 {
				var childNodeStrings = [String]()
				for childNode in childNodes {
					childNodeStrings.append(childNode.description)
				}
				
				return "<\(nodeName)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
			} else {
				return "<\(nodeName) \(attributeStrings.joinWithSeparator(" "))/>"
			}
		}
	}
	
	public override var debugDescription: String {
		get {
			var attributeStrings = [String]()
			for (key, var value) in attributes {
				// TODO: proper escaping for XML attribute value
				value = value.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")
				attributeStrings.append("\(key)=\"\(value)\"")
			}
			
			if childNodes.count > 0 {
				var childNodeStrings = [String]()
				for childNode in childNodes {
					childNodeStrings.append(childNode.debugDescription)
				}
				
				let address = self.isViewInstantiated() ? "(\(unsafeAddressOf(view)))" : ""
				return "<\(nodeName)\(address)\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
			} else {
				return "<\(nodeName) \(attributeStrings.joinWithSeparator(" "))/>"
			}
		}
	}
	
	// this is unfrotunately a very monolithic function right now
	public func processNode() {
		let className = self.nodeName

		// childDocument is set in the pre-processing phase
		if let childDocument = childDocument {
			_view = childDocument.view // this will recursively load the child's view hierarchy
		}
		
		_view = _view ?? document.instantiateView(self)
		
		if _view == nil {
			if self.nodeName.containsString(".") {
			
				// This is a <Class.property> style node
				
				let attributeName = self.nodeName.componentsSeparatedByString(".").last // we actually only care about the last component; the first part is just by convention the class name
				if let parent = self.parentNode {
					// TODO: implement me
					// do we want a whole parent.setValueForAttribute method?
				}
			}
		}
		
		// MARK: - ATTRIBUTES -
		
		if _view == nil {
			NSLog("Error: Could not instantiate class ‘\(className)’.")
			return
		}
		
		view.gravityNode = self
		
		// should this part be moved to post-processing?
		
		for (attribute, _) in attributes {
			processAttribute(attribute)
		}
		
		// TODO: set a flag and disallow access to the "controller" property? can it even be accessed from processElement anyway? presumably only from GravityView, so it's probably not a big deal
		
		if let gravityElement = view as? GravityElement {
			if gravityElement.processElement?(self) == .Handled {
				return //view // handled
			}
		}
		
		// TODO: we may be better off actually setting a z-index on the views; this needs to be computed
		
		// we have to do a manual fucking insertion sort here, jesus gawd what the fuck swift?!! no stable sort in version 2.0 of a language??? how is that even remotely acceptable??
		// because, you know, i enjoy wasting my time writing sort algorithms!
		var sortedChildren = [GravityNode]()
		for childNode in childNodes {
//			let childNode = childNodes[i]
//			let zIndex = Int(childNode["zIndex"] ?? "0")! // really fucking awesome that swift can't fucking propagate nils. god fucking damnit why do i put up with this shit??
			// seriously though, what is the point of having all this optional shit without even taking advantage of what it can offer???
//			var lastChild: GravityNode = nil
			var handled = false
			for var i = 0; i < sortedChildren.count; i++ {
				if sortedChildren[i].zIndex > childNode.zIndex {
					sortedChildren.insert(childNode, atIndex: i)
					handled = true
					break
				}
			}
			if !handled {
				sortedChildren.append(childNode)
			}
		}

		// MARK: Default Child Handling
		
		for childNode in sortedChildren {
			view.addSubview(childNode.view)
			
			UIView.autoSetPriority(GravityPriorities.ViewContainment + Float(childNode.depth)) {
				// TODO: come up with better constraint identifiers than this
				// experimental: only apply these implicit constraints if the parent is not filled
				
				// i swear, childNode.parentNode should be self should it not???
				
				if !self.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) {
					childNode.constraints["view-left"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
					childNode.constraints["view-right"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
				}
				
				if !self.isFilledAlongAxis(UILayoutConstraintAxis.Vertical) {
					childNode.constraints["view-top"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
					childNode.constraints["view-bottom"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
				}
			}
						
			// TODO: we need to size a view to its contents by default (running into an issue where views are 0 sized)
			
//			 TODO: add support for margins via a margin and/or padding attribute

//			childNode.view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
			// TODO: unlock this when things are working:
			
			switch childNode.gravity.horizontal {
				case GravityDirection.Left:
					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
					break
				
				case GravityDirection.Center:
					childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
					break
				
				case GravityDirection.Right:
					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
					break
				
				default:
					break
			}
			
			switch childNode.gravity.vertical {
				case GravityDirection.Top:
					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
					break
				
				case GravityDirection.Middle:
					childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Horizontal)
					break
				
				case GravityDirection.Bottom:
					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
					break
				
				default:
					break
			}
		}
	}
	
	public func processAttribute(attribute: String) {
		guard let rawValue = attributes[attribute] else {
			return
		}
		
		var stringValue: String = rawValue
		var handled = false
		
		// 1. First-chance handling by plugins
		for plugin in document.plugins {
			var newValue = stringValue // value must be a String here
			// TODO: make sure the order here is correct!!
			if plugin.preprocessAttribute(self, attribute: attribute, value: &newValue) == .Handled {
				handled = true
			}
			stringValue = newValue // do this regardless of whether the call returns Handled or not
		}
		
		if handled {
			return
		}
		
		var value: AnyObject = stringValue
		
		// 2. Value transformation by plugins
		for plugin in document.plugins {
			var newValue: AnyObject = value
			if plugin.transformValue(self, attribute: attribute, input: stringValue, output: &newValue) == .Handled {
				value = newValue
				break
			}
		}
		
		if handled {
			return
		}
		
		// 3. GravityElement handling
		if let gravityElement = view as? GravityElement {
			// TODO: can we explicitly search the class chain by calling super.processAttribute, or at the very least call the UIView specific implementation?
			if gravityElement.processAttribute(self, attribute: attribute, value: value, stringValue: stringValue) == .Handled {
				return
			}
		}
		
		// 4. Post-process handling by plugins
		for plugin in document.plugins {
			plugin.postprocessAttribute(self, attribute: attribute, value: value)
		}
	}
	
	public func setAttribute(attribute: String, value: String) {
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
			attributes[attribute] = value
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
