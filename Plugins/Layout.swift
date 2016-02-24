//
//  Layout.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Layout: GravityPlugin {
		private static let keywords = ["fill", "auto"]
		private var widthIdentifiers = [String: [GravityNode]]() // instead of storing a dictionary of arrays, can we store a dictionary that just points to the first-registered view, and then all subsequent views just add constraints back to that view?
		
		public override func instantiateView(node: GravityNode) -> UIView? {
			// should this be handled in a stackview plugin?
			switch node.nodeName {
				case "H":
					let stackView = UIStackView()
					stackView.axis = .Horizontal
					return stackView
				
				case "V":
					let stackView = UIStackView()
					stackView.axis = .Vertical
					return stackView
				
				default:
					return nil
			}
		}
		
		public override func preprocessValue(node: GravityNode, attribute: String, value: GravityNode) {
			guard let textValue = value.textValue else {
				return
			}
			
			switch attribute {
				case "width":
					if !Layout.keywords.contains(textValue) {
						let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
						if textValue.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
							if widthIdentifiers[textValue] == nil {
								widthIdentifiers[textValue] = [GravityNode]()
							}
							widthIdentifiers[textValue]?.append(node)
						}
					}
					break
				
				default:
					break
			}
		}
		
		public override func preprocessAttribute(node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult {
			NSLog(attribute)
			// TODO: can we do anything with node values here?
			guard let textValue = value.textValue else {
				return .NotHandled
			}
			
			switch attribute {
				// TODO: may want to set these with higher priority than default to avoid view/container bindings conflicting
				// we should also capture these priorities as constants and put them all in one place for easier tweaking and balancing
				case "width":
					if !Layout.keywords.contains(textValue) {
						let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
						if textValue.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
//							if widthIdentifiers[textValue] == nil {
//								widthIdentifiers[textValue] = [GravityNode]()
//							}
//							widthIdentifiers[textValue]?.append(node)
						} else {
							UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
								node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((textValue as NSString).floatValue))
							}
						}
					}
					return .Handled
				
				case "minWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((textValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
					return .Handled
				
				case "maxWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((textValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
					return .Handled
				
				case "height":
					if !Layout.keywords.contains(textValue) {
						UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
							node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((textValue as NSString).floatValue))
						}
					}
					return .Handled
				
				case "minHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((textValue as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
					return .Handled
				
				case "maxHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((textValue as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
					return .Handled
				
				case "shrinks":
					return .Handled
				
				default:
					return .NotHandled
			}
		}
		
		public override func handleChildNodes(node: GravityNode) -> GravityResult {
			// TODO: we may be better off actually setting a z-index on the views; this needs to be computed
			
			// we have to do a manual fucking insertion sort here, jesus gawd what the fuck swift?!! no stable sort in version 2.0 of a language??? how is that even remotely acceptable??
			// because, you know, i enjoy wasting my time writing sort algorithms!
			var sortedChildren = [GravityNode]()
			for childNode in node.childNodes {
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

			for childNode in sortedChildren {
				node.view.addSubview(childNode.view)
				
				UIView.autoSetPriority(GravityPriorities.ViewContainment + Float(childNode.depth)) {
					// TODO: come up with better constraint identifiers than this
					// only apply these implicit constraints if the parent is not filled
					
					if !node.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) {
						childNode.constraints["view-left"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
						childNode.constraints["view-right"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
					}
					
					if !node.isFilledAlongAxis(UILayoutConstraintAxis.Vertical) {
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
					
					default:
						break
				}
			}
			
			return .Handled
		}
		
		public override func postprocessElement(node: GravityNode) {
			for (identifier, nodes) in widthIdentifiers {
				let first = nodes[0]
				for var i = 1; i < nodes.count; i++ {
					// priority?? also we need to add a constraint (but what should its identifier be?)
					nodes[i].view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: first.view)
				}
			}
			
			// minWidth, etc. should probably be higher priority than these so they can override fill size
			if node.isFilledAlongAxis(UILayoutConstraintAxis.Horizontal) {
				node.view.setContentHuggingPriority(GravityPriorities.FillSizeHugging, forAxis: UILayoutConstraintAxis.Horizontal)
				if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != UILayoutConstraintAxis.Horizontal {
//					if node.view.superview is UIStackView {
//						NSLog("Superview must be a vertical stack view")
//					}
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
//					if node.view.superview is UIStackView {
//						NSLog("Superview must be a horizontal stack view")
//					}
					UIView.autoSetPriority(GravityPriorities.FillSize - Float(node.depth)) {
	//					node.view.autoMatchDimension(ALDimension.Height, toDimension: ALDimension.Height, ofView: node.view.superview)
						node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
						node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
					}
				}
			}
		}
	}
}

public struct GravityDirection {
	var horizontal = Horizontal.Inherit
	var vertical = Vertical.Inherit
	
	public enum Horizontal: Int {
		case Inherit = 0
		case Left
		case Right
		case Center
	}
	
	public enum Vertical: Int {
		case Inherit = 0
		case Top
		case Bottom
		case Middle
	}
	
	public static let Left = Horizontal.Left
	public static let Right = Horizontal.Right
	public static let Center = Horizontal.Center
	
	public static let Top = Vertical.Top
	public static let Bottom = Vertical.Bottom
	public static let Middle = Vertical.Middle
	
	init() {
		self.horizontal = .Inherit
		self.vertical = .Inherit
	}
	
	init(horizontal: Horizontal, vertical: Vertical) {
		self.horizontal = horizontal
		self.vertical = vertical
	}
	
	init?(_ textValue: String?) {
		guard let textValue = textValue else { // boilerplate! ick
			return nil
		}
		
		let valueParts = textValue.lowercaseString.componentsSeparatedByString(" ")
		
		if valueParts.contains("left") {
			horizontal = GravityDirection.Left
		} else if valueParts.contains("center") {
			horizontal = GravityDirection.Center
		} else if valueParts.contains("right") {
			horizontal = GravityDirection.Right
		}
		
		if valueParts.contains("top") {
			vertical = GravityDirection.Top
		} else if valueParts.contains("mid") || valueParts.contains("middle") {
			vertical = GravityDirection.Middle
		} else if valueParts.contains("bottom") {
			vertical = GravityDirection.Bottom
		}
	}
}

//public struct GravityDirection: OptionSetType {
//	// we could also just do this with two separate member variables
//	public var rawValue: Int = 0
////	public var rawHorizontal: Int = 0
////	public var rawVertical: Int = 0
//	
//	public init(rawValue: Int) {
//		self.rawValue = rawValue
//	}
//	
//	// TODO: can we use a converter for this??
//	init(_ textValue: String) {
//		let valueParts = textValue.lowercaseString.componentsSeparatedByString(" ")
//		var gravity = GravityDirection()
//		
//		if valueParts.contains("left") {
//			gravity.horizontal = GravityDirection.Left
//		} else if valueParts.contains("center") {
//			gravity.horizontal = GravityDirection.Center
//		} else if valueParts.contains("right") {
//			gravity.horizontal = GravityDirection.Right
//		}
//		
//		if valueParts.contains("top") {
//			gravity.vertical = GravityDirection.Top
//		} else if valueParts.contains("mid") || valueParts.contains("middle") {
//			gravity.vertical = GravityDirection.Middle
//		} else if valueParts.contains("bottom") {
//			gravity.vertical = GravityDirection.Bottom
//		}
//
//		rawValue = gravity.rawValue
//	}
//	
//	// horizontal gravity
//	static let Left = GravityDirection(rawValue: 0b01)
//	static let Right = GravityDirection(rawValue: 0b10)
//	static let Center = GravityDirection(rawValue: 0b11)
//	
//	// vertical gravity
//	static let Top = GravityDirection(rawValue: 0b01 << 3)
//	static let Bottom = GravityDirection(rawValue: 0b10 << 3)
//	static let Middle = GravityDirection(rawValue: 0b11 << 3)
//	
//	func hasHorizontal() -> Bool {
//		return horizontal.rawValue > 0
//	}
//	var horizontal: GravityDirection {
//		get {
//			return GravityDirection(rawValue: rawValue & 0b111)
//		}
//		set(value) {
//			rawValue = vertical.rawValue | (value.rawValue & 0b111)
//		}
//	}
//	
//	func hasVertical() -> Bool {
//		return vertical.rawValue > 0
//	}
//	var vertical: GravityDirection {
//		get {
//			return GravityDirection(rawValue: rawValue & (0b111 << 3))
//		}
//		set(value) {
//			rawValue = horizontal.rawValue | (value.rawValue & (0b111 << 3))
//		}
//	}
//}

@available(iOS 9.0, *)
extension GravityNode {
	public var gravity: GravityDirection {
		get {
			var gravity = GravityDirection(self["gravity"]?.textValue) ?? GravityDirection()
			
			if gravity.horizontal == .Inherit {
				gravity.horizontal = parentNode?.gravity.horizontal ?? .Left
			}
			if gravity.vertical == .Inherit {
				gravity.vertical = parentNode?.gravity.vertical ?? .Top
			}
			
			return gravity
		}
	}
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"]?.textValue ?? "0")!
		}
	}
	
//	internal func isExplicitlySizedAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
//		switch axis {
//			case .Horizontal:
//		}
//	}
	
	internal func isFilledAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		switch axis {
			case .Horizontal:
//				if self["maxWidth"] != nil {
//					return false // experimental
//				}
				if self["width"] == "fill" {
					return true
				}
				let width = attributes["width"]?.textValue?.lowercaseString
				if width == "fill" {
					return true
				} else if width != nil && width != "auto" { // "auto" is the default and is the same as not specifying
					return false
				}
//				if
				
				for childNode in childNodes {
					if childNode.isFilledAlongAxis(axis) && childNode["maxWidth"] == nil {
						return true
					}
				}
				
				return false
			
			case .Vertical:
				let height = attributes["height"]?.textValue?.lowercaseString
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
}