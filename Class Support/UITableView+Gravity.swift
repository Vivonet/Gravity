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
	}

//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
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
	
	// MARK: UITableViewDataSource
	
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1 // how should we do sections?
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if let collection = gravityNode?.model as? Array<AnyObject> {
			return collection.count
		}
		return 0
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//		return UITableViewCell()
		let cell = UITableViewCell()
		
		if let collection = gravityNode?.model as? Array<AnyObject> {
//			let cellDoc = GravityDocument("InventoryCell", model: collection[indexPath.row])
//			if let cellView = cellDoc.view {
//			if let cellView = Gravity.instantiate("InventoryCell", model: collection[indexPath.row]) {
			if let cellView = gravityNode?["rowTemplate"]?.instantiate(collection[indexPath.row]).view {
				cell.contentView.addSubview(cellView)
				cellView.autoPinEdgesToSuperviewEdges()
			}
		}
		return cell
	}
}