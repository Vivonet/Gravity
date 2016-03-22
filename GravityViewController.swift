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
	public var document: GravityDocument// = nil

	var bottomPin: NSLayoutConstraint?

//	init(xml: String, model: AnyObject? = nil) {
//		super.init(nibName: nil, bundle: nil)
//		document = GravityDocument(xml: xml, model: model)
//		setup()
//	}

	// TODO: should we consider instantiating a gvc with a view? do we really need to have a document?

	init(document: GravityDocument) {
		self.document = document
		super.init(nibName: nil, bundle: nil)
		setup()
	}
	
	init(name: String, model: AnyObject? = nil) {
		document = GravityDocument(name, model: model)
		super.init(nibName: nil, bundle: nil)
		setup()
	}
	
//	override func didReceiveMemoryWarning() {
//		super.didReceiveMemoryWarning()
//		// Dispose of any resources that can be recreated.
//		self.view = nil
//	}
	
	private func setup() {
		view.backgroundColor = UIColor.whiteColor()
		document.controller = self // does this make sense? if we subclass, yes
		
		var documentView: UIView?
		if document.error == nil {
			documentView = document.view
		} else if let error = document.error {
			let errorDoc = GravityDocument("GravityError", model: error)
			documentView = errorDoc.view
		}
		
		if let documentView = documentView {
			view.translatesAutoresizingMaskIntoConstraints = false
			view.addSubview(documentView)
			
			// FIXME: this is broken with embedded view controllers
			// we need to swizzle didMoveToSuperview and handle this there recursively
			// and also do the proper view controller binding
			documentView.autoPinEdgeToSuperviewEdge(ALEdge.Left)
			documentView.autoPinEdgeToSuperviewEdge(ALEdge.Top)
			documentView.autoPinEdgeToSuperviewEdge(ALEdge.Right)

			self.bottomPin = documentView.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
			
			if documentView.hasAmbiguousLayout() {
				NSLog("WARNING: Document view is ambiguous!!")
			}
		}
		
		// read current keyboard frame?
	}

	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public override func viewDidLoad() {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillChangeFrame:"), name: UIKeyboardWillChangeFrameNotification, object: nil)
	}
	
	public override func prefersStatusBarHidden() -> Bool {
		return true // temp -- should we make this an appearance attribute that only applies to view controllers? we may have to swizzle it.
		// this may be a good use case for having root nodes in a document: it would allow us to specify such an attribute on the root of a layout
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