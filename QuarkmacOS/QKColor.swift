//
//  QKColor.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 11/15/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
class QKColor: NSObject, Color {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    required init(red: Double, green: Double, blue: Double, alpha: Double) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

extension Color {
    /// Returns an `NSColor` instance equivalent to this `Color`
    public var nsColor: NSColor {
        return NSColor(
            red: red.cgFloat,
            green: green.cgFloat,
            blue: blue.cgFloat,
            alpha: alpha.cgFloat
        )
    }
    
    /**
     Creates a `Color` equivalent to the `NSColor`.
     
     - parameter nsColor: The `NSColor` to convert to a `QKColor`
     */
    public init(nsColor: NSColor) {
        let color = nsColor.usingColorSpace(.genericRGB)! // Adjust the color to generic RGB
        self.init(
            red: color.redComponent.double,
            green: color.greenComponent.double,
            blue: color.blueComponent.double,
            alpha: color.alphaComponent.double
        )
    }
}
