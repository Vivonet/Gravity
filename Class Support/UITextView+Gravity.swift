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
	
	public func processElement(node: GravityNode) {
		self.scrollEnabled = false
		
//		return .NotHandled
	}
}