//
//  UIView+Gravity.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-11.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

private var GravityNodeAssociatedObjectKey = 0

@available(iOS 9.0, *)
extension UIView {
	/// Gravity adds this stored property to all instances of `UIView`.
	/// - Returns: The `GravityNode` object that was used to instantiate the receiving view, or `nil` if it was not created by Gravity.
	public var gravityNode: GravityNode {
		get {
			return objc_getAssociatedObject(self, &GravityNodeAssociatedObjectKey) as! GravityNode
		}
		set(value) {
			objc_setAssociatedObject(self, &GravityNodeAssociatedObjectKey, value, .OBJC_ASSOCIATION_ASSIGN) // i believe this should be weak since the view is created and managed by the GravityNode
		}
	}
}