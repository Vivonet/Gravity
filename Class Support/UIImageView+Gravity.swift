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

//	public var recognizedAttributes: [String]? {
//		get {
//			return ["image", "template"]
//		}
//	}
	
// do we really need this at all?
//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
//		guard let stringValue = value.stringValue else {
//			return .NotHandled
//		}
//		
//		switch attribute {
//			case "image":
//				self.image = UIImage(named: stringValue)?.imageWithRenderingMode(node["template"]?.boolValue == true ? .AlwaysTemplate : .AlwaysOriginal)
//				return .Handled
//			
//			case "template":
//				// handled above
//				return .Handled
//				
//			default:
//				break
//		}
//		
//		return .NotHandled
//	}
	
	public func processElement(node: GravityNode) {
		if node["contentMode"] == nil {
			self.contentMode = UIViewContentMode.ScaleAspectFit // this is a much saner default
		}
		self.layer.minificationFilter = kCAFilterTrilinear // improves UIImageView rendering
		
//		let color = node.color
		self.tintColor = node.color
		
		if let imageName = node["image"]?.stringValue {
			self.image = UIImage(named: imageName)?.imageWithRenderingMode(node["template"]?.boolValue == true ? .AlwaysTemplate : .AlwaysOriginal)
		}
		
//////						UIView.autoSetPriority(UILayoutPriorityRequired, forConstraints: { () -> Void in
//////							imageView.autoSetContentCompressionResistancePriorityForAxis(ALAxis.Horizontal)
//////							imageView.autoSetContentHuggingPriorityForAxis(ALAxis.Horizontal)
//////						})
//////						[UIView autoSetPriority:ALLayoutPriorityRequired forConstraints:^{
//////    [myImageView autoSetContentCompressionResistancePriorityForAxis:ALAxisHorizontal];
//////    [myImageView autoSetContentHuggingPriorityForAxis:ALAxisHorizontal];
//////}];

//		return .NotHandled
	}
}