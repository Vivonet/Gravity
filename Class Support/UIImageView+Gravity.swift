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
	public func processAttribute(node: GravityNode, attribute: String, value: AnyObject?, stringValue: String) -> GravityResult {
		switch attribute {
			case "image":
				self.image = UIImage(named: stringValue)?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
				return .Handled
				
			default:
				break
		}
		
		return .NotHandled
	}
	
	public func processElement(node: GravityNode) -> GravityResult {
		self.contentMode = UIViewContentMode.ScaleAspectFit
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