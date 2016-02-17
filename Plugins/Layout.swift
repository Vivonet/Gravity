//
//  Layout.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

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
		
		public override func preprocessAttribute(node: GravityNode, attribute: String, inout value: String) -> GravityResult {
			switch attribute {
				// TODO: may want to set these with higher priority than default to avoid view/container bindings conflicting
				// we should also capture these priorities as constants and put them all in one place for easier tweaking and balancing
				case "width":
					if !Layout.keywords.contains(value) {
						let charset = NSCharacterSet(charactersInString: "-0123456789.").invertedSet
						if value.rangeOfCharacterFromSet(charset) != nil { // if the value contains any characters other than numeric characters
							if widthIdentifiers[value] == nil {
								widthIdentifiers[value] = [GravityNode]()
							}
							widthIdentifiers[value]?.append(node)
						} else {
							UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
								node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue))
							}
						}
					}
					return .Handled
				
				case "minWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
					return .Handled
				
				case "maxWidth":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) { // these have to be higher priority than the normal and fill binding to parent edges
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Width, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
					return .Handled
				
				case "height":
					if !Layout.keywords.contains(value) {
						UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
							node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue))
						}
					}
					return .Handled
				
				case "minHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.GreaterThanOrEqual)
					}
					return .Handled
				
				case "maxHeight":
					UIView.autoSetPriority(GravityPriorities.ExplicitSize) {
						node.constraints[attribute] = node.view.autoSetDimension(ALDimension.Height, toSize: CGFloat((value as NSString).floatValue), relation: NSLayoutRelation.LessThanOrEqual)
					}
					return .Handled
				
				// move to styling??
				case "cornerRadius":
					// TODO: add support for multiple radii, e.g. "5 10", "8 4 10 4"
					node.view.layer.cornerRadius = CGFloat((value as NSString).floatValue)
					node.view.clipsToBounds = true // assume this is still needed
					return .Handled
				
				default:
					return .NotHandled
			}
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