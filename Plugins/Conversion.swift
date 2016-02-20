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
	public typealias GravityConverterBlock = (input: GravityNode, inout output: AnyObject?) -> GravityResult
	
	@available(iOS 9.0, *)
	@objc public class Conversion: GravityPlugin {
		private static var converters = Dictionary<String, GravityConverterBlock>()
		
		public override class func initialize() {
			loadDefaultConverters()
		}
		
		public class func registerConverterForClass(type: AnyClass, converter: GravityConverterBlock) {
			converters["\(type)"] = converter
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
			registerConverterForClass(UIColor.self) { (input, output) -> GravityResult in
				guard let value = input.textValue?.stringByTrimmingCharactersInSet(NSCharacterSet.alphanumericCharacterSet().invertedSet) else {
					return .NotHandled
				}
				var int = UInt32()
				NSScanner(string: value).scanHexInt(&int)
				let r, g, b, a: UInt32
				switch value.characters.count {
					case 3: // RGB (12-bit)
						(r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
					case 6: // RGB (24-bit)
						(r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
					case 8: // RGBA (32-bit)
						(r, g, b, a) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
					default:
						return .NotHandled
				}
				output = UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
				return .Handled // TODO: error handling
			}
			
			// UIFont
			registerConverterForClass(UIFont.self) { (input, output) -> GravityResult in
				guard let parts = input.textValue?.componentsSeparatedByString(" ") else {
					return .NotHandled
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
				output = font
				return output != nil ? .Handled : .NotHandled
			}
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	public func convert(type: String) -> AnyObject? {
//		return Gravity.Conversion.convert(textValue) as? T?
		if type == "String" || type == "NSString" { // there's got to be a better way to do this
			return textValue// as? T // verify
		}
		if #available(iOS 9.0, *) {
		    if let converter = Gravity.Conversion.converters[type] {
    			var output: AnyObject?
    			if converter(input: self, output: &output) == .Handled {
    				return output// as? T
    			}
    		}
		} else {
		    // Fallback on earlier versions
		}
		return nil
	}
	
	public func convert<T>() -> T? {
		return convert("\(T.self)") as? T
	}
}