//
//  GravityViewController.swift
//  Gravity
//
//  Created by Logan Murray on 2016-02-03.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import Foundation

/// A simple view controller designed to host a Gravity document. The supplied Gravity layout is made to fill the entire available screen space and adjusts automatically to support the keyboard.
@available(iOS 9.0, *)
@objc
public class GravityViewController: UIViewController {
	public var document: GravityDocument? = nil

	var bottomPin: NSLayoutConstraint?

//	init(xml: String, model: AnyObject? = nil) {
//		super.init(nibName: nil, bundle: nil)
//		document = GravityDocument(xml: xml, model: model)
//		setup()
//	}
	
	init(name: String, model: AnyObject? = nil) {
		super.init(nibName: nil, bundle: nil)
		document = GravityDocument(name: name, model: model)
		setup()
	}
	
//	override func didReceiveMemoryWarning() {
//		super.didReceiveMemoryWarning()
//		// Dispose of any resources that can be recreated.
//		self.view = nil
//	}
	
	private func setup() {
		view.backgroundColor = UIColor.whiteColor()
		document?.controller = self // does this make sense? if we subclass, yes
		
		if let document = document {
//			document.node.attributes["width"] = GravityNode(document: document, parentNode: document.node, nodeName: "", textValue: "fill");
//			document.node.attributes["height"] = GravityNode(document: document, parentNode: document.node, nodeName: "", textValue: "fill");
			view.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(document.view)
//			UIView.autoSetPriority(150) { // must be less than (bubble fill priority - depth)
//				document.view.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: ALEdge.Bottom)
				document.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
				document.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
				document.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
//				document.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)

				self.bottomPin = document.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
//			}
			
			// read current keyboard frame?
			
			// TODO: figure out if we can do this without duplicating the gravity code
			// any way we can do this in postprocess or use a low-priority host binding for documents to their containers?
			UIView.autoSetPriority(GravityPriority.Gravity) {
				switch document.node.gravity.horizontal {
					case .Left:
						document.node.view.autoPinEdgeToSuperviewEdge(ALEdge.Left)
						break
					
					case .Center:
						document.node.view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
						break
					
					case .Right:
						document.node.view.autoPinEdgeToSuperviewEdge(ALEdge.Right)
						break
					
					default:
						break
				}
				
				switch document.node.gravity.vertical {
					case .Top:
						document.node.view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
						break
					
					case .Middle:
						document.node.view.autoAlignAxisToSuperviewAxis(ALAxis.Horizontal)
						break
					
					case .Bottom:
						document.node.view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
						break
					
					default:
						break
				}
			}
			
			if document.view.hasAmbiguousLayout() {
				NSLog("WARNING: Document view is ambiguous!!")
			}
		}
		
//		document?.postprocess()
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	
	public override func prefersStatusBarHidden() -> Bool {
		return true // temp
	}
	
	@objc private func keyboardWillChangeFrame(notification: NSNotification) {
		guard let keyboardFrame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey]?.CGRectValue else {
			return
		}
		guard let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue else {
			return
		}
		guard let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey]?.integerValue else {
			return
		}
		
		let intersection = CGRectIntersection(keyboardFrame, view.bounds)
		let bottomOffset = intersection.size.height
		NSLog("Offset: \(bottomOffset)")
		bottomPin!.constant = -bottomOffset
		
		UIView.beginAnimations("GravityViewController keyboard frame adjust", context: nil)
		UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: curve) ?? UIViewAnimationCurve.EaseInOut)
		UIView.setAnimationBeginsFromCurrentState(true)
		UIView.setAnimationDuration(duration)
		
		view.layoutIfNeeded()

		UIView.commitAnimations()
	}
}