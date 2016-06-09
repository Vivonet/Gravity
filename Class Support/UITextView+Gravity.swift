//
//  UITextView+Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-10.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
extension UITextView: GravityElement {
//	public var recognizedAttributes: [String]? {
//		get {
//			return []
//		}
//	}
	
//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
//		return .NotHandled
//	}
	
	public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
//		self.scrollEnabled = false // FIXME: do this in postprocess node or whatever
		
		return .NotHandled
	}
}