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

public enum GravityDirection: Int {
	case TopLeft
	case TopRight
	case BottomLeft
	case BottomRight
	// TODO: do we want to add a "center" gravity? maybe split into h-gravity and v-gravity
	
	func isTop() -> Bool {
		return self == TopLeft || self == TopRight
	}
	
	func isLeft() -> Bool {
		return self == TopLeft || self == BottomLeft
	}
}

@available(iOS 9.0, *)
@objc public class Gravity: NSObject, NSXMLParserDelegate {

	static var converters = Dictionary<String, (value: String) -> AnyObject?>()

	var elementStack = [UIView]()
	var attributeStack = [[String : String]]()
	var gravityStack = [GravityDirection]()
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
		gravityStack.append(GravityDirection.TopLeft)
	}
	
	public class func constructFromFile(filename: String) -> GravityView? {
		let gravity = Gravity()
		return gravity.constructFromFile(filename)
	}
	
	// TODO: we should consider caching constructed views for a given filename if we can do so in such a way that serializing/deserializing a cached view is faster than simply rebuilding it each time
	public func constructFromFile(filename: String) -> GravityView? {
		// if filename doesn't end with .xml (and can't be found as specified) append .xml
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(filename, isDirectory: false)
		if let parser = NSXMLParser(contentsOfURL: url) {
			parser.delegate = self
			parser.parse()
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
	
	public class func registerConverter( converter: (String) -> AnyObject?, forTypeName typeName: String ) {
//		if Gravity.converters[className] == nil {
//			Gravity.converters[className] = Array<(String) -> NSObject?>()
//		}
		Gravity.converters[typeName] = converter
	}
	
	func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		var className = elementName
		attributeStack.append(attributeDict)
		
		if let attributeValue = attributeDict["gravity"] {
			let valueParts = attributeValue.stringByReplacingOccurrencesOfString("-", withString: " ").componentsSeparatedByString(" ") // allow to be in the form "top-left" or "top left"
			let left = valueParts.contains("left")
			let top = valueParts.contains("top")
			let right = valueParts.contains("right")
			let bottom = valueParts.contains("bottom")
			var gravity: GravityDirection?
			if top && left {
				gravity = GravityDirection.TopLeft
			} else if top && right {
				gravity = GravityDirection.TopRight
			} else if bottom && left {
				gravity = GravityDirection.BottomLeft
			} else if bottom && right {
				gravity = GravityDirection.BottomRight
			}
			if gravity != nil {
				gravityStack.append(gravity!)
			}
		}
		
		// MARK: - ELEMENTS -
		
		var element: UIView?
		switch elementName {
			case "H", "h", "V", "v":
				element = UIStackView()
//				self.addElement(element)
				if let stackView = element as? UIStackView {
					switch elementName {
						case "H":
							className = "UIStackView"
							stackView.axis = UILayoutConstraintAxis.Horizontal
							stackView.alignment = gravityStack.last!.isTop() ? UIStackViewAlignment.Top : UIStackViewAlignment.Bottom
						
						case "V":
							className = "UIStackView"
							stackView.axis = UILayoutConstraintAxis.Vertical
							stackView.alignment = gravityStack.last!.isLeft() ? UIStackViewAlignment.Leading : UIStackViewAlignment.Trailing
							
						case "XIB":
							className = "UIView"
							// TODO
						
						default:
							break // change to throw when i learn how to do that
					}
//					stackView.layoutMarginsRelativeArrangement = true//test
//					stackView.alignment = 
				}
			
			default:
//				if elementName == "UIButton" {
//					elementName = "UIView"
//				}
				if let classType = NSClassFromString(className) as! UIView.Type? {
					element = classType.init()
					if let button = element as? UIButton {
//						button.backgroundColor = UIColor.blueColor()
//						button.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
					} else if let label = element as? UILabel {
//						label.numberOfLines = 0
//						label.setContentCompressionResistancePriority(100, forAxis: UILayoutConstraintAxis.Horizontal)
					} else if let imageView = element as? UIImageView {
						imageView.contentMode = UIViewContentMode.ScaleAspectFit
//						UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//							imageView.autoSetContentCompressionResistancePriorityForAxis(ALAxis.Horizontal)
//							imageView.autoSetContentHuggingPriorityForAxis(ALAxis.Horizontal)
//						})
//						[UIView autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
//    [myImageView autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
//    [myImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
//}];
					} else if element != nil {
//						element!.backgroundColor = UIColor.greenColor() // temp
					}
//					self.addElement(element)
				}
				break
		}
		
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
		}
		
		// MARK: - ATTRIBUTES -
		
		// we eventually want to interpret these, so things like textColor can contain values like #0099cc or "blue"
		// we should check the property type of the property we are setting and look up a registered converter; we can include a bunch of built-in converters for obvious things like UIColor, UIFont etc.
		for (key, attributeValue) in attributeDict {
			if let element = elementStack.last {
				if key == "id" { // special override case
					containerView.ids[attributeValue] = element
					continue
				}
				
				var propertyName = key
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
							imageView.image = UIImage(named: attributeValue)
							continue
							
						default:
							break
					}
				} else if let _ = currentContext as? UIStackView {
					switch propertyName {
						case "alignment":
							switch attributeValue.lowercaseString {
								case "center":
									value = UIStackViewAlignment.Center.rawValue as NSNumber
								
								case "fill":
									value = UIStackViewAlignment.Fill.rawValue as NSNumber
								
								case "top":
									value = UIStackViewAlignment.Top.rawValue as NSNumber
								
								case "trailing":
									value = UIStackViewAlignment.Trailing.rawValue as NSNumber
								
								default:
									break
							}
						
						default:
							break
					}
				}
//				else {
//					handled = false
//				}
				
				// TODO: look up type of target property and use its name to look up a converter
//				if let classType =  {
//					var aClass: AnyClass? = self.dynamicType
//					var propertiesCount: CUnsignedInt = 0
//var value: Any
				let property = class_getProperty(NSClassFromString(className), propertyName)
				if property != nil {
					if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
						if components.count >= 2 {
							let propertyType = components[1]
							NSLog("propertyType: %@", propertyType)
							if let converter = Gravity.converters[propertyType] {
								value = converter(value: attributeValue)
							}
						}
					}
				}
				
//				if !handled {
					switch propertyName {
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
							currentContext?.setValue(value, forKey: propertyName)
					}
				}
//			}
//			else {
//				// throw/warn
//			}
		}
	}
	
	func colorForStackLevel(level: Int) -> UIColor {
		NSLog("level %d", level)
		switch level % 5 {
			case 0:
				return UIColor.magentaColor()
			case 1:
				return UIColor.greenColor()
			case 2:
				return UIColor.purpleColor()
			case 3:
				return UIColor.cyanColor()
			case 4:
				return UIColor.redColor()
			default:
				return UIColor.whiteColor()
		}
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		if let stackView = elementStack.last as? UIStackView {
			let spacer = UIView()
//			spacer.text = "hi"
			spacer.userInteractionEnabled = false
//			spacer.autoSetDimension(stackView.axis == UILayoutConstraintAxis.Horizontal ? ALDimension.Width : ALDimension.Height, toSize: 100000)
//			spacer.setContentCompressionResistancePriority(100 - Float(stack.count), forAxis: stackView.axis)

//			spacer.setContentHuggingPriority(100-Float(elementStack.count), forAxis: stackView.axis) // does this do anything?

//			spacer.autoSetDimension(ALDimension.Width, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
//			spacer.autoSetDimension(ALDimension.Height, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)

//			spacer.backgroundColor = colorForStackLevel(stack.count)
			if stackView.axis == UILayoutConstraintAxis.Horizontal && !gravityStack.last!.isLeft() || stackView.axis == UILayoutConstraintAxis.Vertical && !gravityStack.last!.isTop() {
				stackView.insertArrangedSubview(spacer, atIndex: 0)
			} else {
				stackView.addArrangedSubview(spacer) // add an empty view to act as a space filler
			}
		}
		if let attrs = attributeStack.last {
			if attrs["gravity"] != nil {
				gravityStack.popLast()
			}
		}
		elementStack.popLast()
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

@objc public class GravitySpacer: UIView {
//	init() {
//		super.init(forAutoLayout: ())
//		setContentCompressionResistancePriority(1, forAxis: UILayoutConstraintAxis.Horizontal)
//		setContentCompressionResistancePriority(1, forAxis: UILayoutConstraintAxis.Vertical)
//	}
//
//	required public init?(coder aDecoder: NSCoder) {
//	    fatalError("init(coder:) has not been implemented")
//	}
	
	public override func intrinsicContentSize() -> CGSize {
		return CGSize(width: 0, height: 0)
	}
}