//
//  QKPoint.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
public class QKPoint: NSObject, Point {
    public var x: Double
    public var y: Double
    
    public required init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public extension Point {
    /// Returns a `CGPoint` instance equivalent to this `Point`
    public var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    /**
     Creates a `Point` equivalent to the `CGPoint`.
     
     - parameter cgPoint: The `CGPoint` to convert to a `QKPoint`
     */
    public init(cgPoint: CGPoint) {
        self.init(x: Double(cgPoint.x), y: Double(cgPoint.y))
    }
}
