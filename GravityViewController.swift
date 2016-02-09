//
//  GravityViewController.swift
//  Mobile
//
//  Created by Logan Murray on 2016-02-03.
//  Copyright © 2016 The Little Software Company. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@objc
public class GravityViewController: UIViewController {

	var bottomPin: NSLayoutConstraint?

	public var gravityView: GravityView? = nil
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
		gravityView = GravityView(xml: xml)
		setup()
	}
	
	init(filename: String) {
		super.init(nibName: nil, bundle: nil)
		gravityView = GravityView(filename: filename)
		setup()
	}
	
	private func setup() {
		view.backgroundColor = UIColor.whiteColor()
//		gravityView?.translatesAutoresizingMaskIntoConstraints = false
		gravityView?.controller = self
		view.addSubview(gravityView!)
//		gravityView?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero)
		gravityView?.autoPinEdgesToSuperviewEdgesWithInsets(UIEdgeInsetsZero, excludingEdge: ALEdge.Bottom)
		
		// read current keyboard frame?
		
		bottomPin = (gravityView?.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)!)! // <- what the fuck is going on here?!
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