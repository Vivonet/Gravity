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