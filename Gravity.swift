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
		// if filename doesn't end with .xml (and can't be found as specified) append .xml
		let gravity = Gravity()
		let url = NSURL(fileURLWithPath: NSBundle.mainBundle().resourcePath!).URLByAppendingPathComponent(filename, isDirectory: false)
		if let parser = NSXMLParser(contentsOfURL: url) {
			parser.delegate = gravity
			parser.parse()
		}
//		let containerView = GravityView()
		gravity.containerView.addSubview(gravity.rootElement!)
		gravity.rootElement?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
//		gravity.rootElement?.autoCenterInSuperview()
		gravity.containerView.layoutIfNeeded()
		gravity.containerView.updateConstraints() // need this?
		// TODO: figure out what size to pass here
		// perhaps we should write this as an extension on UIView and then we can simply check the size of the parent view
		// we should also allow things like a maxWidth, maxHeight to be specified on the root element in the xml file
		let fitSize = gravity.rootElement?.systemLayoutSizeFittingSize(CGSize(width: 400, height: 400));
		gravity.containerView.frame.size.width = (fitSize?.width)!
		gravity.containerView.frame.size.height = (fitSize?.height)!
		
		return gravity.containerView
	}
	
	func typeName(some: Any) -> String {
		return (some is Any.Type) ? "\(some)" : "\(some.dynamicType)"
	}
	
	func addElement(element: UIView) {
		if let top = self.stack.last {
			if let stackView = top as? UIStackView {
				stackView.addArrangedSubview(element)
//				element.autoPinEdgeToSuperviewEdge(ALEdge.Left)
//				element.autoPinEdgeToSuperviewEdge(ALEdge.Top)
			} else {
				top.addSubview(element)
//				element.autoCenterInSuperview()
				// TODO: add support for margins via a margins and/or padding attribute
				element.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
			}
		} else if ( rootElement == nil ) {
			rootElement = element
		} else {
			// throw
		}
		
		self.stack.append(element)
	}
	
	@objc public func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
		var element: UIView
		
		switch elementName {
			case "H", "h", "V", "v":
				element = UIStackView()
				self.addElement(element)
				if let stackView = element as? UIStackView {
					switch elementName {
						case "H", "h":
							stackView.axis = UILayoutConstraintAxis.Horizontal
						
						case "V", "v":
							stackView.axis = UILayoutConstraintAxis.Vertical
						
						default:
							break // change to throw when i learn how to do that
					}
				}
			
			default:
				if let classType = NSClassFromString(elementName) as! UIView.Type? {
					element = classType.init()
					if let button = element as? UIButton {
						button.backgroundColor = UIColor.blueColor()
					} else if let label = element as? UILabel {
						label.numberOfLines = 0
					}
					self.addElement(element)
				}
				break
		}
		
		// attributes:
		// we eventually want to interpret these, so things like textColor can contain values like #0099cc or "blue"
		for (key, value) in attributeDict {
			if let element = self.stack.last {
				if key == "id" { // special override case
					self.containerView.ids[value] = element
					continue
				}
				if let button = element as? UIButton {
					switch key {
						case "title":
							button.setTitle(value, forState: UIControlState.Normal)
						
						default:
							element.setValue(value, forKey: key)
					}
				} else {
					switch key {
						case "width":
							element.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
						case "minWidth":
							element.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxWidth":
							element.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
						case "height":
							element.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue))
						case "minHeight":
							element.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
						case "maxHeight":
							element.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
						
						default:
							element.setValue(value, forKey: key)
					}
				}
			} else {
				// throw/warn
			}
		}
	}
	
	public func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
		self.stack.popLast()
	}
}

@objc public class GravityView: UIView {
	public var ids: [String : UIView] = [:]
}