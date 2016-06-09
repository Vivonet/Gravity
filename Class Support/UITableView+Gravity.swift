//
//  UITableView+Gravity.swift
//  GravityAssist
//
//  Created by Logan Murray on 2016-02-21.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// is there perhaps a better way we could set the dataSource of tables created with gravity without extending the UITableView class itself?
// perhaps we should create a gravity helper class
extension UITableView: GravityElement, UITableViewDataSource {
	public class func initializeGravity() {
		Gravity.swizzle(UITableViewCell.self, original: #selector(UITableViewCell.setHighlighted(_:animated:)), override: #selector(UITableViewCell.grav_setHighlighted(_:animated:)))
		Gravity.swizzle(UITableViewCell.self, original: #selector(UITableViewCell.setSelected(_:animated:)), override: #selector(UITableViewCell.grav_setSelected(_:animated:)))
	}
	
	public var recognizedAttributes: [String]? {
		get {
			return ["rowTemplate"]
		}
	}

//	public func processAttribute(node: GravityNode, attribute: String, value: GravityNode) -> GravityResult {
	public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
		return .NotHandled
	}
	
	// should we rename this to something like init or setup?
	public func postprocessNode(node: GravityNode) {
		self.dataSource = self
//		self.delegate = self
//		return .NotHandled
		
//		self.selectionsty
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
//		cell.selectionStyle = .None
		
		if let collection = gravityNode?.model as? Array<AnyObject> {
//			let cellDoc = GravityDocument("InventoryCell", model: collection[indexPath.row])
			// FIXME: this is adding the view to the view hierarhcy too early; we need to be in control of adding it, and postprocessing when added
			// perhaps time to swizzle didmovetosuperview?
			let cellDoc = gravityNode?["rowTemplate"]?.instantiate(collection[indexPath.row])
			if let cellView = cellDoc?.view {
//				cellView.translatesAutoresizingMaskIntoConstraints = false
//			if let cellView = Gravity.instantiate("InventoryCell", model: collection[indexPath.row]) {
//			if let cellView = gravityNode?["rowTemplate"]?.instantiate(collection[indexPath.row]).view {
				cell.contentView.addSubview(cellView)
//				cell.contentView = cellView
				cellView.autoPinEdgesToSuperviewEdges()
			}
		}
		return cell
	}
}

extension UITableViewCell {
	func grav_setSelected(selected: Bool, animated: Bool) {
		grav_setSelected(selected, animated: animated)
		
		if contentView.subviews.isEmpty {
			return
		}
		
		if let gravityNode = contentView.subviews[0].gravityNode as GravityNode? {
			UIView.animateWithDuration(animated ? 0.3 : 0.0) { // this is definitely not the best way to do this (is there a default animation or something??)
				gravityNode[":selected"] = selected ? true : false // dear swift, your bizarre special meaning of literals does not make for an enjoyable programming experience; no other language would require this nonsense
			}
		}
	}
	
	func grav_setHighlighted(highlighted: Bool, animated: Bool) {
		grav_setHighlighted(highlighted, animated: animated)
		
		if contentView.subviews.isEmpty {
			return
		}
		
		if let gravityNode = contentView.subviews[0].gravityNode as GravityNode? {
			UIView.animateWithDuration(animated ? 0.3 : 0) {
				gravityNode[":highlighted"] = highlighted ? true : false
				
				// this gives precedence to highlighted over selected when both are true:
				if highlighted {
					gravityNode[":selected"] = false
				} else {
					gravityNode[":selected"] = self.selected ? true : false // unreal.
				}
				print("Highlighted: \(highlighted)")
			}
		}		
	}
}