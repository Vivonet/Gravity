//
//  Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-20.
//  Copyright © 2016 Vivonet. All rights reserved.
//

import Foundation
import UIKit

// TODO: add identifiers for all added constraints

public struct GravityDirection: OptionSetType {
	// we could also just do this with two separate member variables
	public var rawValue: Int = 0
	
	public init(rawValue: Int) {
		self.rawValue = rawValue
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
	
//	func isLeft() -> Bool {
//		return horizontal == GravityDirection.Left
//	}
//	
//	func isTop() -> Bool {
//		return vertical == GravityDirection.Top
//	}
}

enum GravityError: ErrorType {
	case InvalidParse
}

@available(iOS 9.0, *)
@objc public class Gravity: NSObject, NSXMLParserDelegate {

	static var converters = Dictionary<String, (String) -> AnyObject?>()
	static var styles = Dictionary<String, (UIView) -> ()>() // styles by class name, e.g. "UIButton" TODO: add support for style class names too, e.g. style="styleClass"
	// styles can also be used to do any post processing on an element after initialization; it doesn't have to be style related
	// i wonder if we can use this or a similar concept to set up data binding/templating (we'd probably need to track changes somehow)

	var elementStack = [UIView]()
	var attributeStack = [[String : String]]()
	var gravityStack = [GravityDirection]()
	var colorStack = [UIColor]() // can we do a stack of styles? i want something like CSS
	var elementMetadata = Dictionary<UIView, GravityMetadata>() // does this actually work?? we don't have to wrap UIView in something?
	// actually do we need this to be a stack? since all elements are unique we could do this all in one dictionary, but we'd need to be sure to remove elements appropriately
	
	var rootElement: UIView? = nil
	var containerView = GravityView()
	
	// note: only works on @objc classes
	public override class func initialize() {
		
		// MARK: - BUILT-IN CONVERTERS -
		
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
	
	override init() {
		gravityStack.append([GravityDirection.Top, GravityDirection.Left])
		colorStack.append(UIColor.blackColor())
	}
	
	public class func constructFromFile(filename: String) -> GravityView? {
		let gravity = Gravity()
		return gravity.constructFromFile(filename)
	}
	
	public class func constructFromXML(xml: String) -> GravityView? {
		return Gravity().constructFromXML(xml)
	}
	
	public func constructFromFile(filename: String) -> GravityView? {
		// if filename doesn't end with .xml (and can't be found as specified) append .xml
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(filename, isDirectory: false)
		do {
			return try constructFromXML(String(contentsOfURL: url, encoding: NSUTF8StringEncoding))
		} catch {
			return nil
		}
	}
	
	// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time
	public func constructFromXML(xml: String) -> GravityView? {
		if let data = xml.dataUsingEncoding(NSUTF8StringEncoding) {
			let parser = NSXMLParser(data: data)
			parser.delegate = self
			if !parser.parse() {
				return nil
			}
		}
//		let containerView = GravityView()
		containerView.addSubview(rootElement!)
//		rootElement?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
		rootElement?.autoPinEdgeToSuperviewEdge(ALEdge.Top)
		rootElement?.autoPinEdgeToSuperviewEdge(ALEdge.Left)
//		gravity.rootElement?.autoCenterInSuperview()
		containerView.autoSize()
//		containerView.layoutIfNeeded()
//		containerView.updateConstraints() // need this?
//		// TODO: figure out what size to pass here
//		// perhaps we should write this as an extension on UIView and then we can simply check the size of the parent view
//		// we should also allow things like a maxWidth, maxHeight to be specified on the root element in the xml file
//		let fitSize = rootElement?.frame.size
////		let fitSize = rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
//		containerView.frame.size.width = (fitSize?.width)!
//		containerView.frame.size.height = (fitSize?.height)!
		
		return containerView
	}
	
	public class func registerConverter(converter: (String) -> AnyObject?, forTypeName typeName: String) {
//		if Gravity.converters[className] == nil {
//			Gravity.converters[className] = Array<(String) -> NSObject?>()
//		}
		Gravity.converters[typeName] = converter
	}
	
	public class func registerStyle(style: (UIView) -> (), forTypeName typeName: String) {
		Gravity.styles[typeName] = style
	}
	
	func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, var attributes attributeDict: [String : String]) {
		var className = elementName
		attributeStack.append(attributeDict)
		
		// MARK: - GLOBAL ATTRIBUTES -
		
		// does if var work like if let?
		if var gravityValue = attributeDict["gravity"] {
			gravityValue = gravityValue.lowercaseString
			var gravity = GravityDirection()
//			var vGravity: GravityDirection
			let valueParts = gravityValue.stringByReplacingOccurrencesOfString("-", withString: " ").componentsSeparatedByString(" ") // allow to be in the form "top-left" or "top left"
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

			if !gravity.hasHorizontal() {
				gravity.horizontal = gravityStack.last!.horizontal
			}
			
			if !gravity.hasVertical() {
				gravity.vertical = gravityStack.last!.vertical
			}

			gravityStack.append(gravity)
		}
		if let colorValue = attributeDict["color"] {
			let converter = Gravity.converters["UIColor"]!
			let color = converter(colorValue) as! UIColor
			colorStack.append(color)
			attributeDict.removeValueForKey("color")//test
		}
		
		// MARK: - ELEMENT PRE-PROCESSING -
		
		var element: UIView?
		switch elementName {
			case "H", "V":
				element = UIStackView()
//				self.addElement(element)
				if let stackView = element as? UIStackView {
					switch elementName {
						case "H":
							className = "UIStackView"
							stackView.axis = UILayoutConstraintAxis.Horizontal
							// FIXME: we need to handle the gravity of manually-created UIStackViews; make this more universal, perhaps just set the classname (and axis??) and construct it below
//							stackView.alignment = gravityStack.last!.vertical == GravityDirection.Top ? UIStackViewAlignment.Top : UIStackViewAlignment.Bottom
//							switch gravityStack.last!.vertical {
//								case GravityDirection.Top:
//									stackView.alignment = UIStackViewAlignment.Top
//									break
//								case GravityDirection.Middle:
//									stackView.alignment = UIStackViewAlignment.Center
//									break
//								case GravityDirection.Bottom:
//									stackView.alignment = UIStackViewAlignment.Bottom
//									break
//								case GravityDirection.Tall:
//									stackView.alignment = UIStackViewAlignment.Fill
//									break
//							}
						
						case "V":
							className = "UIStackView"
							stackView.axis = UILayoutConstraintAxis.Vertical
//							stackView.alignment = gravityStack.last!.horizontal == GravityDirection.Left ? UIStackViewAlignment.Leading : UIStackViewAlignment.Trailing
							
						default:
							break // change to throw when i learn how to do that
					}
//					stackView.layoutMarginsRelativeArrangement = true//test
//					stackView.alignment = 

					// if the stackView is contained in a button it needs to be interaction-disabled in order for the button to accept clicks. i'm not sure why this is.
//					stackView.userInteractionEnabled = true
				}
			
			case "XIB":
				className = "UIView"
				// TODO
			
			default:
				break
		}

		if element == nil {
			if let classType = NSClassFromString(className) as! UIView.Type? {
				element = classType.init()
				
			}
		}
		
		// how do we handle manually created stackviews with an axis property??
		
		
		// add element to view and stack
		if element != nil {
			if let top = elementStack.last {
				if let stackView = top as? UIStackView {
					stackView.addArrangedSubview(element!)
					element!.setContentHuggingPriority(750 - Float(elementStack.count), forAxis: stackView.axis)
					
	//				element.autoPinEdgeToSuperviewEdge(ALEdge.Left)
	//				element.autoPinEdgeToSuperviewEdge(ALEdge.Top)
				} else {
					top.addSubview(element!)
	//				element.autoCenterInSuperview()
					// TODO: add support for margins via a margins and/or padding attribute
					element!.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
				}
			} else if ( rootElement == nil ) {
				rootElement = element
			} else {
				// throw
			}
			elementStack.append(element!)
			elementMetadata[element!] = GravityMetadata()
			
			if let styler = Gravity.styles[className] {
				styler(element!)
			}
		}
		
		// MARK: - ATTRIBUTES -
		
		// we eventually want to interpret these, so things like textColor can contain values like #0099cc or "blue"
		// we should check the property type of the property we are setting and look up a registered converter; we can include a bunch of built-in converters for obvious things like UIColor, UIFont etc.
		for (key, attributeValue) in attributeDict {
			if let element = elementStack.last {
				switch key { // special override cases (these pseudo-attributes take precedence over any class-specific attributes)
					case "id":
						containerView.ids[attributeValue] = element
						continue
					
					case "shrinks":
						// TODO: assert/ensure we are contained within a stack view
						elementMetadata[element]!.shrinks = Int(attributeValue) ?? 0
						continue
						
					case "grows":
						// TODO: assert/ensure we are contained within a stack view
						elementMetadata[element]!.grows = Int(attributeValue) ?? 0
						continue
					
					default:
						break
				}
				
				var propertyName = key
				var propertyType: String?
				var currentContext: NSObject? = element
				var value: AnyObject? = attributeValue
				
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
				
				if let label = currentContext as? UILabel {
					switch propertyName {
						case "wrap":
							if (attributeValue as NSString).boolValue {
								label.numberOfLines = 0
							}
							continue
						
//						case "textAlignment":
						
						default:
							break
					}
				} else if let button = currentContext as? UIButton {
					switch propertyName {
						case "title":
							// TODO: we should replace this with css-style styles, with styles for different button states
							button.setTitle(attributeValue, forState: UIControlState.Normal)
							continue
						
						default:
							break
					}
				}
				else if let imageView = currentContext as? UIImageView {
					switch propertyName {
						case "image":
							imageView.image = UIImage(named: attributeValue)?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
							continue
							
						default:
							break
					}
				} else if let stackView = currentContext as? UIStackView {
					switch propertyName {
						case "axis":
							switch attributeValue.lowercaseString {
								case "horizontal", "h":
									stackView.axis = UILayoutConstraintAxis.Horizontal
									break
								
								case "vertical", "v":
									stackView.axis = UILayoutConstraintAxis.Vertical
									break
								
								default:
									break
							}
							break
						
						case "alignment":
							switch attributeValue.lowercaseString {
								case "center":
									value = UIStackViewAlignment.Center.rawValue as NSNumber
									break
								
								case "fill":
									value = UIStackViewAlignment.Fill.rawValue as NSNumber
									break
								
								case "top":
									value = UIStackViewAlignment.Top.rawValue as NSNumber
									break
								
								case "trailing":
									value = UIStackViewAlignment.Trailing.rawValue as NSNumber
									break
								
								default:
									break
							}
						
						default:
							break
					}
				}
				
				// this is string.endsWith in swift. :| lovely.
				if let range = propertyName.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch) {
					if range.endIndex == propertyName.endIndex {
						propertyType = "UIColor" // bit of a hack because UIButton.backgroundColor doesn't seem to know its property class via inspection :/
					}
				}
				
				// TODO: look up type of target property and use its name to look up a converter
//				if let classType =  {
//					var aClass: AnyClass? = self.dynamicType
//					var propertiesCount: CUnsignedInt = 0
//var value: Any
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
				
//				if !handled {
					switch propertyName {
						// FIXME: may want to set these with higher priority than default to avoid view/container bindings conflicting
						case "width":
//							NSLog("set width to %@", value)
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue))
//							if let view = currentContext as? UIView {
////								UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//									view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
////								})
//							}
						case "minWidth":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxWidth":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
						case "height":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue))
						case "minHeight":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxHeight":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((attributeValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
						case "gravity":

							break
						
//						case "font":
//							
//							currentContext?.setValue("\(font) Medium", forKey: "font")
						
//						default:
//							handled = false
//					}
//				}
//				
//				if !handled {
//					switch propertyName {

						// TODO: we should get rid of these and replace them with something intuitive, like rank
						case "h-hugging":
							element.setContentHuggingPriority((attributeValue as NSString).floatValue, forAxis: UILayoutConstraintAxis.Horizontal)
							break
//						
						case "h-resistance":
							element.setContentCompressionResistancePriority((attributeValue as NSString).floatValue, forAxis: UILayoutConstraintAxis.Horizontal)
							break
						
						default:
//							try {
								try currentContext?.setValue(value, forKey: propertyName)
//							} catch {
//								return nil
//							}
					}
				}
//			}
//			else {
//				// throw/warn
//			}
		}
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
	
		let element = elementStack.last!
		
		// MARK: - ELEMENT POST-PROCESSING -
		
		if let stackView = element as? UIStackView {
			if attributeStack.last!["alignment"] == nil { // only if alignment is not explicitly set
				if stackView.axis == UILayoutConstraintAxis.Horizontal {
					switch gravityStack.last!.vertical {
						case GravityDirection.Top:
							stackView.alignment = UIStackViewAlignment.Top
							break
						case GravityDirection.Middle:
							stackView.alignment = UIStackViewAlignment.Center
							break
						case GravityDirection.Bottom:
							stackView.alignment = UIStackViewAlignment.Bottom
							break
						case GravityDirection.Tall:
							stackView.alignment = UIStackViewAlignment.Fill
							break
						default:
							break // throw?
					}
				} else {
					switch gravityStack.last!.horizontal {
						case GravityDirection.Top:
							stackView.alignment = UIStackViewAlignment.Top
							break
						case GravityDirection.Middle:
							stackView.alignment = UIStackViewAlignment.Center
							break
						case GravityDirection.Bottom:
							stackView.alignment = UIStackViewAlignment.Bottom
							break
						case GravityDirection.Tall:
							stackView.alignment = UIStackViewAlignment.Fill
							break
						default:
							break // throw?
					}
				}
			}
			
			// MARK: Content Compression Resistance
			let baseCompressionResistance = Float(750)
			var shrinkIndex = Dictionary<Int, UIView>()
			for subview in stackView.arrangedSubviews {
				let rank = elementMetadata[subview]!.shrinks
				let adjustedIndex = rank == 0 ? 0 : (1000 - abs(rank)) * (rank > 0 ? -1 : 1)
				NSLog("rank %d adjusted to %d", rank, adjustedIndex)
				shrinkIndex[adjustedIndex] = subview
			}
			let sortedShrinks = shrinkIndex.sort({ (first: (Int, UIView), second: (Int, UIView)) -> Bool in
				return first.0 < second.0
			})
			for var i = 0; i < sortedShrinks.count; i++ {
//				let shrinkTuple = sortedShrinks[i]
				var compressionResistance: Float
				if i > 0 && sortedShrinks[i].0 == sortedShrinks[i-1].0 {
					compressionResistance = sortedShrinks[i-1].1.contentCompressionResistancePriorityForAxis(stackView.axis)
				} else {
					compressionResistance = baseCompressionResistance + Float(i) / Float(sortedShrinks.count)
				}
				sortedShrinks[i].1.setContentCompressionResistancePriority(compressionResistance, forAxis: stackView.axis)
				NSLog("%d: %f", sortedShrinks[i].0, compressionResistance)
			}
			
			
			// MARK: Content Hugging
			let baseContentHugging = Float(200)
			var growIndex = Dictionary<Int, UIView>()
			for subview in stackView.arrangedSubviews {
				let rank = elementMetadata[subview]!.grows
				let adjustedIndex = rank == 0 ? 0 : (1000 - abs(rank)) * (rank > 0 ? -1 : 1)
				NSLog("rank %d adjusted to %d", rank, adjustedIndex)
				growIndex[adjustedIndex] = subview
			}
			let sortedGrows = growIndex.sort({ (first: (Int, UIView), second: (Int, UIView)) -> Bool in
				return first.0 < second.0
			})
			for var i = 0; i < sortedGrows.count; i++ {
//				let shrinkTuple = sortedShrinks[i]
				var contentHugging: Float
				if i > 0 && sortedGrows[i].0 == sortedGrows[i-1].0 {
					contentHugging = sortedGrows[i-1].1.contentHuggingPriorityForAxis(stackView.axis)
				} else {
					contentHugging = baseContentHugging + Float(i) / Float(sortedGrows.count)
				}
				sortedGrows[i].1.setContentHuggingPriority(contentHugging, forAxis: stackView.axis)
				NSLog("%d: %f", sortedGrows[i].0, contentHugging)
			}
			
			// TODO: clean this code up
			let spacer = UIView()
//			spacer.text = "hi"
			spacer.userInteractionEnabled = false
//			spacer.autoSetDimension(stackView.axis == UILayoutConstraintAxis.Horizontal ? ALDimension.Width : ALDimension.Height, toSize: 100000)
//			spacer.setContentCompressionResistancePriority(100 - Float(stack.count), forAxis: stackView.axis)

//			spacer.setContentHuggingPriority(100-Float(elementStack.count), forAxis: stackView.axis) // does this do anything?

//			spacer.autoSetDimension(ALDimension.Width, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
//			spacer.autoSetDimension(ALDimension.Height, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)

//			spacer.backgroundColor = colorForStackLevel(stack.count)

			// note that we probably only want to do this for certain gravities
			if stackView.axis == UILayoutConstraintAxis.Horizontal && gravityStack.last!.horizontal == GravityDirection.Right || stackView.axis == UILayoutConstraintAxis.Vertical && gravityStack.last!.vertical == GravityDirection.Bottom {
				stackView.insertArrangedSubview(spacer, atIndex: 0)
			} else if stackView.axis == UILayoutConstraintAxis.Horizontal && gravityStack.last!.horizontal == GravityDirection.Left || stackView.axis == UILayoutConstraintAxis.Vertical && gravityStack.last!.vertical == GravityDirection.Top {
				stackView.addArrangedSubview(spacer) // add an empty view to act as a space filler
			}

		} else if let button = element as? UIButton {
			button.adjustsImageWhenHighlighted = true
//						button.backgroundColor = UIColor.blueColor()
//						button.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
		} else if let label = element as? UILabel {
			switch gravityStack.last!.horizontal {
				case GravityDirection.Left:
					label.textAlignment = NSTextAlignment.Left
					break
				case GravityDirection.Center:
					label.textAlignment = NSTextAlignment.Center
					break
				case GravityDirection.Right:
					label.textAlignment = NSTextAlignment.Right
					break
				case GravityDirection.Wide:
					label.textAlignment = NSTextAlignment.Justified
					break
				default:
					// TODO: throw
					break
			}
			label.textColor = colorStack.last!
//						label.numberOfLines = 0
//						label.setContentCompressionResistancePriority(100, forAxis: UILayoutConstraintAxis.Horizontal)
		} else if let imageView = element as? UIImageView {
			imageView.contentMode = UIViewContentMode.ScaleAspectFit
			imageView.tintColor = colorStack.last!
//						UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//							imageView.autoSetContentCompressionResistancePriorityForAxis(ALAxis.Horizontal)
//							imageView.autoSetContentHuggingPriorityForAxis(ALAxis.Horizontal)
//						})
//						[UIView autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
//    [myImageView autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
//    [myImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
//}];
		}
	
//		if let stackView = elementStack.last as? UIStackView {
//		}
		
		if let attrs = attributeStack.last {
			if attrs["gravity"] != nil {
				gravityStack.popLast()
			}
			if attrs["color"] != nil {
				colorStack.popLast()
			}
		}
		
		if let poppedElement = elementStack.popLast() {
			// this might be preemptive; we should only do this when the stack closes, at which point the child metadata will already be removed
			// we don't actually need to remove any metadata as we parse, we can clean it up afterwards
//			elementMetadata.removeValueForKey(poppedElement)
		}
		attributeStack.popLast()
	}
}

@objc public class GravityView: UIView {
	public var ids: [String : UIView] = [:]
	
	public func autoSize() {
		layoutIfNeeded()
		
		frame.size.width = subviews[0].frame.size.width
		frame.size.height = subviews[0].frame.size.height
	}
	
//	public override func layoutIfNeeded() {
//		super.layoutIfNeeded()
//		autoSize()
//	}
	
//	public override func updateConstraints() {
//		super.updateConstraints()
//		autoSize()
//	}
}

// make this a struct??
public struct GravityMetadata {
	var shrinks: Int = 0
	var grows: Int = 0
}
//@objc public class GravitySpacer: UIView {
////	init() {
////		super.init(forAutoLayout: ())
////		setContentCompressionResistancePriority(1, forAxis: UILayoutConstraintAxis.Horizontal)
////		setContentCompressionResistancePriority(1, forAxis: UILayoutConstraintAxis.Vertical)
////	}
////
////	required public init?(coder aDecoder: NSCoder) {
////	    fatalError("init(coder:) has not been implemented")
////	}
//	
//	public override func intrinsicContentSize() -> CGSize {
//		return CGSize(width: 0, height: 0)
//	}
//}