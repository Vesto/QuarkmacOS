//
//  JSAdapter+Cocoa.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 11/25/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import JavaScriptCore
import QuarkExports

extension JSRect {
    var cgRect: CGRect {
        guard let point = point, let size = size else {
            print("Invalid JSRect point or size.")
            return CGRect.zero
        }
        
        return CGRect(origin: point.cgPoint, size: size.cgSize)
    }
    
    convenience init?(context: JSContext, cgRect: CGRect) {
        // Get the point and size
        guard
            let point = JSPoint(context: context, cgPoint: cgRect.origin),
            let size = JSSize(context: context, cgSize: cgRect.size)
            else {
                return nil
        }
        
        self.init(context: context, point: point, size: size)
    }
}

extension JSPoint {
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    convenience init?(context: JSContext, cgPoint: CGPoint) {
        self.init(context: context, x: cgPoint.x.double, y: cgPoint.y.double)
    }
}

extension JSSize {
    var cgSize: CGSize {
        return CGSize(width: width, height: height)
    }
    
    convenience init?(context: JSContext, cgSize: CGSize) {
        self.init(context: context, width: cgSize.width.double, height: cgSize.height.double)
    }
}

extension JSColor {
    var nsColor: NSColor {
        return NSColor(red: red.cgFloat, green: green.cgFloat, blue: blue.cgFloat, alpha: alpha.cgFloat)
    }
    
    convenience init?(context: JSContext, nsColor: NSColor) {
        let color = nsColor.usingColorSpaceName(NSCalibratedRGBColorSpace)!
        self.init(
            context: context,
            red: color.redComponent.double,
            green: color.greenComponent.double,
            blue: color.blueComponent.double,
            alpha: color.alphaComponent.double
        )
    }
}

extension JSShadow {
    var nsShadow: NSShadow {
        let shadow = NSShadow()
        let shadowOffset = offset?.cgPoint ?? CGPoint.zero
        shadow.shadowOffset = NSSize(width: shadowOffset.x, height: shadowOffset.y)
        shadow.shadowBlurRadius = blurRadius.cgFloat
        shadow.shadowColor = color?.nsColor
        return shadow
    }
    
    convenience init?(context: JSContext, nsShadow: NSShadow) {
        guard
            let point = JSPoint(
                context: context,
                cgPoint: CGPoint(x: nsShadow.shadowOffset.width, y: nsShadow.shadowOffset.height)
            ),
            let shadowColor = nsShadow.shadowColor,
            let color = JSColor(context: context, nsColor: shadowColor)
            else {
                return nil
        }
        self.init(
            context: context,
            offset: point,
            blurRadius: nsShadow.shadowBlurRadius.double,
            color: color
        )
    }
}
