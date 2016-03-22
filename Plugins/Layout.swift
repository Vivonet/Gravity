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
		private var widthIdentifiers = [String: Set<GravityNode>]() // instead of storing a dictionary of arrays, can we store a dictionary that just points to the first-registered view, and then all subsequent views just add constraints back to that view?
		
		public override var recognizedAttributes: [String]? {
			get {
				return [
					"gravity",
					"height", "minHeight", "maxHeight",
					"margin", "leftMargin", "topMargin", "rightMargin", "bottomMargin",
					"padding", "leftPadding", "topPadding", "rightPadding", "bottomPadding",
					"shrinks",
					"width", "minWidth", "maxWidth",
					"zIndex"
				]
			}
		}
		
		static var swizzleToken: dispatch_once_t = 0
		
		public override class func initialize() {
			dispatch_once(&swizzleToken) {
				// method swizzling:
				let alignmentRectInsets_orig = class_getInstanceMethod(UIView.self, Selector("alignmentRectInsets"))
				let alignmentRectInsets_swiz = class_getInstanceMethod(UIView.self, Selector("grav_alignmentRectInsets"))
				
				if class_addMethod(UIView.self, Selector("alignmentRectInsets"), method_getImplementation(alignmentRectInsets_swiz), method_getTypeEncoding(alignmentRectInsets_swiz)) {
					class_replaceMethod(UIView.self, Selector("grav_alignmentRectInsets"), method_getImplementation(alignmentRectInsets_orig), method_getTypeEncoding(alignmentRectInsets_orig));
				} else {
					method_exchangeImplementations(alignmentRectInsets_orig, alignmentRectInsets_swiz);
				}
			}
		}
		
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
		
		public override func processValue(value: GravityNode) -> GravityResult {
			guard let node = value.parentNode else {
				return .NotHandled
			}
			
			guard let stringValue = value.stringValue else {
				return .NotHandled
			}
			
			// this has to be done here because widthIdentifiers should be referenced relative to the document the value is defined in, not the node they are applied to
			if value.attributeName == "width" {
				if !Layout.keywords.contains(stringValue) {
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if stringValue.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
						if widthIdentifiers[stringValue] == nil {
							widthIdentifiers[stringValue] = Set<GravityNode>()
						}
						widthIdentifiers[stringValue]?.unionInPlace([node])
					}
				}
				return .Handled
			}
			return .NotHandled
		}
		
		public override func processNode(node: GravityNode) {
//			if let width = node["width"]?.stringValue {
//				if !Layout.keywords.contains(width) {
//					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
//					if width.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
////						if widthIdentifiers[width] == nil {
////							widthIdentifiers[width] = [GravityNode]()
////						}
////						widthIdentifiers[width]?.append(node)
//					} else {
//						if let width = node.width {
//							NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
//								node.constraints["width"] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat(width))
//							}
//						}
//					}
//				}
//			}
			
//		public override func preprocessAttribute(node: GravityNode, attribute: String, inout value: GravityNode) -> GravityResult {
//			NSLog(attribute)
//			// TODO: can we do anything with node values here?
//			guard let stringValue = value.stringValue else {
//				return .NotHandled
//			}
			
//			switch attribute {
				// TODO: may want to set these with higher priority than default to avoid view/container bindings conflicting
				// we should also capture these priorities as constants and put them all in one place for easier tweaking and balancing
//				case "width":
//					if !Layout.keywords.contains(stringValue) {
//						let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
//						if stringValue.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
////							if widthIdentifiers[stringValue] == nil {
////								widthIdentifiers[stringValue] = [GravityNode]()
////							}
////							widthIdentifiers[stringValue]?.append(node)
//						} else {
//							NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
//								node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((stringValue as NSString).floatValue))
//							}
//						}
//					}
//					return .Handled
				
				if let width = node.width {
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints["width"] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat(width))
					}
				}
						
				if let minWidth = node.minWidth {
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints["minWidth"] = node.view.autoSetDimension(.Width, toSize: CGFloat(minWidth), relation: .GreaterThanOrEqual)
					}
					NSLayoutConstraint.autoSetPriority(50) {//test
						node.view.autoSetDimension(.Width, toSize: CGFloat(minWidth))
					}
				}
				
				if let maxWidth = node.maxWidth {
					if node.isOtherwiseFilledAlongAxis(.Horizontal) {
							// a maxWidth that is filled is equal to an explicit width
						NSLayoutConstraint.autoSetPriority(700) {
							// FIXME: *HOWEVER* it should have lesser priority than the fill binding because it may still be smaller if the fill size is < maxWidth!
							NSLog("filled maxWidth found")
							node.constraints["maxWidth"] = node.view.autoSetDimension(.Width, toSize: CGFloat(maxWidth))
						}
//						NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
//							// experimental (we need to keep a maxWidth inside a filled view contained to that filled view, at a higher priority than typical view containment)
//							// FIXME: we might want to move this to postprocess so it can bind to the parent view properly
//							node.view.autoPinEdgeToSuperviewEdge(.Left, withInset: CGFloat(node.leftInset))
//							node.view.autoPinEdgeToSuperviewEdge(.Right, withInset: CGFloat(node.rightInset))
//						}
					} else {
						NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
							node.constraints["maxWidth"] = node.view.autoSetDimension(.Width, toSize: CGFloat(maxWidth), relation: .LessThanOrEqual)
						}
					}
				}
				
				if let height = node.height {
//					if !Layout.keywords.contains(stringValue) {
						// TODO: add support for height identifiers
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints["height"] = node.view.autoSetDimension(.Height, toSize: CGFloat(height))
					}
//					}
				}
				
				if let minHeight = node.minHeight {
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) {
						node.constraints["minHeight"] = node.view.autoSetDimension(.Height, toSize: CGFloat(minHeight), relation: .GreaterThanOrEqual)
					}
					NSLayoutConstraint.autoSetPriority(50) {//test
						node.view.autoSetDimension(.Height, toSize: CGFloat(minHeight))
					}
				}
				
				if let maxHeight = node.maxHeight {
					NSLayoutConstraint.autoSetPriority(GravityPriority.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
						if node.isOtherwiseFilledAlongAxis(.Vertical) {
							// a maxWidth that is filled is equal to an explicit width
							NSLog("filled maxHeight found")
							node.constraints["maxHeight"] = node.view.autoSetDimension(.Height, toSize: CGFloat(maxHeight))
						} else {
							node.constraints["maxHeight"] = node.view.autoSetDimension(.Height, toSize: CGFloat(maxHeight), relation: .LessThanOrEqual)
						}
					}
				}
				
//				case "margin":
//					return .Handled
//				
//				case "padding":
//					return .Handled
//				
//				case "shrinks":
//					return .Handled
//				
//				default:
//					return .NotHandled
//			}
		}
		
		public override func processContents(node: GravityNode) -> GravityResult {
			if !node.viewIsInstantiated {
				return .NotHandled // no default child handling if we don't have a valid view
			}
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
				
//				let leftInset = CGFloat(node.leftMargin + node.leftPadding)
//				let rightInset = CGFloat(node.rightMargin + node.rightPadding)
	
				NSLayoutConstraint.autoSetPriority(GravityPriority.Gravity) {
					switch childNode.gravity.horizontal {
						case .Left:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: CGFloat(childNode.leftInset))
							break
						
						case .Center:
							let constraint = childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
							constraint.constant = CGFloat(childNode.rightInset - childNode.leftInset); // test (not working)
							break
						
						case .Right:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: CGFloat(childNode.rightInset))
							break
						
						default:
							break
					}
					
					switch childNode.gravity.vertical {
						case .Top:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: CGFloat(childNode.topInset))
							break
						
						case .Middle:
							childNode.view.autoAlignAxisToSuperviewAxis(ALAxis.Horizontal)
							break
						
						case .Bottom:
							childNode.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: CGFloat(childNode.bottomInset))
							break
						
						default:
							break
					}
				}
			}
			
			return .Handled
		}
		
		public override func postprocessNode(node: GravityNode) {
		
			// FIXME: put widthIdentifiers back in here somewhere
			
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
						node.constraints["view-left"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: CGFloat(node.leftInset), relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-left")
						node.constraints["view-right"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: CGFloat(node.rightInset), relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-right")
					}
				}
				
				if (node.view.superview as? UIStackView)?.axis != .Vertical { // we are not inside a stack view (of the same axis)
					node.view.autoMatchDimension(.Height, toDimension: .Height, ofView: node.parentNode!.view, withOffset: 0, relation: .LessThanOrEqual)
					
					var priority = GravityPriority.ViewContainment + Float(node.recursiveDepth)
					
					if node.isDivergentAlongAxis(.Vertical) {
						priority = 200 + Float(node.recursiveDepth)
					}
					
					NSLayoutConstraint.autoSetPriority(priority) {
						node.constraints["view-top"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: CGFloat(node.topInset), relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-top")
						node.constraints["view-bottom"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: CGFloat(node.bottomInset), relation: NSLayoutRelation.Equal).autoIdentify("gravity-view-bottom")
					}
				}
				
				// minWidth, etc. should probably be higher priority than these so they can override fill size
				if node.isOtherwiseFilledAlongAxis(.Horizontal) {
					node.view.setContentHuggingPriority(GravityPriority.FillSizeHugging, forAxis: .Horizontal)
					if (node.view.superview as? UIStackView)?.axis != .Horizontal {
						NSLayoutConstraint.autoSetPriority(GravityPriority.FillSize - Float(node.recursiveDepth)) {
		//					node.view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: node.view.superview)
							node.constraints["fill-left"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left, withInset: CGFloat(node.leftInset)).autoIdentify("gravity-fill-left") // leading?
							node.constraints["fill-right"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right, withInset: CGFloat(node.rightInset)).autoIdentify("gravity-fill-right") // trailing?
						}
					}
				}
				
				if node.isFilledAlongAxis(.Vertical) {
					node.view.setContentHuggingPriority(GravityPriority.FillSizeHugging, forAxis: .Vertical)
					if (node.view.superview as? UIStackView)?.axis != .Vertical {
						NSLayoutConstraint.autoSetPriority(GravityPriority.FillSize - Float(node.recursiveDepth)) {
		//					node.view.autoMatchDimension(ALDimension.Height, toDimension: ALDimension.Height, ofView: node.view.superview)
							node.constraints["fill-top"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top, withInset: CGFloat(node.topInset)).autoIdentify("gravity-fill-top")
							node.constraints["fill-bottom"] = node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom, withInset: CGFloat(node.topInset)).autoIdentify("gravity-fill-bottom")
						}
					}
				}
			
			} else {
				NSLog("superview nil")
			}
			
			// do we need/want to set content hugging if superview is nil?
		}
		
//		public override func postprocessDocument(document: GravityDocument) {
//			NSLog("postprocessDocument: \(document.node.nodeName)")
//			
//			var widthIdentifiers = [String: GravityNode]()
			
//			for node in document.node {
//				if let width = node["width"]?.stringValue {
//					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
//					if width.rangeOfCharacterFromSet(charset) != nil {
//						if let archetype = widthIdentifiers[width] {
//							NSLog("Matching dimension of \(unsafeAddressOf(node)) to \(unsafeAddressOf(archetype)).")
//							// TODO: add a gravity priority
//							node.view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: archetype.view)
//						} else {
//							widthIdentifiers[width] = node
//						}
//					}
//				}
//			}
			
//			for (identifier, nodes) in widthIdentifiers {
//				let first = nodes[0]
//				for var i = 1; i < nodes.count; i++ {
//					// priority?? also we need to add a constraint (but what should its identifier be?)
//					NSLog("Matching dimension of \(unsafeAddressOf(nodes[i])) to \(unsafeAddressOf(first)).")
//					nodes[i].view.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: first.view)
//				}
//			}
//		}
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
	
	init?(_ stringValue: String?) {
		guard let stringValue = stringValue else {
			return nil
		}
		
		let valueParts = stringValue.lowercaseString.componentsSeparatedByString(" ")
		
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
extension UIView {
	var grav_alignmentRectInsets: UIEdgeInsets {
		get {
			var insets = self.grav_alignmentRectInsets
			
			if let node = self.gravityNode {
				insets = UIEdgeInsetsMake(insets.top - CGFloat(node.topMargin), insets.left - CGFloat(node.leftMargin), insets.bottom - CGFloat(node.bottomMargin), insets.right - CGFloat(node.rightMargin))
			}
			
			return insets
		}
	}
}

@available(iOS 9.0, *)
extension GravityNode {
	// MARK: Debugging
	
	internal var leftInset: Float {
		get { return (parentNode?.leftMargin ?? 0) + (parentNode?.leftPadding ?? 0) }
	}
	
	internal var topInset: Float {
		get { return (parentNode?.topMargin ?? 0) + (parentNode?.topPadding ?? 0) }
	}
	
	internal var rightInset: Float {
		get { return (parentNode?.rightMargin ?? 0) + (parentNode?.rightPadding ?? 0) }
	}
	
	internal var bottomInset: Float {
		get { return (parentNode?.bottomMargin ?? 0) + (parentNode?.bottomPadding ?? 0) }
	}
	
	// MARK: Public
	public var gravity: GravityDirection {
		get {
			var gravity = GravityDirection(self["gravity"]?.stringValue) ?? GravityDirection()
			
			if gravity.horizontal == .Inherit {
				gravity.horizontal = parentNode?.gravity.horizontal ?? .Center
			}
			if gravity.vertical == .Inherit {
				gravity.vertical = parentNode?.gravity.vertical ?? .Middle
			}
			
			return gravity
		}
	}
	
	public var width: Float? {
		get {
			return self["width"]?.floatValue // verify this is nil for a string, also test "123test" etc.
		}
	}
	
	public var height: Float? {
		get {
			return self["height"]?.floatValue
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
	
	public var margin: Float {
		get {
			return self["margin"]?.floatValue ?? 0
		}
	}
	
	public var leftMargin: Float {
		get {
			return self["leftMargin"]?.floatValue ?? self.margin
		}
	}
	
	public var topMargin: Float {
		get {
			return self["topMargin"]?.floatValue ?? self.margin
		}
	}
	
	public var rightMargin: Float {
		get {
			return self["rightMargin"]?.floatValue ?? self.margin
		}
	}
	
	public var bottomMargin: Float {
		get {
			return self["bottomMargin"]?.floatValue ?? self.margin
		}
	}
	
	public var padding: Float {
		get {
			return self["padding"]?.floatValue ?? 0
		}
	}
	
	public var leftPadding: Float {
		get {
			return self["leftPadding"]?.floatValue ?? self.padding
		}
	}
	
	public var topPadding: Float {
		get {
			return self["topPadding"]?.floatValue ?? self.padding
		}
	}
	
	public var rightPadding: Float {
		get {
			return self["rightPadding"]?.floatValue ?? self.padding
		}
	}
	
	public var bottomPadding: Float {
		get {
			return self["bottomPadding"]?.floatValue ?? self.padding
		}
	}
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"]?.stringValue ?? "0")!
		}
	}
	
	internal func isExplicitlySizedAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		switch axis {
			case .Horizontal:
				if let width = self["width"]?.stringValue {
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if width.rangeOfCharacterFromSet(charset) == nil {
						return true
					}
				}
				return false
			
			case .Vertical:
				if let height = self["height"]?.stringValue {
					let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
					if height.rangeOfCharacterFromSet(charset) == nil {
						return true
					}
				}
				return false
		}
	}
	
	/// A node is divergent from its parent on an axis if it has the potential that at least one edge of that axis is not bound to its corresponding parent edge. For example, an auto-sized node inside a fixed size node has the potential to be smaller than its container, and is therefore considered divergent.
	internal func isDivergentAlongAxis(axis: UILayoutConstraintAxis) -> Bool {
		if parentNode != nil && parentNode!.parentNode != nil && document.parentNode != nil {
			return true
		}
		
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
				
				if let width = self["width"]?.stringValue {
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
				
				if let height = self["height"]?.stringValue {
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