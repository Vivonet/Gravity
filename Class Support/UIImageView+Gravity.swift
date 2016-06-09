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
	
//	public func processElement(node: GravityNode) {
	public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
		
//		let color = node.color
		if attribute == "image" || attribute == nil {
			if let imageName = value?.stringValue {
				self.image = UIImage(named: imageName)?.imageWithRenderingMode(node["template"]?.boolValue == true ? .AlwaysTemplate : .AlwaysOriginal)
				return .Handled
			} else {
				self.image = nil
			}
		}
		
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
	
	public func postprocessNode(node: GravityNode) {
		self.layer.minificationFilter = kCAFilterTrilinear // improves UIImageView rendering
		
		if node["contentMode"] == nil { // would this be easier as a preprocess (default)? maybe not because we don't want to reset it every time unless we're processing that attribute
			self.contentMode = UIViewContentMode.ScaleAspectFit // this is a much saner default
		}
		if node["tintColor"] == nil { // maybe this should be done generally for all views
			self.tintColor = node.color // is this the best way/place to handle these defaults? should we have an initializing call?
		}
	}
}