//
//  Conversion.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// Gravity.Conversion.registerConverter(...)
// Gravity.Conversion.convert(object) as Type

@available(iOS 9.0, *)
extension Gravity {
	public typealias GravityConverterBlock = (value: GravityNode) -> AnyObject?
	
	@available(iOS 9.0, *)
	@objc public class Conversion: GravityPlugin {
		private static var converters = Dictionary<String, GravityConverterBlock>()
		
//		public override var recognizedAttributes: [String]? {
//			get {
//				return [] // no attributes
//			}
//		}
		
		public override class func initialize() {
			loadDefaultConverters()
		}
		
		public class func registerConverterForClass(type: AnyClass, converter: GravityConverterBlock) {
			
			converters["\(type)"] = converter
		}
		
		public override func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
			var propertyType: String? = nil
			
			guard let attribute = attribute else {
				return .NotHandled
			}
			
//			if let attribute = attribute { // this is an attribute node
			if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
				propertyType = "UIColor" // bit of a hack because UIView.backgroundColor doesn't seem to know its property class via inspection :/
			}
			
			if propertyType == nil {
//				NSLog("Looking up property for \(node.view.dynamicType) . \(attribute)")
				// is there a better/safer way to do this reliably?
				if let parentNode = value?.parentNode {
					let property = class_getProperty(NSClassFromString("\(parentNode.view.dynamicType)"), attribute) // can we do this without touching view?
					if property != nil {
						if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
							if components.count >= 2 {
								propertyType = components[1]
	//							NSLog("propertyType: \(propertyType!)")
							}
						}
					}
				}
			}
//			}
			
//			if let stringValue = value?.stringValue {
			var convertedValue: AnyObject? = nil//value.stringValue
			if let propertyType = propertyType {
				convertedValue = value?.convert(propertyType)
			}
			
			if convertedValue != nil {
				value?.objectValue = convertedValue
			}
//			}
//			else { // this is a node value
//				// do we actually need to do this, or can we write UIView/UIViewController converters? if so they should naturally accept a node value, not a string value
//				if let propertyType = propertyType {
//					if let type = NSClassFromString(propertyType) {
//						if type is UIView.Type {
//							// TODO: implement
//						} else if type is UIViewController.Type {
//							// TODO: implement
//						}
//					}
//				}
//			}
			return .NotHandled
		}
		
//		public class func convert<T: AnyObject>(input: String) -> T? {
//			if "\(T.self)" == "String" { // there's got to be a better way to do this
//				return input as? T // verify
//			}
//			if let converter = converters["\(T.self)"] {
//				var output: AnyObject?
//				if converter(input: input, output: &output) == .Handled {
//					return output as? T
//				}
//			}
//			return nil
//		}
		
//		public override func transformValue(node: GravityNode, attribute: String, input: GravityNode, inout output: AnyObject) -> GravityResult {
//			var propertyType: String? = nil
//			
//			// this is string.endsWith in swift. :| lovely.
//			if attribute.lowercaseString.rangeOfString("color", options:NSStringCompareOptions.BackwardsSearch)?.endIndex == attribute.endIndex {
//				propertyType = "UIColor" // bit of a hack because UIView.backgroundColor doesn't seem to know its property class via inspection :/
//			}
//			
//			if propertyType == nil {
////				NSLog("Looking up property for \(node.view.dynamicType) . \(attribute)")
//				// is there a better/safer way to do this reliably?
//				let property = class_getProperty(NSClassFromString("\(node.view.dynamicType)"), attribute)
//				if property != nil {
//					if let components = String.fromCString(property_getAttributes(property))?.componentsSeparatedByString("\"") {
//						if components.count >= 2 {
//							propertyType = components[1]
////							NSLog("propertyType: \(propertyType!)")
//						}
//					}
//				}
//			}
//			
//			if propertyType != nil {
//				if let converter = Conversion.converters[propertyType!] {
//					var newOutput: AnyObject? = output
//					if converter(input: input, output: &newOutput) == .Handled {
//						output = newOutput! // this feels ugly
//						return .Handled
//					}
//				}
//			}
//			
//			return .NotHandled
//		}
		
		private class func loadDefaultConverters() {
			// UIColor
			registerConverterForClass(UIColor.self) { (value) -> AnyObject? in
				guard let value = value.stringValue?.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet) else {
					return nil
				}
				var int = UInt32()
				NSScanner(string: value).scanHexInt(&int)
				let r, g, b, a: UInt32
				switch value.characters.count {
					case 3: // RGB (12-bit)
						(r, g, b, a) = ((int >> 8) * 0x11, (int >> 4 & 0xF) * 0x11, (int & 0xF) * 0x11, 255)
					case 6: // RGB (24-bit)
						(r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
					case 8: // RGBA (32-bit)
						(r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
					default:
						return nil
				}
				return UIColor(red: CGFloat(r) / 255.0, green: CGFloat(g) / 255.0, blue: CGFloat(b) / 255.0, alpha: CGFloat(a) / 255.0)
//				return .Handled // TODO: error handling
			}
			
			// UIFont
			registerConverterForClass(UIFont.self) { (value) -> AnyObject? in
				guard let parts = value.stringValue?.componentsSeparatedByString(" ") else {
					return nil
				}
				var font: UIFont?
				let size = CGFloat((parts.last! as NSString).floatValue)
				if parts.count >= 2 {
					var weight: CGFloat
					switch parts[1].lowercaseString {
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
					
					if parts.first!.lowercaseString == "system" {
						font = UIFont.systemFontOfSize(size, weight: weight)
					} else {
						font = UIFont(name: parts.prefix(parts.count - 1).joinWithSeparator("-"), size: size)
					}				
				} else {
					if parts.first!.lowercaseString == "system" {
						font = UIFont.systemFontOfSize(size)
					} else {
						font = UIFont(name: parts.first!, size: size)
					}
				}
				return font
//				output = font
//				return output != nil ? .Handled : .NotHandled
			}
			
			// UIView
			registerConverterForClass(UIView.self) { (value) -> AnyObject? in
				return value.view // TODO: or do we want to instantiate?
			}
			
			// UIImage
			registerConverterForClass(UIImage.self) { (value) -> AnyObject? in
				if let stringValue = value.stringValue {
					return UIImage(named: stringValue)
				} else {
					return nil
				}
			}
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	public func convert(type: String) -> AnyObject? {
//		return Gravity.Conversion.convert(stringValue) as? T?
		if type == "String" || type == "NSString" { // there's got to be a better way to do this
			return stringValue// as? T // verify
		}
		if let converter = Gravity.Conversion.converters[type] {
//			var output: AnyObject?
			if let value = converter(value: self) {
				return value// as? T
			}
		}
		return nil
	}
	
	public func convert<T>() -> T? {
		return convert("\(T.self)") as? T
	}
}