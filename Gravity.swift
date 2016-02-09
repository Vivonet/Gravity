//
//  Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-20.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation
import ObjectiveC
import UIKit

// TODO: add identifiers for all added constraints

struct GravityConstraintPriorities {
/**
	The generic containment constraint of an auto-sizing UIView. These constraints ensure that the view will automatically size to fit its contents, but are low priority so as to be easily overridden.
*/
	static let ViewContainment: UILayoutPriority = 300
}

// rename to GravityCore?
@available(iOS 9.0, *)
@objc public class Gravity: NSObject {
	static var plugins = [AnyClass]() // plugins (currently) work statically as class methods, not on instances
	static var converters = Dictionary<String, (String) -> AnyObject?>()
	static var styles = Dictionary<String, (UIView) -> ()>() // styles by class name, e.g. "UIButton" TODO: add support for style classes too, e.g. style="styleClass"
	// styles can also be used to do any post processing on an element after initialization; it doesn't have to be style related, though we should probably use plugins for that in general
	// i wonder if we can use this or a similar concept to set up data binding/templating (we'd probably need to track changes somehow)
	
	var rootElement: UIView? = nil
	var containerView = GravityView()
	
	// note: only works on @objc classes
	public override class func initialize() {
	
		registerPlugin(GravityNode)
		registerPlugin(GravityView)
		registerPlugin(UIStackView)
		
		// MARK: - BUILT-IN CONVERTERS -
		// TODO: move these into a plugin or external file
		
		registerConverter({ (value: String) -> NSObject? in
			let valueParts = value.componentsSeparatedByString(" ")
			var font: UIFont?
			let size = CGFloat((valueParts.last! as NSString).floatValue)
			if valueParts.count >= 2 {
				var weight: CGFloat
				switch valueParts[1].lowercaseString {
					case "ultralight":
						weight = UIFontWeightUltraLight
					case "thin":
						weight = UIFontWeightThin
					case "light":
						weight = UIFontWeightLight
					case "regular":
						weight = UIFontWeightRegular
					case "medium":
						weight = UIFontWeightMedium
					case "semibold":
						weight = UIFontWeightSemibold
					case "bold":
						weight = UIFontWeightBold
					case "heavy":
						weight = UIFontWeightHeavy
					case "black":
						weight = UIFontWeightBlack
					default:
						weight = UIFontWeightRegular
				}
				
				if valueParts.first!.lowercaseString == "system" {
					font = UIFont.systemFontOfSize(size, weight: weight)
				} else {
					font = UIFont(name: valueParts.prefix(valueParts.count - 1).joinWithSeparator("-"), size: size)
				}				
			} else {
				if valueParts.first!.lowercaseString == "system" {
					font = UIFont.systemFontOfSize(size)
				} else {
					font = UIFont(name: valueParts.first!, size: size)
				}
			}
			return font
		}, forTypeName: "UIFont")
		
		registerConverter({ (var value: String) -> AnyObject? in
			value = value.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet)
			var int = UInt32()
			NSScanner(string: value).scanHexInt(&int)
			let a, r, g, b: UInt32
			switch value.characters.count {
				case 3: // RGB (12-bit)
					(a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
				case 6: // RGB (24-bit)
					(a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
				case 8: // ARGB (32-bit)
					(r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
				default:
					return UIColor.clearColor()
			}
			return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
		}, forTypeName: "UIColor")
	}
	
//	public class func start(xml: String) {
//	
//	}
	
	// returns Bool so it can be returned from applicationDidFinishLaunchingWithOptions
	public class func start(filename: String) -> UIWindow {
		var window = UIWindow(frame: UIScreen.mainScreen().bounds)
//		let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//		var exampleViewController: ExampleViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ExampleController") as! ExampleViewController
//		let vc = 
//		UIApplication.sharedApplication().delegate.window = UIWindow(frame: UIScreen.mainScreen().bounds)

		window.rootViewController = GravityViewController(filename: filename)

		window.makeKeyAndVisible()

		return window
	}
	
	public class func registerPlugin(type: AnyClass) {
		// add to registered plugins
		plugins.append(type)
	}
	
	// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time
	public class func constructFromFile(filename: String) -> GravityView? {
		let gravityView = GravityView()
		gravityView.filename = filename
		return gravityView
	}
	
	public class func constructFromXML(xml: String) -> GravityView? {
		let gravityView = GravityView()
		gravityView.xml = xml
		return gravityView
	}
	
//////		let fitSize = rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
	
	public class func registerConverter(converter: (String) -> AnyObject?, forTypeName typeName: String) {
		Gravity.converters[typeName] = converter
	}
	
	public class func registerStyle(style: (UIView) -> (), forTypeName typeName: String) {
		Gravity.styles[typeName] = style
	}
	
	func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
}

// MARK: -

@available(iOS 9.0, *) // TODO: should we derive from NSTreeNode? that could handle all the traversal itself
@objc public class GravityNode: NSObject, GravityPlugin, CustomDebugStringConvertible {
	public weak var parentNode: GravityNode?
	public weak var gravityView: GravityView?
	public var nodeName: String
	public var depth: Int // the number of nodes deep this node is in the tree
	// TODO: add a computed relativeDepth property that returns a value between 0-1 based on the maximum depth of the parsed table
	public var attributes: [String: String]
	public var constraints: [String: NSLayoutConstraint] // TODO: store constraints here based on their attribute name (width, minHeight, etc.)
	public var childNodes = [GravityNode]()
	public var ids: [String: UIView] // should we move this to GravityView? it would avoid us having to copy this between all nodes, and we can already access the gravityView from a node anyway
	
	subscript(attribute: String) -> String? {
		get {
			return attributes[attribute]
		}
	}
	// add Int subscript for child nodes too?
	
	private var _view: UIView?
	public var view: UIView {
		get {
			if _view == nil {
				processNode()
				if _view == nil {
					_view = UIView() // probably want to think of something better here
				}
			}
			return _view!
		}
		set(value) {
			_view = value
		}
	}
	
	// MARK: Attribute Helpers
	
	public var gravity: GravityDirection {
		get {
			return GravityDirection(getScopedAttribute("gravity") ?? "top left")
		}
	}
	
	public var color: UIColor {
		get {
			let converter = Gravity.converters["UIColor"]!
			return converter(getScopedAttribute("color") ?? "#000") as! UIColor
		}
	}
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"] ?? "0")!
		}
	}
	
	public init(gravityView: GravityView, parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.gravityView = gravityView
		self.parentNode = parentNode
		self.nodeName = nodeName
		self.depth = (parentNode?.depth ?? 0) + 1
		self.attributes = attributes
		self.constraints = [String: NSLayoutConstraint]()
		self.ids = self.parentNode?.ids ?? [String: UIView]() // make sure this is copied by ref
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
				
				return "<\(nodeName)(\(unsafeAddressOf(view)))\(attributeStrings.count > 0 ? " " : "")\(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
			} else {
				return "<\(nodeName) \(attributeStrings.joinWithSeparator(" "))/>"
			}
		}
	}
	
	// do we need to return if our job is to set view? what about return Bool if the node was fully handled (children and all)
	public func processNode() -> UIView {
		// TODO: check registered element name index and see if there is an associated class
//		var element: UIView?
		var className = nodeName
		
		// TODO: add plugin hook, move H, V into a plugin
		for plugin in Gravity.plugins {
			_view = plugin.instantiateElement?(self)
			if _view != nil {
				// TODO: either set className here or change it to figure it out from the instance (better)
				break
			}
		}
		
//		switch nodeName {
//			// move this to a plugin or something
//			case "H", "V":
//				view = UIStackView()
////				self.addElement(element)
//				if let stackView = view as? UIStackView {
//					switch nodeName {
//						case "H":
//							className = "UIStackView" // maybe change this to 
//							stackView.axis = UILayoutConstraintAxis.Horizontal
//						
//						case "V":
//							className = "UIStackView"
//							stackView.axis = UILayoutConstraintAxis.Vertical
//						
//						default:
//							break // change to throw when i learn how to do that
//					}
////					stackView.layoutMarginsRelativeArrangement = true//test
//
//					// if the stackView is contained in a button it needs to be interaction-disabled in order for the button to accept clicks. i'm not sure why this is.
////					stackView.userInteractionEnabled = true
//				}
//			
//			case "XIB":
//				className = "UIView"
//				// TODO
//			
//			default:
//				break
//		}
		
		if _view == nil {
			if let classType = NSClassFromString(className) as! UIView.Type? {
				view = classType.init()
				view.translatesAutoresizingMaskIntoConstraints = false // do we need this??
				
				// TODO: determine if the instance is an instance of UIView or UIViewController and handle the latter by embedding a view controller
				
				// TODO: should we set clipsToBounds for views by default?
			}
		}
		
		// MARK: - ATTRIBUTES -
		
		for (key, attributeValue) in attributes {
			switch key { // special override cases (these pseudo-attributes take precedence over any class-specific attributes)
				case "id":
					self.ids[attributeValue] = view
					// TODO: add these to a controller object
					continue
				
				default:
					break
			}
			
			// TODO: add plugin hook
			
			var propertyName = key
			var propertyType: String?
			var currentContext: NSObject? = view
			var value: AnyObject? = attributeValue
			
			// if elementName contains a '.', treat everything following the dot as a propertyAccessor and instantiate its contents (or should we just pass this as keyPath?)
			if key.containsString(".") {
				let keyParts = key.componentsSeparatedByString(".")
				
				for var i = 0; i < keyParts.count; i++ {
					let part = keyParts[i]
					NSLog("part: %@", part)
					if i < keyParts.count - 1 {
						currentContext = currentContext?.valueForKey(part) as? NSObject
					} else {
//							currentContext?.setValue(value, forKey: part)
						propertyName = part
					}
				}
//					continue
			}
			
			// moved this up above gravity element because plugins should always have a chance to handle things first
			var handled = false
			for plugin in Gravity.plugins {
				if plugin.processAttribute?(self, attribute: propertyName, value: attributeValue) ?? false {
					handled = true
				}
			}
			if handled {
				continue
			}

			if let gravityElement = currentContext as? GravityElement {
				// TODO: can we explicitly search the class chain by calling super.processAttribute, or at the very least call the UIView specific implementation?
				if gravityElement.processAttribute(self, attribute: propertyName, value: attributeValue) {
					continue // handled
				}
			}
			
			// this is string.endsWith in swift. :| lovely.
			if propertyName.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == propertyName.endIndex {
//					if range.endIndex {
					propertyType = "UIColor" // bit of a hack because UIButton.backgroundColor doesn't seem to know its property class via inspection :/
//					}
			}

			// can we change this to just get the class name from the instance?
			let property = class_getProperty(NSClassFromString(className), propertyName)
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
					value = converter(attributeValue)
				}
			}
			
			switch propertyName {
				// TODO: may want to set these with higher priority than default to avoid view/container bindings conflicting
				// we should also capture these priorities as constants and put them all in one place for easier tweaking and balancing
				case "width":
//							NSLog("set width to %@", value)
					if attributeValue.lowercaseString != "fill" {
						constraints[propertyName] = view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue))
//							if let view = currentContext as? UIView {
////								UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//									view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
////								})
//							}
					}
				case "minWidth":
						constraints[propertyName] = view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
				case "maxWidth":
					UIView.autoSetPriority(800) { // TODO: these have to be higher priority than the normal and fill binding to parent edges
						self.constraints[propertyName] = self.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
				
				case "height":
					if attributeValue.lowercaseString != "fill" {
						constraints[propertyName] = view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue))
					}
				case "minHeight":
					constraints[propertyName] = view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
				case "maxHeight":
					constraints[propertyName] = view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
				
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					view.layer.cornerRadius = CGFloat((attributeValue as NSString).floatValue)
					view.clipsToBounds = true // assume this is still needed
					break
						
						
				default:
					if tryBlock({
						currentContext?.setValue(value, forKey: propertyName)
					}) != nil {
						NSLog("Warning: Property '\(propertyName)' not found on object \(currentContext!).")
					}
			}
		}
		
		// TODO: set a flag and disallow access to the "controller" property? can it even be accessed from processElement anyway? presumably only from GravityView, so it's probably not a big deal
		
		if let gravityElement = view as? GravityElement {
			if gravityElement.processElement?(self) == true {
				return view // handled
			}
		}
		
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
			
			UIView.autoSetPriority(GravityConstraintPriorities.ViewContainment + Float(childNode.depth)) {
				// TODO: come up with better constraint identifiers than this
				// experimental: only apply these implicit constraints if the parent is not filled
				if childNode.parentNode?.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) != true {
					childNode.constraints["view-left"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
					childNode.constraints["view-right"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
				}
				
				if childNode.parentNode?.isFilledAlongAxis(UILayoutConstraintAxis.Vertical) != true {
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
		
		return view
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
		switch attribute {
			case "gravity":
				return true
			
			default:
				return false
		}
	}
	
	public static func processElement(node: GravityNode) {
		// TODO: minWidth, etc. should probably be higher priority than these so they can override fill size
		let priority = Float(99)//99 - Float(node.depth)
		if node.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) {
			NSLog("Priority: \(priority)")
			node.view.setContentHuggingPriority(priority, forAxis: UILayoutConstraintAxis.Horizontal)
			if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != UILayoutConstraintAxis.Horizontal {
				if node.view.superview is UIStackView {
					NSLog("Superview must be a vertical stack view")
				}
				UIView.autoSetPriority(800 - Float(node.depth)) {
//					node.view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: node.view.superview)
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Leading)
					node.view.autoPinEdgeToSuperviewEdge(ALEdge.Trailing)
				}
			}
		}
		
		if node.isFilledAlongAxis(UILayoutConstraintAxis.Vertical) {
			node.view.setContentHuggingPriority(priority, forAxis: UILayoutConstraintAxis.Vertical)
			if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != UILayoutConstraintAxis.Vertical {
				if node.view.superview is UIStackView {
					NSLog("Superview must be a horizontal stack view")
				}
				UIView.autoSetPriority(800 - Float(node.depth)) {
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

extension GravityNode: SequenceType {
	public func generate() -> AnyGenerator<GravityNode> {
		var childGenerator = childNodes.generate()
		var subGenerator : AnyGenerator<GravityNode>?
		var returnedSelf = false

		return anyGenerator {
			if let subGenerator = subGenerator,
				let next = subGenerator.next() {
					return next
			}

			if let child = childGenerator.next() {
				subGenerator = child.generate()
				return subGenerator!.next()
			}
			if !returnedSelf {
				returnedSelf = true
				return self
			}


			return nil
		}
	}
}

//	public func generate() -> AnyGenerator<GravityNode> {
//		var childrenGenerator = childNodes.generate()
//		var childGenerator: AnyGenerator<GravityNode>? = nil // the recursive generator
//		var lastChild: GravityNode? = nil
//		var returnedSelf = false
//		
//		return anyGenerator {
//			while true {
//				if childGenerator == nil {
//					lastChild = childrenGenerator.next()
//					if lastChild == nil {
//						break
//					}
//				}
//				
//				if lastChild != nil && childGenerator == nil {
//					childGenerator = lastChild!.generate()
//				}
//				
//				if childGenerator != nil {
//					let recursiveNext = childGenerator!.next()
//					if recursiveNext != nil {
//						return recursiveNext
//					} else {
//						childGenerator = nil
//					}
//				}
//			}
//			
//			if !returnedSelf {
//				returnedSelf = true
//				return self
//			} else {
//				return nil // ends here
//			}
//		}
//	}

// MARK: -

@available(iOS 9.0, *)
@objc public protocol GravityElement { // MARK: GravityElement
	func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool
	optional func processElement(node: GravityNode) -> Bool // return true if you handled your own child nodes, otherwise false to handle them automatically
	optional func connectController(node: GravityNode, controller: NSObject) // return?
}

// MARK: -

// plugins will eventually let behavior at key points to be overridden/customized
@available(iOS 9.0, *)
@objc public protocol GravityPlugin { // MARK: GravityPlugin
	// TODO: we should use a different method name from GravityElement; even though this one is static, it is confusing
	optional static func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool // i don't think we need to return bool here; plugins should always get a chance to read the attribute regardless of whether they have been handled or not
	// actually, what we want is for every plugin to get a chance to handle the attribute, BUT we could also allow them to return true to mean that it was handled and therefore don't process it any further
	

	// add plugin option to map element name/shorthand into instance. e.g. "H" -> instantiated UIStackView with the axis set
	optional static func instantiateElement(node: GravityNode) -> UIView? // note: we should consider preventing access to the "view" property here; also you should not use the attributes of the node to fill-in the object's info *unless* you need the attribute in a constructor (e.g. UICollectionView)
	optional static func processElement(node: GravityNode) // maybe rename this to something like elementCreated or postProcessElement
	// add a hook for when the document is completely parsed
}

@objc public protocol GravityConverter {
	static func convert(value: String) -> AnyObject
}

// MARK: -

public struct GravityDirection: OptionSetType {
	// we could also just do this with two separate member variables
	public var rawValue: Int = 0
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	init(_ textValue: String) {
		let valueParts = textValue.lowercaseString.componentsSeparatedByString(" ") // allow to be in the form "top-left" or "top left"
		var gravity = GravityDirection()
//			var vGravity: GravityDirection
		if valueParts.contains("left") {
			gravity.horizontal = GravityDirection.Left
		} else if valueParts.contains("center") {
			gravity.horizontal = GravityDirection.Center
		} else if valueParts.contains("right") {
			gravity.horizontal = GravityDirection.Right
		} //else if valueParts.contains("wide") {
//			gravity.horizontal = GravityDirection.Wide
//		}
		
		if valueParts.contains("top") {
			gravity.vertical = GravityDirection.Top
		} else if valueParts.contains("mid") || valueParts.contains("middle") {
			gravity.vertical = GravityDirection.Middle
		} else if valueParts.contains("bottom") {
			gravity.vertical = GravityDirection.Bottom
		} //else if valueParts.contains("tall") {
//			gravity.vertical = GravityDirection.Tall
//		}

		rawValue = gravity.rawValue
	}
	
	// horizontal gravity
	static let Left = GravityDirection(rawValue: 0b001)
	static let Right = GravityDirection(rawValue: 0b010)
	static let Center = GravityDirection(rawValue: 0b011) // or should left | right = wide?
//	static let Wide = GravityDirection(rawValue: 0b100)
	
	// vertical gravity
	static let Top = GravityDirection(rawValue: 0b001 << 3)
	static let Bottom = GravityDirection(rawValue: 0b010 << 3)
	static let Middle = GravityDirection(rawValue: 0b011 << 3)
//	static let Tall = GravityDirection(rawValue: 0b100 << 3)
	
	func hasHorizontal() -> Bool {
		return horizontal.rawValue > 0
	}
	var horizontal: GravityDirection {
		get {
			return GravityDirection(rawValue: rawValue & 0b111)
		}
		set(value) {
			rawValue = vertical.rawValue | (value.rawValue & 0b111)
		}
	}
	
	func hasVertical() -> Bool {
		return vertical.rawValue > 0
	}
	var vertical: GravityDirection {
		get {
			return GravityDirection(rawValue: rawValue & (0b111 << 3))
		}
		set(value) {
			rawValue = horizontal.rawValue | (value.rawValue & (0b111 << 3))
		}
	}
}

enum GravityError: ErrorType {
	case InvalidParse
}