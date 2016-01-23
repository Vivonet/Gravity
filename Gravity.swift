//
//  Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-20.
//  Copyright © 2016 Vivonet. All rights reserved.
//

import Foundation
import UIKit

@available(iOS 9.0, *)
@objc public class Gravity: NSObject, NSXMLParserDelegate {

	var stack = [UIView]()
	var rootElement: UIView? = nil
	var containerView = GravityView()
	
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
	
	func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		
		// ELEMENTS
		
		var element: UIView?
		switch elementName {
			case "H", "h", "V", "v":
				element = UIStackView()
//				self.addElement(element)
				if let stackView = element as? UIStackView {
					switch elementName {
						case "H", "h":
							stackView.axis = UILayoutConstraintAxis.Horizontal
						
						case "V", "v":
							stackView.axis = UILayoutConstraintAxis.Vertical
						
						default:
							break // change to throw when i learn how to do that
					}
//					stackView.layoutMarginsRelativeArrangement = true//test
				}
			
			default:
//				if elementName == "UIButton" {
//					elementName = "UIView"
//				}
				if let classType = NSClassFromString(elementName) as! UIView.Type? {
					element = classType.init()
					if let button = element as? UIButton {
						button.backgroundColor = UIColor.blueColor()
						button.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)
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
			if let top = stack.last {
				if let stackView = top as? UIStackView {
					stackView.addArrangedSubview(element!)
					element!.setContentHuggingPriority(750 - Float(stack.count), forAxis: stackView.axis)
					
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
			stack.append(element!)
		}
		
		// ATTRIBUTES
		
		// we eventually want to interpret these, so things like textColor can contain values like #0099cc or "blue"
		// we should check the property type of the property we are setting and look up a registered converter; we can include a bunch of built-in converters for obvious things like UIColor, UIFont etc.
		for (key, value) in attributeDict {
			if let element = stack.last {
				if key == "id" { // special override case
					containerView.ids[value] = element
					continue
				}
				
				var propertyName = key
				var currentContext: NSObject? = element
				
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
				
				var handled = true
				
				if let label = currentContext as? UILabel {
					switch propertyName {
						case "wrap":
							if (value as NSString).boolValue {
								label.numberOfLines = 0
							}
						
						default:
							handled = false
					}
				} else if let button = currentContext as? UIButton {
					switch propertyName {
						case "title":
							// TODO: we should replace this with css-style styles, with styles for different button states
							button.setTitle(value, forState: UIControlState.Normal)
						
						default:
							handled = false
					}
				}
				else if let imageView = currentContext as? UIImageView {
					switch propertyName {
						case "image":
							imageView.image = UIImage(named: value)
							
						default:
							handled = false
					}
				} else {
					handled = false
				}
				
				if !handled {
					switch propertyName {
						case "width":
//							NSLog("set width to %@", value)
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
//							if let view = currentContext as? UIView {
////								UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//									view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
////								})
//							}
						case "minWidth":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxWidth":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
						case "height":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue))
						case "minHeight":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxHeight":
							(currentContext as? UIView)?.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
//						default:
//							handled = false
//					}
//				}
//				
//				if !handled {
//					switch propertyName {
						case "h-hugging":
//							break
							element.setContentHuggingPriority((value as NSString).floatValue, forAxis: UILayoutConstraintAxis.Horizontal)
//						
						case "h-resistance":
//							break
							element.setContentCompressionResistancePriority((value as NSString).floatValue, forAxis: UILayoutConstraintAxis.Horizontal)
						
						default:
							currentContext?.setValue(value, forKey: propertyName)
					}
				}
			} else {
				// throw/warn
			}
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
		if let stackView = stack.last as? UIStackView {
			let spacer = UIView()
//			spacer.text = "hi"
			spacer.userInteractionEnabled = false
//			spacer.autoSetDimension(stackView.axis == UILayoutConstraintAxis.Horizontal ? ALDimension.Width : ALDimension.Height, toSize: 100000)
//			spacer.setContentCompressionResistancePriority(100 - Float(stack.count), forAxis: stackView.axis)

			spacer.setContentHuggingPriority(100-Float(stack.count), forAxis: stackView.axis)

//			spacer.autoSetDimension(ALDimension.Width, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
//			spacer.autoSetDimension(ALDimension.Height, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
			spacer.backgroundColor = colorForStackLevel(stack.count)
			stackView.addArrangedSubview(spacer) // add an empty view to act as a space filler
		}
		stack.popLast()
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