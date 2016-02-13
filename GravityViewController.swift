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

	var bottomPin: NSLayoutConstraint?

	public var document: GravityDocument? = nil
//	public var keyboardView = UIView()
//		get {
//			return super.view as? GravityView
//		}
//		set(value) {
//			super.view = value
//		}
//	}

	init(xml: String) {
		super.init(nibName: nil, bundle: nil)
		document = GravityDocument(xml: xml)
		setup()
	}
	
	init(name: String) {
		super.init(nibName: nil, bundle: nil)
		document = GravityDocument(name: name)
		setup()
	}
	
	private func setup() {
		view.backgroundColor = UIColor.whiteColor()
//		gravityView?.translatesAutoresizingMaskIntoConstraints = false
		document?.controller = self
		
		if let rootNodeView = document?.rootNodeView {
			view.addSubview(rootNodeView) // TODO: fix this
	//		gravityView?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
			rootNodeView.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: ALEdge.Bottom)
			
			// read current keyboard frame?
			
			bottomPin = rootNodeView.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
		}
		
		document?.postProcess()
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
//	public override var view: GravityView
	public override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
//		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardFrameChanged:"), name: UIKeyboardDidChangeFrameNotification, object: nil)
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
		
		UIView.beginAnimations("GravityView keyboard frame adjust", context: nil)
		UIView.setAnimationCurve(UIViewAnimationCurve(rawValue: curve) ?? UIViewAnimationCurve.EaseInOut)
		UIView.setAnimationBeginsFromCurrentState(true)
		UIView.setAnimationDuration(duration)
		
		view.layoutIfNeeded()

		UIView.commitAnimations()
	}
}