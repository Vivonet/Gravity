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

// rename to GravityCore?
@available(iOS 9.0, *)
@objc public class Gravity: NSObject {
	static var extensions = [AnyClass]() // change to plugins
	static var converters = Dictionary<String, (String) -> AnyObject?>()
	static var styles = Dictionary<String, (UIView) -> ()>() // styles by class name, e.g. "UIButton" TODO: add support for style classes too, e.g. style="styleClass"
	// styles can also be used to do any post processing on an element after initialization; it doesn't have to be style related, though we should probably use plugins for that in general
	// i wonder if we can use this or a similar concept to set up data binding/templating (we'd probably need to track changes somehow)
	
	var rootElement: UIView? = nil
	var containerView = GravityView()
	
	// note: only works on @objc classes
	public override class func initialize() {
		
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
	
	public class func registerPlugin(type: AnyClass) {
		// add to registered extensions
		extensions.append(type)
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

@available(iOS 9.0, *)
@objc public class GravityNode: NSObject {
	public weak var parentNode: GravityNode?
	public var nodeName: String
	public var attributes: [String: String]
	public var childNodes = [GravityNode]()
	public var ids: [String: UIView]
	
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
	
	public init(parentNode: GravityNode?, nodeName: String, attributes: [String: String]) {
		self.parentNode = parentNode
		self.nodeName = nodeName
		self.attributes = attributes
		self.ids = self.parentNode?.ids ?? [String: UIView]() // make sure this is copied by ref
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
				
				return "<\(nodeName) \(attributeStrings.joinWithSeparator(" "))>\n\(childNodeStrings.joinWithSeparator("\n"))\n</\(nodeName)>"
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
		
		switch nodeName {
			// move this to a plugin or something
			case "H", "V":
				view = UIStackView()
//				self.addElement(element)
				if let stackView = view as? UIStackView {
					switch nodeName {
						case "H":
							className = "UIStackView" // maybe change this to 
							stackView.axis = UILayoutConstraintAxis.Horizontal
						
						case "V":
							className = "UIStackView"
							stackView.axis = UILayoutConstraintAxis.Vertical
						
						default:
							break // change to throw when i learn how to do that
					}
//					stackView.layoutMarginsRelativeArrangement = true//test

					// if the stackView is contained in a button it needs to be interaction-disabled in order for the button to accept clicks. i'm not sure why this is.
//					stackView.userInteractionEnabled = true
				}
			
			case "XIB":
				className = "UIView"
				// TODO
			
			default:
				break
		}
		
		if _view == nil {
			if let classType = NSClassFromString(className) as! UIView.Type? {
				view = classType.init()
				view.translatesAutoresizingMaskIntoConstraints = false // do we need this??
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
			
//				var handled = true

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
			
//			if currentContext is UIView {
				for type in Gravity.extensions {
					if type.processAttribute(self, attribute: propertyName, value: attributeValue) {
						continue
					}
				}
//			}
			
			switch propertyName {
				// FIXME: may want to set these with higher priority than default to avoid view/container bindings conflicting
				case "width":
//							NSLog("set width to %@", value)
					view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue))
//							if let view = currentContext as? UIView {
////								UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//									view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
////								})
//							}
				case "minWidth":
					view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
				case "maxWidth":
					view.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
				
				case "height":
					view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue))
				case "minHeight":
					view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
				case "maxHeight":
					view.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
				
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					view.layer.cornerRadius = CGFloat((attributeValue as NSString).floatValue)
					view.clipsToBounds = true // assume this is still needed
					break
						
						
				default:
					tryBlock {
						currentContext?.setValue(value, forKey: propertyName)
					}
//							} catch {
//								return UIView() // change to nil?
//							}
					break
			}
		}
		
		if let gravityElement = view as? GravityElement {
			if gravityElement.processElement?(self) == true {
				return view // handled
			}
		}
		
		for childNode in childNodes {
			view.addSubview(childNode.view)
			// should we set the Z-order of added subviews??
			
//			 TODO: add support for margins via a margins and/or padding attribute
			childNode.view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
			// unlock this when things are working:
			
//				switch gravity.horizontal {
//					case GravityDirection.Left:
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
//						break
//					
//					case GravityDirection.Center:
//						childNode.view.autoCenterHorizontallyInSuperview()
//						break
//					
//					case GravityDirection.Right:
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
//						break
//						
//					case GravityDirection.Wide:
//						// what priority should we use here?? does it matter?
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
//						break
//					
//					default:
//						break
//				}
//				
//				switch gravity.vertical {
//					case GravityDirection.Top:
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
//						break
//					
//					case GravityDirection.Middle:
//						childNode.view.autoCenterVerticallyInSuperview()
//						break
//					
//					case GravityDirection.Bottom:
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
//						break
//						
//					case GravityDirection.Wide:
//						// what priority should we use here?? does it matter?
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
//						childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
//						break
//					
//					default:
//						break
//				}
		}
		
		return view
	}
}

@available(iOS 9.0, *)
@objc public protocol GravityElement {
//	var gravity: Gravity { get set }
	func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool
	optional func processElement(node: GravityNode) -> Bool // return true if you handled your own child nodes, otherwise false to handle them automatically
}

// plugins will eventually let behavior at key points to be overridden/customized
@available(iOS 9.0, *)
@objc public protocol GravityPlugin {
//	var gravity: Gravity { get set }
	static func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool
//	optional func processElement(gravity: Gravity) // maybe rename this to something like elementCreated or postProcessElement

	// add plugin option to map element name/shorthand into instance. e.g. "H" -> instantiated UIStackView with the axis set
}

@objc public protocol GravityConverter {
	static func convert(value: String) -> AnyObject
}

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
		} else if valueParts.contains("wide") {
			gravity.horizontal = GravityDirection.Wide
		}
		
		if valueParts.contains("top") {
			gravity.vertical = GravityDirection.Top
		} else if valueParts.contains("mid") || valueParts.contains("middle") {
			gravity.vertical = GravityDirection.Middle
		} else if valueParts.contains("bottom") {
			gravity.vertical = GravityDirection.Bottom
		} else if valueParts.contains("tall") {
			gravity.vertical = GravityDirection.Tall
		}

		rawValue = gravity.rawValue
	}
	
	// horizontal gravity
	static let Left = GravityDirection(rawValue: 0b001)
	static let Right = GravityDirection(rawValue: 0b010)
	static let Center = GravityDirection(rawValue: 0b011) // or should left | right = wide?
	static let Wide = GravityDirection(rawValue: 0b100)
	
	// vertical gravity
	static let Top = GravityDirection(rawValue: 0b001 << 3)
	static let Bottom = GravityDirection(rawValue: 0b010 << 3)
	static let Middle = GravityDirection(rawValue: 0b011 << 3)
	static let Tall = GravityDirection(rawValue: 0b100 << 3)
	
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