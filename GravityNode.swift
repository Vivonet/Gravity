//
//  GravityNode.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-11.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *) // TODO: should we derive from NSTreeNode? that could handle all the traversal itself
// TODO: split these protocols into extensions to follow Swift conventions
@objc public class GravityNode: NSObject, GravityPlugin, CustomDebugStringConvertible {
	public var document: GravityDocument! // should this be weak?
	public weak var parentNode: GravityNode?
	public var nodeName: String
	public var depth: Int // the number of nodes deep this node is in the tree
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed table
	public var attributes: [String: String]
	public var constraints: [String: NSLayoutConstraint] // TODO: store constraints here based on their attribute name (width, minHeight, etc.)
	public var childNodes = [GravityNode]()
	public var subDocument: GravityDocument? = nil // if this node represents an external layout
//	public var ids: [String: GravityNode] // should we move this to GravityView? it would avoid us having to copy this between all nodes, and we can already access the gravityView from a node anyway
	
	subscript(attribute: String) -> String? {
		get {
			return attributes[attribute]
		}
	}
	// add Int-indexed subscript for child nodes too? or is that supported by SequenceType? probably we need CollectionType or something for that
	
//	subscript(attribute: String) -> T? {
//		get {
//			return Gravity.convert(attribute) as T?
//		}
//	}
	
	private var _view: UIView?
	public var view: UIView {
		get {
			if _view == nil {
				processNode()
//				if _view == nil {
//					_view = UIView()
//				}
			}
			return _view ?? UIView() // probably want to think of something better here
		}
//		set(value) {
//			_view = value
//		}
	}
	
	// MARK: Attribute Helpers
	
	public var gravity: GravityDirection {
		get {
			return GravityDirection(getScopedAttribute("gravity") ?? "top left")
		}
	}
	
	public var color: UIColor {
		get {
			return Gravity.convert(getScopedAttribute("color") ?? "#000")!
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
		self.parentNode = parentNode
		self.nodeName = nodeName
		self.depth = (parentNode?.depth ?? 0) + 1
		self.attributes = attributes
		self.constraints = [String: NSLayoutConstraint]()
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
	
	public func getScopedAttribute(attribute: String) -> String? {
		var currentNode: GravityNode? = self
		while currentNode != nil {
			if let value = currentNode!.attributes[attribute] {
				return value
			}
			currentNode = currentNode?.parentNode
		}
		return nil
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
	
	public func processNode() {
		let className = self.nodeName
		
		// first check to see if the node is an externed document
		if let subDoc = GravityDocument(name: self.nodeName) {
			for (attribute, rawValue) in attributes {
				if attribute.containsString(".") {
					let attributeParts = attribute.componentsSeparatedByString(".")
					let identifier = attributeParts.first!
					let property = attributeParts.last!
					
					if let subNode = subDoc.ids[identifier] {
						subNode.attributes[property] = rawValue
					}
					
					continue
				}
			}
			
			_view = subDoc.view // ok?
		}
		
		_view = _view ?? Gravity.instantiateView(self)
		
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
		
		// moving to pre-processing
		if let subDoc = GravityDocument(name: self.nodeName) {
			self.subDocument = subDoc
			
			NSLog("FOUND SUBDOCUMENT for note \(self.nodeName)")
			
			for (attribute, rawValue) in attributes {
				if attribute.containsString(".") {
					setAttribute(attribute, value: rawValue)
//					let attributeParts = attribute.componentsSeparatedByString(".")
//					let identifier = attributeParts.first!
//					let property = attributeParts.last!
//					
//					// what we actually need here is to split the first part off and call some recursive setAttribute function on the remainer parts
//					// so that it can dig more than one level deeper.
//					
//					if let subNode = subDoc.ids[identifier] {
//						subNode.attributes[property] = rawValue
//					}
//					
//					continue
				}
			}
			
			if let subView = subDoc.view {
				if _view == nil {
					_view = subView // ok??
				} else {
					view.addSubview(subView)
					
					// bind edges or anything??
				}
			}
		}
		
		// MARK: - ATTRIBUTES -
		
		if _view == nil {
			NSLog("Error: Could not instantiate class ‘\(className)’.")
			return
		}
		
		view.gravityNode = self
		
		for (attribute, rawValue) in attributes {
			// moved this up above gravity element because plugins should always have a chance to handle things first
			var handled = false
			for plugin in Gravity.plugins {
				if plugin.processAttribute?(self, attribute: attribute, value: rawValue) ?? false {
					handled = true
				}
			}
			if handled {
				continue
			}
			
			var propertyName = attribute
			var propertyType: String?
//			var currentContext: NSObject? = view
			var value: AnyObject? = rawValue

			if let gravityElement = view as? GravityElement {
				// TODO: can we explicitly search the class chain by calling super.processAttribute, or at the very least call the UIView specific implementation?
				if gravityElement.processAttribute(self, attribute: attribute, value: rawValue) {
					continue // handled
				}
			}
			
			// this is string.endsWith in swift. :| lovely.
			if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
//					if range.endIndex {
					propertyType = "UIColor" // bit of a hack because UIButton.backgroundColor doesn't seem to know its property class via inspection :/
//					}
			}

			// can we change this to just get the class name from the instance?
			let property = class_getProperty(NSClassFromString(className), attribute)
			if property != nil {
				if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
					if components.count >= 2 {
						propertyType = components[1]
//							NSLog("propertyType: %@", propertyType!)
					}
				}
			}
			if propertyType != nil {
				if let converter = Gravity.converters[propertyType!] {
					value = converter(rawValue)
				}
			}
			
			let sizeKeywords = ["fill", "auto"]
			
			// this might best be moved entirely into plugins, perhaps a core plugin
			switch propertyName {
				// TODO: may want to set these with higher priority than default to avoid view/container bindings conflicting
				// we should also capture these priorities as constants and put them all in one place for easier tweaking and balancing
				case "width":
//							NSLog("set width to %@", value)
					if !sizeKeywords.contains(rawValue) {
						UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
							self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((rawValue as NSString).floatValue))
//							if let view = currentContext as? UIView {
////								UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//									view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
////								})
//							}
						}
					}
				case "minWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((rawValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
				case "maxWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
						self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((rawValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
				
				case "height":
					if !sizeKeywords.contains(rawValue) {
						UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
							self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((rawValue as NSString).floatValue))
						}
					}
				case "minHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((rawValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
				case "maxHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((rawValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
				
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					view.layer.cornerRadius = CGFloat((rawValue as NSString).floatValue)
					view.clipsToBounds = true // assume this is still needed
					break
						
						
				default:
					if tryBlock({
						self.view.setValue(value, forKey: propertyName)
					}) != nil {
						NSLog("Warning: Property '\(propertyName)' not found on object \(view).")
					}
			}
		}
		
		// TODO: set a flag and disallow access to the "controller" property? can it even be accessed from processElement anyway? presumably only from GravityView, so it's probably not a big deal
		
		if let gravityElement = view as? GravityElement {
			if gravityElement.processElement?(self) == true {
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
		
//		var zIndexes = [Int: GravityNode]()
//		for childNode in childNodes {
//			let zIndex = Int(childNode["zIndex"] ?? "0")! // Really fucking stupid that Swift can't fucking propagate nils. God fucking damnit why do I put up with this shit??
//			zIndexes[zIndex] = childNode
//		}
//		let sortedChildren = childNodes.sort { (a, b) -> Bool in
//			return Int(a["zIndex"] ?? "0") < Int(b["zIndex"] ?? "0")
//		}

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
					
//				case GravityDirection.Wide:
//					// what priority should we use here?? does it matter?
//					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
//					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
//					break
				
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
					
//				case GravityDirection.Tall:
//					// what priority should we use here?? does it matter?
//					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
//					childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
//					break
				
				default:
					break
			}
		}
		
//		return view
	}
	
	public func setAttribute(attribute: String, value: String) {
		let attributeParts = attribute.componentsSeparatedByString(".")
		
		if attributeParts.count > 1 {
			if let subDoc = self.subDocument {
				let identifier = attributeParts.first!
				let remainder = attributeParts.suffixFrom(1).joinWithSeparator(".")
				if let child = subDoc.ids[identifier] {
					child.setAttribute(remainder, value: value)
				}
			} else {
				NSLog("Error: Cannot use dot notation for an attribute on a node that is not an externed Gravity file.")
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
	
	// MARK: GravityPlugin
	
	public static func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		let keywords = ["id", "zIndex", "gravity"]
		
		if keywords.contains(attribute) {
			return true
		}
		
		switch attribute {
			default:
				return false
		}
	}
	
	public static func processElement(node: GravityNode) {
		// TODO: minWidth, etc. should probably be higher priority than these so they can override fill size
//		let priority = Float(99)//99 - Float(node.depth)
		if node.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) {
			node.view.setContentHuggingPriority(GravityPriorities.FillSizeHugging, forAxis: UILayoutConstraintAxis.Horizontal)
			if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != UILayoutConstraintAxis.Horizontal {
				if node.view.superview is UIStackView {
					NSLog("Superview must be a vertical stack view")
				}
				UIView.autoSetPriority(GravityPriorities.FillSize - Float(node.depth)) {
//					node.view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: node.view.superview)
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left) // leading?
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right) // trailing?
				}
			}
		}
		
		if node.isFilledAlongAxis(UILayoutConstraintAxis.Vertical) {
			node.view.setContentHuggingPriority(GravityPriorities.FillSizeHugging, forAxis: UILayoutConstraintAxis.Vertical)
			if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != UILayoutConstraintAxis.Vertical {
				if node.view.superview is UIStackView {
					NSLog("Superview must be a horizontal stack view")
				}
				UIView.autoSetPriority(GravityPriorities.FillSize - Float(node.depth)) {
//					node.view.autoMatchDimension(ALDimension.Height, toDimension: ALDimension.Height, ofView: node.view.superview)
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
				}
			}
		}
	}
}
	
//extension GravityNode: SequenceType { // MARK: SequenceType
//	// http://stackoverflow.com/a/35279383/238948
//    public func generate() -> AnyGenerator<GravityNode> {
//        var stack : [GravityNode] = [self]
//        return anyGenerator {
//            if let next = stack.first {
//                stack.removeAtIndex(0)
////				stack.appendContentsOf(next.childNodes) // breadth-first
//                stack.insertContentsOf(next.childNodes, at: 0) // depth-first
//                return next
//            }
//            return nil
//        }
//    }
//}

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
