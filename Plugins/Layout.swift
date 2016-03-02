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
							NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
								node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((textValue as NSString).floatValue))
							}
						}
					}
					return .Handled
				
				case "minWidth":
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(.Width, toSize: CGFloat((textValue as NSString).floatValue), relation: .GreaterThanOrEqual)
					}
					NSLayoutConstraint.autoSetPriority(50) {//test
						node.view.autoSetDimension(.Width, toSize: CGFloat((textValue as NSString).floatValue))
					}
					return .Handled
				
				case "maxWidth":
					if let maxWidth = node.maxWidth {
						NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
							if node.isOtherwiseFilledAlongAxis(.Horizontal) {
								// a maxWidth that is filled is equal to an explicit width
								NSLog("filled maxWidth found")
								node.constraints[attribute] = node.view.autoSetDimension(.Width, toSize: CGFloat(maxWidth))
							} else {
								node.constraints[attribute] = node.view.autoSetDimension(.Width, toSize: CGFloat(maxWidth), relation: .LessThanOrEqual)
							}
						}
					}
					return .Handled
				
				case "height":
					if !Layout.keywords.contains(textValue) {
						NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
							node.constraints[attribute] = node.view.autoSetDimension(.Height, toSize: CGFloat((textValue as NSString).floatValue))
						}
					}
					return .Handled
				
				case "minHeight":
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(.Height, toSize: CGFloat((textValue as NSString).floatValue), relation: .GreaterThanOrEqual)
					}
					NSLayoutConstraint.autoSetPriority(50) {//test
						node.view.autoSetDimension(.Height, toSize: CGFloat((textValue as NSString).floatValue))
					}
					return .Handled
				
				case "maxHeight":
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
						if node.isOtherwiseFilledAlongAxis(.Vertical) {
							// a maxWidth that is filled is equal to an explicit width
							NSLog("filled maxHeight found")
							node.constraints[attribute] = node.view.autoSetDimension(.Height, toSize: CGFloat((textValue as NSString).floatValue))
						} else {
							node.constraints[attribute] = node.view.autoSetDimension(.Height, toSize: CGFloat((textValue as NSString).floatValue), relation: .LessThanOrEqual)
						}
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
			
			// i'm actually thinking this might make the most sense all in one place in postprocess
			for childNode in sortedChildren {
				node.view.addSubview(childNode.view)
				
//				UIView.autoSetPriority(GravityPriority.ViewContainment + Float(childNode.depth)) {
//					// TODO: come up with better constraint identifiers than this
//					// only apply these implicit constraints if we are not filled
//					// if a parent view is not filled, it can still be larger than the child (e.g. via a min size)
//					
////					if !node.isFilledAlongAxis(.Horizontal) {
//						childNode.constraints["view-left"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-left")
//						childNode.constraints["view-right"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-right")
////					}
//					
////					if !node.isFilledAlongAxis(.Vertical) {
//						childNode.constraints["view-top"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-top")
//						childNode.constraints["view-bottom"] = childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-bottom")
////					}
//				}
				
	//			 TODO: add support for margins via a margin and/or padding attribute

	//			childNode.view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
				
				NSLayoutConstraint.autoSetPriority(GravityPriority.Gravity) {
					switch childNode.gravity.horizontal {
						case .Left:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
							break
						
						case .Center:
							childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
							break
						
						case .Right:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
							break
						
						default:
							break
					}
					
					switch childNode.gravity.vertical {
						case .Top:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
							break
						
						case .Middle:
							childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Horizontal)
							break
						
						case .Bottom:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
							break
						
						default:
							break
					}
				}
			}
			
			return .Handled
		}
		
		public override func postprocessElement(node: GravityNode) {
//			NSLog("Postprocess: \(unsafeAddressOf(node))")
			// TODO: we may be getting way too many constraints here
			for (identifier, nodes) in widthIdentifiers {
				let first = nodes[0]
				for var i = 1; i < nodes.count; i++ {
					// priority?? also we need to add a constraint (but what should its identifier be?)
					NSLog("Matching dimension of \(nodes[i]) to \(first).")
					nodes[i].view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: first.view)
				}
			}


			if node.view.superview != nil {
				if (node.view.superview as? UIStackView)?.axis != .Horizontal { // we are not inside a stack view (of the same axis)
					// TODO: what priority should these be?
					// we need to make a special exception for UIScrollView and potentially others. should we move this back into a default handler/handleChildNodes?
					node.view.autoMatchDimension(.Width, toDimension: .Width, ofView: node.parentNode!.view, withOffset: 0, relation: .LessThanOrEqual)
					
					var priority = GravityPriority.ViewContainment + Float(node.recursiveDepth)
					
					if node.isDivergentAlongAxis(.Horizontal) {
						priority = 200 + Float(node.recursiveDepth)
					}
					
					NSLayoutConstraint.autoSetPriority(priority) {
						// if a parent view is not filled, it can still be larger than the child (e.g. via a min size)
						node.constraints["view-left"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-left")
						node.constraints["view-right"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-right")
					}
				}
				
				if (node.view.superview as? UIStackView)?.axis != .Vertical { // we are not inside a stack view (of the same axis)
					node.view.autoMatchDimension(.Height, toDimension: .Height, ofView: node.parentNode!.view, withOffset: 0, relation: .LessThanOrEqual)
					
					var priority = GravityPriority.ViewContainment + Float(node.recursiveDepth)
					
					if node.isDivergentAlongAxis(.Vertical) {
						priority = 200 + Float(node.recursiveDepth)
					}
					
					NSLayoutConstraint.autoSetPriority(priority) {
						node.constraints["view-top"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-top")
						node.constraints["view-bottom"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: 0, relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-bottom")
					}
				}
				
				
			} else {
				NSLog("superview nil")
			}
			
			// minWidth, etc. should probably be higher priority than these so they can override fill size
			if node.isFilledAlongAxis(.Horizontal) {
				node.view.setContentHuggingPriority(GravityPriority.FillSizeHugging, forAxis: .Horizontal)
				if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != .Horizontal {
					NSLayoutConstraint.autoSetPriority(GravityPriority.FillSize - Float(node.recursiveDepth)) {
	//					node.view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: node.view.superview)
						node.constraints["fill-left"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left).autoIdentify("gravity-fill-left") // leading?
						node.constraints["fill-right"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right).autoIdentify("gravity-fill-right") // trailing?
					}
				}
			}
			
			if node.isFilledAlongAxis(.Vertical) {
				node.view.setContentHuggingPriority(GravityPriority.FillSizeHugging, forAxis: .Vertical)
				if node.view.superview != nil && (node.view.superview as? UIStackView)?.axis != .Vertical {
					NSLayoutConstraint.autoSetPriority(GravityPriority.FillSize - Float(node.recursiveDepth)) {
	//					node.view.autoMatchDimension(ALDimension.Height, toDimension: ALDimension.Height, ofView: node.view.superview)
						node.constraints["fill-top"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top).autoIdentify("gravity-fill-top")
						node.constraints["fill-bottom"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom).autoIdentify("gravity-fill-bottom")
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
	
	// these let you shortcut the Horizontal and Vertical enums and say e.g. GravityDirection.Center
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
		guard let textValue = textValue else {
			return nil
		}
		
		let valueParts = textValue.lowercaseString.componentsSeparatedByString(" ")
		
		if valueParts.contains("left") {
			horizontal = .Left
		} else if valueParts.contains("center") {
			horizontal = .Center
		} else if valueParts.contains("right") {
			horizontal = .Right
		}
		
		if valueParts.contains("top") {
			vertical = .Top
		} else if valueParts.contains("middle") {
			vertical = .Middle
		} else if valueParts.contains("bottom") {
			vertical = .Bottom
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	public var gravity: GravityDirection {
		get {
			var gravity = GravityDirection(self["gravity"]?.textValue) ?? GravityDirection()
			
			if gravity.horizontal == .Inherit {
				gravity.horizontal = parentNode?.gravity.horizontal ?? .Center
			}
			if gravity.vertical == .Inherit {
				gravity.vertical = parentNode?.gravity.vertical ?? .Middle
			}
			
			return gravity
		}
	}
	
	public var minWidth: Float? {
		get {
			return self["minWidth"]?.floatValue
		}
	}
	
	public var maxWidth: Float? {
		get {
			return self["maxWidth"]?.floatValue
		}
	}
	
	public var minHeight: Float? {
		get {
			return self["minHeight"]?.floatValue
		}
	}
	
	public var maxHeight: Float? {
		get {
			return self["maxHeight"]?.floatValue
		}
	}
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"]?.textValue ?? "0")!
		}
	}
	
	internal func isExplicitlySizedAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		switch axis {
			case .Horizontal:
				if let width = self["width"]?.textValue {
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if width.rangeOfCharacterFromSet(charset) == nil {
						return true
					}
				}
				return false
			
			case .Vertical:
				if let height = self["height"]?.textValue {
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if height.rangeOfCharacterFromSet(charset) == nil {
						return true
					}
				}
				return false
		}
	}
	
	/// A node is divergent from its parent on an axis if it has the potential that at least one edge of that axis are not bound to their parent edges. For example, an auto-sized node inside a fixed size node has the potential to be smaller than its container, and is considered divergent.
	internal func isDivergentAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		guard let parentNode = parentNode else {
			return false
		}
		
		if self.recursiveDepth == 1 {
			return true // leaving in for now
		}
		
		if parentNode.isFilledAlongAxis(axis) {
			return true
		} else if self.isFilledAlongAxis(axis) {
			return false
		} else if parentNode.isExplicitlySizedAlongAxis(axis) {
			return true
		}
		
		switch axis {
			case .Horizontal:
				if (parentNode.view as? UIStackView)?.axis == .Vertical {
					return true
				}
				if parentNode["minWidth"] != nil {
					return true
				}
			
			case .Vertical:
				if (parentNode.view as? UIStackView)?.axis == .Horizontal {
					return true
				}
				if parentNode["minHeight"] != nil {
					return true
				}
		}
		
		return false
	}
	
	internal func isFilledAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		if !isOtherwiseFilledAlongAxis(axis) {
			return false
		}
		
		switch axis {
			case .Horizontal:
				return self["maxWidth"] == nil
			
			case .Vertical:
				return self["maxHeight"] == nil
		}
	}
	
	internal func isOtherwiseFilledAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		switch axis {
			case .Horizontal:
//				if self["maxWidth"] != nil { // we could verify that it is numeric, but i can't think of a concise way to do that
//					// even if we have width="fill", if there's a maxWidth, that still just equals width
//					return false
//				}
				
				if let width = self["width"]?.textValue {
					if width == "fill" {
						// are there any other negation cases?
						return true
					}
					
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if width.rangeOfCharacterFromSet(charset) == nil {
						return false
					}
				}
				break
			
			case .Vertical:
//				if self["maxHeight"] != nil { // we could verify that it is numeric, but i can't think of a concise way to do that
//					// even if we have width="fill", if there's a maxWidth, that still just equals width
//					return false
//				}
				
				if let height = self["height"]?.textValue {
					if height == "fill" {
						// are there any other negation cases?
						return true
					}
					
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if height.rangeOfCharacterFromSet(charset) == nil {
						return false
					}
				}
				break
		}
		
		for childNode in childNodes {
			if childNode.isFilledAlongAxis(axis) {
				return true
			}
		}
		
		return false
	}
}