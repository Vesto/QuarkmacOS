//
//  CGSize+Quark.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
public class QKSize: NSObject, Size {
    public var width: Double = 0.0
    
    public var height: Double = 0.0
    
    public required init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

extension Size {
    /// Returns a `CGSize` instance equivalent to this `QKSize`
    public var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
    
    /**
     Creates a `Size` equivalent to the `CGSize`.
     
     - parameter cgPoint: The `CGSize` to convert to a `QKSize`
     */
    public init(cgSize: CGSize) {
        self.init(width: Double(cgSize.width), height: Double(cgSize.height))
    }
}
