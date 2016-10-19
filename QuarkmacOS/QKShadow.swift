//
//  QKShadow.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/19/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
public class QKShadow: NSObject, Shadow {
    public var offset: Point
    public var blurRadius: Double
    
    public required init(offset: Point, blurRadius: Double) {
        self.offset = offset
        self.blurRadius = blurRadius
    }
}

extension Shadow {
    /// Returns an `NSShadow` instance equivalent to this `Shadow`
    public var nsShadow: NSShadow {
        let shadow = NSShadow()
        shadow.shadowOffset = NSSize(
            width: offset.x.cgFloat,
            height: offset.y.cgFloat
        )
        shadow.shadowBlurRadius = blurRadius.cgFloat
        return shadow
    }
    
    /**
     Creates a `Shadow` equivalent to the `NSShadow`.
     
     - parameter nsShadow: The `NSShadow` to convert to a `QKShadow`
     */
    public init(nsShadow: NSShadow) {
        self.init(
            offset: QKPoint(
                x: nsShadow.shadowOffset.width.double,
                y: nsShadow.shadowOffset.height.double
            ),
            blurRadius: nsShadow.shadowBlurRadius.double
        )
    }
}
