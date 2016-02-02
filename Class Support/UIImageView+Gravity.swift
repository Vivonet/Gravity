//
//  UIImageView+Gravity.swift
//  Mobile
//
//  Created by Logan Murray on 2016-01-27.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UIImageView: GravityElement {
	// do we really need this at all?
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		switch attribute {
			case "image":
				self.image = UIImage(named: value)?.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
				return true
				
			default:
				break
		}
		
		return false
	}
	
	public func processElement(node: GravityNode) -> Bool {
		self.contentMode = UIViewContentMode.ScaleAspectFit
//		self.translatesAutoresizingMaskIntoConstraints = false
		self.tintColor = node.color
		
//////						UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//////							imageView.autoSetContentCompressionResistancePriorityForAxis(ALAxis.Horizontal)
//////							imageView.autoSetContentHuggingPriorityForAxis(ALAxis.Horizontal)
//////						})
//////						[UIView autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
//////    [myImageView autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
//////    [myImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
//////}];

		return false
	}
}