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
		private var widthIdentifiers = [String: [GravityNode]]()
		
		public override func instantiateElement(node: GravityNode) -> UIView? {
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
				
				// move to styling??
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					node.view.layer.cornerRadius = CGFloat((textValue as NSString).floatValue)
					node.view.clipsToBounds = true // assume this is still needed
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
					// experimental: only apply these implicit constraints if the parent is not filled
					
					// i swear, childNode.parentNode should be self should it not???
					
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
			// is this ok here?
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

@available(iOS 9.0, *)
extension GravityNode {
	public var gravity: GravityDirection {
		get {
			return GravityDirection(getScopedAttribute("gravity")?.textValue ?? "top left")
		}
	}
	
	public var zIndex: Int {
		get {
			return Int(attributes["zIndex"]?.textValue ?? "0")!
		}
	}
}