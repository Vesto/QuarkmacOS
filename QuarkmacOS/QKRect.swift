//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
class QKRect: NSObject, Rect {
    var origin: Point
    var size: Size
    
    required init(origin: Point, size: Size) {
        self.origin = origin
        self.size = size
    }
}

extension Rect {
    /// Returns a `CGRect` equivilent to this `QKRect`
    var cgRect: CGRect {
        return CGRect(origin: origin.cgPoint, size: size.cgSize)
    }
    
    /**
     Creates a `Rect` equivalent to the `CGRect`.
     
     - parameter cgRect: The `CGRect` to convert to a `Rect`
     */
    public init(cgRect: CGRect) {
        self.init(
            origin: QKPoint(cgPoint: cgRect.origin),
            size: QKSize(cgSize: cgRect.size)
        )
    }
}
