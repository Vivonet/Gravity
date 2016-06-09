//
//  UINavigationController+Gravity.swift
//  GravityAssist
//
//  Created by Logan Murray on 2016-03-12.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

extension UINavigationController: GravityElement {
//	public var recognizedAttributes: [String]? {
//		get { return [] }
//	}
	
//	public static func instantiateView(node: GravityNode) -> UIView? {
//		let instance = UINavigationController()
//		node.controller = instance
//		return instance.view
//	}
	
//	public func processElement(node: GravityNode) {
	public func handleAttribute(node: GravityNode, attribute: String?, value: GravityNode?) -> GravityResult {
		NSLog(node["rootViewController"]?.description ?? "")
		
//		// TODO: figure out how to handle/default contents here
//		if attribute == nil || attribute == "rootViewController" {
//			if let rootView = value {
//				let newDoc = rootView.instantiate()
//				let gvc = GravityViewController(document: newDoc)
//				gvc.view.translatesAutoresizingMaskIntoConstraints = false
////				self.addChildViewController(gvc)
//				self.pop
//				self.pushViewController(gvc, animated: true)
//			} else {
//				self.remove
//			}
//		}
		return .NotHandled
	}
	
	
	
//	public func processContents(node: GravityNode) {
//		// override so gravity doesn't keep trying
//	
////		for childNode in node.childNodes {
////			let subdoc = node.instantiate()
////			let gvc = GravityViewController(document: subdoc)
////			self.addChildViewController(gvc)
////		}
//	}
}