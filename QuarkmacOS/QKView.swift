//
//  QKView.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/13/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkExports

/*
 Can't do this because of @objc:
 
 class QKKView<ViewType: NSView> {
    var underlyingView: ViewType? = nil
 }
 */

public protocol NSViewOverrideProtocol {
    // Callbacks
    var layoutCallback: (() -> Void)? { get set }
    
    // `NSView`-specific properties
    var frame: CGRect { get set }
    var isHidden: Bool { get set }
    var alphaValue: CGFloat { get set }
    var layer: CALayer? { get set }
    var wantsLayer: Bool { get set }
    var shadow: NSShadow? { get set }
    var superview: NSView? { get }
    var subviews: [NSView] { get }
    func addSubview(_ view: NSView)
    func removeFromSuperview()
}

/// An override class that manages things only subclasses can do.
public class NSViewOverride: NSView, NSViewOverrideProtocol {
    // Callbacks
    public var layoutCallback: (() -> Void)?
    
    // Overrides
    public override func layout() {
        super.layout()
        
        layoutCallback?()
    }
}

@objc
public class QKView: NSObject, View {
    /// Returns the underlying `NSView` for the `QKView`
    public private(set) var nsView: NSViewOverrideProtocol
    public var caLayer: CALayer {
        if let layer = nsView.layer { // Return the existing layer
            return layer
        } else { // Add a new layer and return it
            return addLayer()
        }
    }
    
    /**
     Creates a new `QKView` with an underlying `NSView`.
 
     - parameter nsView: The `NSView` that drives the `QKView`.
     */
    public init(nsView view: NSViewOverrideProtocol) throws {
        // Set the view
        nsView = view
        
        super.init()
        
        // Add a layer if needed
        if view.layer == nil {
            _ = addLayer()
        }
    }
    
    /**
     Creates a new `QKView` with an empty `NSView`.
     */
    required public override convenience init() {
        try! self.init(nsView: NSViewOverride())
    }
    
    /// Adds a layer to the NSView.
    private func addLayer() -> CALayer {
        // Creates a layer
        let layer = CALayer()
        nsView.wantsLayer = true
        nsView.layer = layer
        return layer
    }
    
    /// Adds callbacks to the `NSViewOverride`.
    private func addOverrideCallbacks() {
        nsView.layoutCallback = {
            
        }
    }

    // MARK: - Positioning
    public var rect: Rect {
        get {
            return QKRect(cgRect: nsView.frame)
        }
        set {
            nsView.frame = newValue.cgRect
        }
    }
    
    // MARK: - View heiarchy
    public var subviews: [View] {
        return nsView.subviews
            .filter { $0 is NSViewOverride } // Filter to `NSViewOverride`
            .map { try! QKView(nsView: $0 as! NSViewOverride) } // Map to `QKView`
    }
    
    public var superview: View? {
        if let superview = nsView.superview as? NSViewOverride {
            return try! QKView(nsView: superview) // TODO: Safety
        } else {
            return nil
        }
    }
    
    public func addSubview(_ view: View) {
        if let view = view as? QKView, let nsView = view.nsView as? NSView {
            nsView.addSubview(nsView)
        } else {
            // TODO: Handle error
            print("Invalid view type.")
        }
    }
    
    public func removeFromSuperview() {
        nsView.removeFromSuperview()
    }
    
    // MARK: - Layout
    public var layoutCallback: JSValue?
    
    // MARK: - Visibility
    public var hidden: Bool {
        get {
            return nsView.isHidden
        }
        set {
            nsView.isHidden = newValue
        }
    }
    
    // MARK: - Style
    public var backgroundColor: Color {
        get {
            if
                let cgColor = caLayer.backgroundColor,
                let nsColor = NSColor(cgColor: cgColor)
            { // Attempt to get background
                return QKColor(nsColor: nsColor)
            } else { // Could not get layer
                return QKColor(nsColor: NSColor.clear)
            }
        }
        set {
            caLayer.backgroundColor = newValue.nsColor.cgColor
        }
    }
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

