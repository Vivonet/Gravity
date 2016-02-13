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
	public func processAttribute(node: GravityNode, attribute: String, value: String) -> Bool {
		return false
	}
	
	public func processElement(node: GravityNode) -> Bool {
		self.scrollEnabled = false
		
		return false
	}
}