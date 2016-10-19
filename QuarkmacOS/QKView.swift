//
//  QKView.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/13/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports

@objc
public class QKView: NSObject, View {
    var underlyingView: NSView
    
    init(underlyingView view: NSView) {
        underlyingView = view
    }
}

/* Positioning */
extension QKView {
    public var rect: Rect {
        get {
            return QKRect(cgRect: underlyingView.frame)
        }
        set {
            underlyingView.frame = newValue.cgRect
        }
    }
}

/* View hierarchy */
extension QKView {
    public var subviews: [View] {
        return underlyingView.subviews.map { QKView(underlyingView: $0) }
    }
    
    public var superview: View? {
        if let superview = underlyingView.superview {
            return QKView(underlyingView: superview)
        } else {
            return nil
        }
    }
    
    public func addSubview(view: View) {
        
    }
    
    public func removeFromSuperview() {
        
    }
}

/* Layout */
extension QKView {
    public func layout() {
        
    }
}

/* Visibility */
extension QKView {
    public var hidden: Bool {
        get {
            return underlyingView.isHidden
        }
        set {
            underlyingView.isHidden = newValue
        }
    }
}

/* Style */
extension QKView {
    public var alpha: Double {
        get {
            return underlyingView.alphaValue.double
        }
        set {
            underlyingView.alphaValue = newValue.cgFloat
        }
    }
    
    public var shadow: Shadow {
        get {
            return QKShadow(nsShadow: underlyingView.shadow!)
        }
        set {
            underlyingView.shadow = newValue.nsShadow
        }
    }
    
    public var cornerRadius: Double {
        get {
            return underlyingView.layer!.cornerRadius.double
        }
        set {
            underlyingView.layer!.cornerRadius = newValue.cgFloat
        }
    }
}

