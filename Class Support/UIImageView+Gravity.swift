//
//  UIImageView+Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UIImageView: GravityElement {
	// do we really need this at all?
	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
		guard let textValue = value.textValue else {
			return .NotHandled
		}
		
		switch attribute {
			case "image":
				self.image = UIImage(named: textValue)?.imageWithRenderingMode(node["template"]?.boolValue == true ? .AlwaysTemplate : .AlwaysOriginal)
				return .Handled
			
			case "template":
				// handled above
				return .Handled
				
			default:
				break
		}
		
		return .NotHandled
	}
	
	public func processElement(node: GravityNode) -> GravityResult {
		if node["contentMode"] == nil {
			self.contentMode = UIViewContentMode.ScaleAspectFit // this is a much saner default
		}
		self.layer.minificationFilter = kCAFilterTrilinear // improves UIImageView rendering
		self.tintColor = node.color
		
//////						UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//////							imageView.autoSetContentCompressionResistancePriorityForAxis(ALAxis.Horizontal)
//////							imageView.autoSetContentHuggingPriorityForAxis(ALAxis.Horizontal)
//////						})
//////						[UIView autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
//////    [myImageView autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
//////    [myImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
//////}];

		return .NotHandled
	}
}