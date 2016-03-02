//
//  AppDelegate.swift
//  Gravity Demo
//
//  Created by Logan Murray on 2016-03-01.
//  Copyright © 2016 Logan Murray. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		self.window = Gravity.start("Main")
		return true
	}
}
