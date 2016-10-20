//
//  QKView.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/13/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

/*
 Can't do this because of @objc:
 
 class QKKView<ViewType: NSView> {
    var underlyingView: ViewType? = nil
 }
 */

@objc
public class QKView: NSObject, View {
    /// Returns the underlying `NSView` for the `QKView`
    public var nsView: NSView
    
    /**
     Creates a new `QKView` with an underlying `NSView`.
 
     - parameter nsView: The `NSView` that drives the `QKView`.
     */
    public init(nsView view: NSView) throws {
        nsView = view
    }
    
    required public override convenience init() {
        try! self.init(nsView: NSView()) // TODO: Safety
    }
}

/* Positioning */
extension QKView {
    public var rect: Rect {
        get {
            return QKRect(cgRect: nsView.frame)
        }
        set {
            nsView.frame = newValue.cgRect
        }
    }
}

/* View hierarchy */
extension QKView {
    public var subviews: [View] {
        return nsView.subviews.map { try! QKView(nsView: $0) } // TODO: Safety
    }
    
    public var superview: View? {
        if let superview = nsView.superview {
            return try! QKView(nsView: superview) // TODO: Safety
        } else {
            return nil
        }
    }
    
    public func addSubview(_ view: View) {
        if let view = view as? QKView {
            nsView.addSubview(view.nsView)
        } else {
            // TODO: Handle error
            print("Invalid view type.")
        }
    }
    
    public func removeFromSuperview() {
        nsView.removeFromSuperview()
    }
}

/* Layout */
extension QKView {
    public func layout() {
        // TODO: This
    }
}

/* Visibility */
extension QKView {
    public var hidden: Bool {
        get {
            return nsView.isHidden
        }
        set {
            nsView.isHidden = newValue
        }
    }
}

/* Style */
extension QKView {
    public var alpha: Double {
        get {
            return nsView.alphaValue.double
        }
        set {
            nsView.alphaValue = newValue.cgFloat
        }
    }
    
    public var shadow: Shadow {
        get {
            return QKShadow(nsShadow: nsView.shadow!)
        }
        set {
            nsView.shadow = newValue.nsShadow
        }
    }
    
    public var cornerRadius: Double {
        get {
            return nsView.layer!.cornerRadius.double
        }
        set {
            nsView.layer!.cornerRadius = newValue.cgFloat
        }
    }
}

