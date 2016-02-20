//
//  Styling.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-15.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// Gravity.Styling.registerStyle(...)

// should i move this into Appearance?

@available(iOS 9.0, *)
extension Gravity {
	@objc public class Styling: GravityPlugin {
		static var styles = Dictionary<String, (UIView) -> ()>() // styles by class name, e.g. "UIButton" TODO: add support for style classes too, e.g. style="styleClass"
		// styles can also be used to do any post processing on an element after initialization; it doesn't have to be style related, though we should probably use plugins for that in general
		// i wonder if we can use this or a similar concept to set up data binding/templating (we'd probably need to track changes somehow)
		
		public class func registerStyle(style: (UIView) -> (), forType type: AnyClass) {
			styles["\(type)"] = style
		}
	}
}