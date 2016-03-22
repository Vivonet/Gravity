//
//  UITableView+Gravity.swift
//  GravityAssist
//
//  Created by Logan Murray on 2016-02-21.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

extension UITableView: GravityElement, UITableViewDataSource {
	public var recognizedAttributes: [String]? {
		get {
			return ["rowTemplate"]
		}
	}//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
//		switch attribute {
//			case "rowTemplate":
//				return .Handled
//			
//			default:
//				return .NotHandled
//		}
//	}
	
	public func processElement(node: GravityNode) {
		self.dataSource = self
//		self.delegate = self
//		return .NotHandled
	}
	
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1 // how should we do sections?
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 0
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		return UITableViewCell()
	}
}