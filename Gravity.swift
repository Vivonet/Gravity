//
//  Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-20.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation
import ObjectiveC
import UIKit

// TODO: add identifiers for all added constraints

// don't change these values unless you know what you are doing! ;)
struct GravityPriorities {
/**
	The generic containment constraint of an auto-sizing UIView. These constraints ensure that the view will automatically size to fit its contents, but are low priority so as to be easily overridden.
*/

	static let FillSizeHugging: UILayoutPriority = 99
	static let ViewContainment: UILayoutPriority = 300
	static let FillSize: UILayoutPriority = 800
	static let ExplicitSize: UILayoutPriority = 800
}

// rename to GravityCore?
@available(iOS 9.0, *)
@objc public class Gravity: NSObject {
	static var plugins = [GravityPlugin.Type]() // plugins (currently) work statically as class methods, not on instances
	static var converters = Dictionary<String, (String) -> AnyObject?>()
	static var styles = Dictionary<String, (UIView) -> ()>() // styles by class name, e.g. "UIButton" TODO: add support for style classes too, e.g. style="styleClass"
	// styles can also be used to do any post processing on an element after initialization; it doesn't have to be style related, though we should probably use plugins for that in general
	// i wonder if we can use this or a similar concept to set up data binding/templating (we'd probably need to track changes somehow)
	
	var rootElement: UIView? = nil
//	var containerView = GravityView()
	
	// note: only works on @objc classes
	public override class func initialize() {
	
		registerPlugin(GravityNode)
		registerPlugin(GravityDocument) // does this still make sense?
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
		}, forType: UIFont.self)
		
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
		}, forType: UIColor.self)
	}
	
//	public class func start(xml: String) {
//	
//	}
	
	// really wish there were a way to actually set the app's window property
	public class func start(name: String) -> UIWindow {
		let window = UIWindow(frame: UIScreen.mainScreen().bounds)
//		let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
//		var exampleViewController: ExampleViewController = mainStoryboard.instantiateViewControllerWithIdentifier("ExampleController") as! ExampleViewController
//		let vc = 
//		UIApplication.sharedApplication().delegate.window = UIWindow(frame: UIScreen.mainScreen().bounds)

		window.rootViewController = GravityViewController(name: name)

		window.makeKeyAndVisible()

		return window
	}
	
	public class func new<T: UIView>(type: T.Type, model: AnyObject? = nil) -> T? {
		return self.new("\(type)") as! T? // verify
	}
	
	public class func new<T: UIView>(name: String, model: AnyObject? = nil) -> T? {
		if let document = GravityDocument(name: name, model: model) {
			return document.view as! T? // verify
		}
		
		return nil
	}
	
	public class func instantiate(name: String) -> UIView? {
		return new(name)
	}
	
	// is this good here?
	public class func instantiateView(node: GravityNode) -> UIView? {
		var view: UIView? = nil
		
		for plugin in plugins {
			if let view = plugin.instantiateElement?(node) {
				return view
			}
		}
		
		if let type = NSClassFromString(node.nodeName) as! UIView.Type? {
			tryBlock {
				view = type.init()
				view?.translatesAutoresizingMaskIntoConstraints = false // do we need this??
			}
			
			// TODO: determine if the instance is an instance of UIView or UIViewController and handle the latter by embedding a view controller
			
			// TODO: should we set clipsToBounds for views by default?
		}
		
		return view
	}
	
	public class func registerPlugin(type: GravityPlugin.Type) {
		// add to registered plugins
		plugins.append(type)
	}
	
	public class func convert<T: AnyObject>(value: String) -> T? {
		if let converter = converters["\(T.self)"] {
			return converter(value) as? T
		} else {
			return nil
		}
	}
	
	// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time
//	public class func constructFromFile(filename: String) -> GravityView? {
//		let gravityView = GravityView(name: filename)
////		gravityView.filename = filename
//		return gravityView
//	}
	
//	public class func constructFromXML(xml: String) -> GravityView? {
//		let gravityView = GravityView(xml: xml)
//		gravityView.xml = xml
//		return gravityView
//	}
	
//////		let fitSize = rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
	
	public class func registerConverter(converter: (String) -> AnyObject?, forType type: AnyClass) {
		Gravity.converters["\(type)"] = converter
	}
	
	public class func registerStyle(style: (UIView) -> (), forType type: AnyClass) {
		Gravity.styles["\(type)"] = style
	}
	
	private func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
}

//// MARK: -
//
//@available(iOS 9.0, *)
//@objc public class GravityDocument: NSObject {
//	private var nodeStack = [GravityNode]()
//	private var widthIdentifiers = [String: [GravityNode]]()
//	public var rootNode: GravityNode?
//	public var ids: [String : UIView] = [:]
//	
//	public var controller: NSObject? = nil {
//		didSet {
//			controllerChanged()
//		}
//	}
//
//	@IBInspectable public var xml: String = "" {
//		didSet {
//			parseXML()
//		}
//	}
//	
//	
//}

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
	// add a method to bind an id? or just use processAttribute?
}

// MARK: -

// plugins let behavior at key points be overridden/customized
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