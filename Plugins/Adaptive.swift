//
//  Adaptive.swift
//  Gravity
//
//  Created by Logan Murray on 2016-03-01.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

// TODO: add support for a sizeClass attribute and registering size classes as ranges of horizontal and vertical sizes.
// the ranges shouldn't need to be contiguous: we should snap to the most-applicable size class
// we should also support adaptive design by allowing completely different layouts for different size classes (not just different attributes within one layout)
extension Gravity {
	@objc public class Adaptive: GravityPlugin {
		static var documents = Set<GravityDocument>() // TODO: make this weak somehow, or unregister with a proper hook
		// this also needs to be optimized; only true root nodes need to have this set
		
		public static override func initialize() {
			UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
			NSNotificationCenter.defaultCenter().addObserverForName(UIDeviceOrientationDidChangeNotification, object: nil, queue: nil) { (notification: NSNotification) in
				if UIDevice.currentDevice().orientation.isPortrait {
					for document in Adaptive.documents {
						// TODO: add the condition back so these aren't processed as local attributes
						document.node["portrait"] = true
						document.node["landscape"] = false
					}
				} else if UIDevice.currentDevice().orientation.isLandscape {
					for document in Adaptive.documents {
						document.node["landscape"] = true
						document.node["portrait"] = false
					}
				}
			}
		}
		
		// this is a load cycle hook
		public override func preprocessValue(value: GravityNode) -> GravityResult {
			guard let attributeName = value.attributeName else {
				return .NotHandled
			}
			
			if !attributeName.containsString(":") {
				return .NotHandled
			}
			
			// TODO: if a static condition is true, re-add the attribute without that condition, removing any equivalent existing attribute
			
			let attributeParts = attributeName.componentsSeparatedByString(":")
			let rootAttribute = attributeParts.first!
			let conditions = Set(attributeParts.suffixFrom(1))
			let idiom = UIDevice.currentDevice().userInterfaceIdiom
			
			for condition in conditions {
				let remainingConditions = conditions.subtract([condition])
				switch condition {
					case "phone":
						if idiom == .Phone {
							let newAttribute = ([rootAttribute] + remainingConditions).joinWithSeparator(":")
							assert(newAttribute.hasPrefix(rootAttribute))
							NSLog("New attribute: \(newAttribute)")
							value.parentNode?.setAttribute(newAttribute, value: value)
						}
						return .Handled
					
					case "pad":
						if idiom == .Pad {
							let newAttribute = ([rootAttribute] + remainingConditions).joinWithSeparator(":")
							assert(newAttribute.hasPrefix(rootAttribute))
							NSLog("New attribute: \(newAttribute)")
							value.parentNode?.setAttribute(newAttribute, value: value)
						}
						return .Handled
					
					case "tv":
						if idiom != .TV {
							value.include = false
							// we probably want to do this in a better way then .include, unless the load cycle checks this explicitly and removes the node
							// any false *static* conditions should remove a node completely and permanently from the static dom
						}
						return .Handled
					
					case "carPlay":
						if idiom != .CarPlay {
							value.include = false
						}
						return .Handled
					
					default:
						break
				}
			}
			
			return .NotHandled
		}
		
		public override func postprocessDocument(document: GravityDocument) {
			// we can't do this (yet anyway) because despite the child document having a link to the parent, the converse is not always true: instantiated row templates for example are not (currently) pointed to from their parent tableview element
//			if document.parentNode != nil {
//				return
//			}
			
			Adaptive.documents.insert(document)
			
			// these are all static; we should consider removing these at static load time
//			switch UIDevice.currentDevice().userInterfaceIdiom {
//				case .Phone:
//					document.node["phone"] = true
//					break
//				
//				case .Pad:
//					document.node["pad"] = true
//					break
//				
//				case .TV:
//					document.node["tv"] = true
//					break
//				
//				case .CarPlay:
//					document.node["carPlay"] = true
//					break
//				
//				case .Unspecified:
//					break
//			}
		}
	}
}