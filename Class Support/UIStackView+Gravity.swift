//
//  UIStackView+Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UIStackView: GravityElement, GravityPlugin {

	// unfortunately this doesn't seem to want to work:
//	override public class func initialize() {
//		Gravity.registerPlugin(self)
//	}
	
	public static func instantiateElement(node: GravityNode) -> UIView? {
		switch node.nodeName {
			case "H":
				let stackView = UIStackView()
				stackView.axis = UILayoutConstraintAxis.Horizontal
				return stackView
			
			case "V":
				let stackView = UIStackView()
				stackView.axis = UILayoutConstraintAxis.Vertical
				return stackView
			
			default:
				return nil
		}
	}

	// reorder to attribute, value, node?
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		switch attribute {
			case "axis":
				switch value.lowercaseString {
					case "horizontal", "h":
						self.axis = UILayoutConstraintAxis.Horizontal
						return true
					
					case "vertical", "v":
						self.axis = UILayoutConstraintAxis.Vertical
						return true
					
					default:
						break
				}
			
			case "alignment":
				switch value.lowercaseString {
					case "center":
						self.alignment = UIStackViewAlignment.Center
						return true
					
					case "fill":
						self.alignment = UIStackViewAlignment.Fill
						return true
					
					case "top":
						self.alignment = UIStackViewAlignment.Top
						return true
					
					case "trailing":
						self.alignment = UIStackViewAlignment.Trailing
						return true
					
					default:
						break
				}
			
			default:
				break
		}
		
		return false//super.processAttribute(gravity, attribute: attribute, value: value)
	}
	
	public func processElement(node: GravityNode) -> Bool {
		if node.attributes["alignment"] == nil { // only if alignment is not explicitly set
			if self.axis == UILayoutConstraintAxis.Horizontal {
				switch node.gravity.vertical {
					case GravityDirection.Top:
						self.alignment = UIStackViewAlignment.Top
						break
					case GravityDirection.Middle:
						self.alignment = UIStackViewAlignment.Center
						break
					case GravityDirection.Bottom:
						self.alignment = UIStackViewAlignment.Bottom
						break
//					case GravityDirection.Tall:
//						self.alignment = UIStackViewAlignment.Fill
//						break
					default:
						break // throw?
				}
			} else {
				switch node.gravity.horizontal {
					case GravityDirection.Left:
						self.alignment = UIStackViewAlignment.Leading
						break
					case GravityDirection.Center:
						self.alignment = UIStackViewAlignment.Center
						break
					case GravityDirection.Right:
						self.alignment = UIStackViewAlignment.Trailing
						break
//					case GravityDirection.Tall:
//						self.alignment = UIStackViewAlignment.Fill
//						break
					default:
						break // throw?
				}
			}
		}
		
		var fillChild: GravityNode? = nil
		
		for childNode in node.childNodes {
			addArrangedSubview(childNode.view)
			if childNode.isFilledAlongAxis(axis) {
				if fillChild != nil {
					NSLog("Warning: Only one child of a stack view may be filled along the axis of the stack view, due to limitations of the stack view. Gravity will arbitrarily choose the first child tree to fill.")
				} else {
					fillChild = childNode
				}
			}
//			childNode.view.setContentHuggingPriority(750 /*- Float(elementStack.count)*/, forAxis: self.axis) // TODO: do we need to implement node.depth?
		}
		
		// TODO: abstract this into a method (maybe not anymore)
		// MARK: Content Compression Resistance
		let baseCompressionResistance = Float(750)
		var shrinkIndex = [Int: GravityNode]()
		for childNode in node.childNodes {
			// no idea why i need the ! here:
			let rank = Int(childNode.attributes["shrinks"] ?? "0")! //gravity.elementMetadata[subview]!.shrinks
			let adjustedIndex = rank == 0 ? 0 : (1000 - abs(rank)) * (rank > 0 ? -1 : 1)
//			NSLog("rank %d adjusted to %d", rank, adjustedIndex)
			shrinkIndex[adjustedIndex] = childNode
		}
		let sortedShrinks = shrinkIndex.sort({ (first: (Int, GravityNode), second: (Int, GravityNode)) -> Bool in
			return first.0 < second.0
		})
		for var i = 0; i < sortedShrinks.count; i++ {
//				let shrinkTuple = sortedShrinks[i]
//			guard let subview = 
			var compressionResistance: Float
			if i > 0 && sortedShrinks[i].0 == sortedShrinks[i-1].0 {
				compressionResistance = sortedShrinks[i-1].1.view.contentCompressionResistancePriorityForAxis(self.axis)
			} else {
				compressionResistance = baseCompressionResistance + Float(i) / Float(sortedShrinks.count)
			}
			sortedShrinks[i].1.view.setContentCompressionResistancePriority(compressionResistance, forAxis: self.axis)
//			NSLog("%d: %f", sortedShrinks[i].0, compressionResistance)
		}
		
		// MARK: Content Hugging
		// i'm not sure we even need a "grows" attribute at all now with fill size. if we want an element to grow we should just set its width="fill"
//		let baseContentHugging = Float(200)
//		var growIndex = [Int: GravityNode]()
//		for childNode in node.childNodes {
//			let rank = Int(childNode.attributes["grows"] ?? "0")!
//			let adjustedIndex = rank == 0 ? 0 : (1000 - abs(rank)) * (rank > 0 ? -1 : 1)
//			NSLog("rank %d adjusted to %d", rank, adjustedIndex)
//			growIndex[adjustedIndex] = childNode
//		}
//		let sortedGrows = growIndex.sort({ (first: (Int, GravityNode), second: (Int, GravityNode)) -> Bool in
//			return first.0 < second.0
//		})
//		for var i = 0; i < sortedGrows.count; i++ {
////				let shrinkTuple = sortedShrinks[i]
//			var contentHugging: Float
//			if i > 0 && sortedGrows[i].0 == sortedGrows[i-1].0 {
//				contentHugging = sortedGrows[i-1].1.view.contentHuggingPriorityForAxis(self.axis)
//			} else {
//				contentHugging = baseContentHugging + Float(i) / Float(sortedGrows.count)
//			}
//			sortedGrows[i].1.view.setContentHuggingPriority(contentHugging, forAxis: self.axis)
//			NSLog("%d: %f", sortedGrows[i].0, contentHugging)
//		}
		
		// TODO: clean this code up
		let spacer = UIView()
//		spacer.text="?"
//		spacer.backgroundColor = UIColor.magentaColor().colorWithAlphaComponent(0.5)
//			spacer.text = "hi"
		spacer.userInteractionEnabled = false
		spacer.setContentHuggingPriority(100, forAxis: self.axis) // must be higher than fill size hugging priority
		
//			spacer.autoSetDimension(stackView.axis == UILayoutConstraintAxis.Horizontal ? ALDimension.Width : ALDimension.Height, toSize: 100000)
//			spacer.setContentCompressionResistancePriority(100 - Float(stack.count), forAxis: stackView.axis)

//			spacer.setContentHuggingPriority(100-Float(elementStack.count), forAxis: stackView.axis) // does this do anything?

//			spacer.autoSetDimension(ALDimension.Width, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)
//			spacer.autoSetDimension(ALDimension.Height, toSize: 0, relation: NSLayoutRelation.GreaterThanOrEqual)

//			spacer.backgroundColor = colorForStackLevel(stack.count)

		// note that we probably only want to do this for certain gravities
		if self.axis == UILayoutConstraintAxis.Horizontal && node.gravity.horizontal == GravityDirection.Right || self.axis == UILayoutConstraintAxis.Vertical && node.gravity.vertical == GravityDirection.Bottom {
			self.insertArrangedSubview(spacer, atIndex: 0)
		} else if self.axis == UILayoutConstraintAxis.Horizontal && node.gravity.horizontal == GravityDirection.Left || self.axis == UILayoutConstraintAxis.Vertical && node.gravity.vertical == GravityDirection.Top {
			self.addArrangedSubview(spacer) // add an empty view to act as a space filler
		}
		
		return true
	}
}