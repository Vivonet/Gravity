//
//  Default.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// do we really need/want this class? maybe rename?

extension Gravity {
	@objc public class Default: GravityPlugin {
		private static let keywords = ["id", "zIndex", "gravity"] // add more? move?
		// TODO: these should ideally be blocked at the same location they are used (e.g. zIndex and gravity in Layout, id should be blocked in the kernel.
		
		public override func preprocessAttribute(node: GravityNode, attribute: String, inout value: String) -> GravityResult {
			if Default.keywords.contains(attribute) {
				return .Handled
			}
			
			return .NotHandled
		}
		
		public override func postprocessAttribute(node: GravityNode, attribute: String, value: AnyObject) {
			if tryBlock({
				node.view.setValue(value, forKeyPath: attribute)
			}) != nil {
				NSLog("Warning: Key path '\(attribute)' not found on object \(node.view).")
			}
		}
	}
}