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

/*
 - Extensions will return JavaScript structures for everything
 - For arrays, need an adapter so it doesn't generate an entire array every time you index it
    - e.g. suviews
    - JavaScript: view.subviews[0] will make the program take every subview and convert it to JS then be thrown back into the garbage collector
    - Make ArrayAdapter<JSView> { index: Int in return view.subviews[index].jsView }
    - Then when JavaSript wants to subscript it, do view.subviews.atIndex(0)
    - Or get the whole thing by view.subviews.all() (goes through every item and converts it)
 */

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

extension NSView: View {
    /* JavaScript Interop */
    public var jsView: JSValue? {
        get {
            return nil
        }
        set {
            
        }
    }
    
    /* Positioning */
    public var jsRect: JSValue {
        get {
            guard let rect = JSRect(context: Quark.context, cgRect: frame)?.value else {
                print("Unable to convert CGRect.")
                return JSValue()
            }
            return rect
        }
        set {
            guard let rect = JSRect(value: newValue) else {
                print("Invalid JSRect.")
                return
            }
            frame = rect.cgRect
        }
    }
    
    /* View hierarchy */
    public var jsSubviews: [JSValue] {
        get {
            return subviews
                .map { $0.readOrCreateJSView(context: Quark.context) }
                .filter { $0 != nil }.map { $0! } // Filter out the nil values
        }
    }
    
    public var jsSuperview: JSValue? {
        return superview?.readOrCreateJSView(context: Quark.context)
    }
    
    public func jsAddSubview(_ view: JSValue) {
        guard let nsView = JSView(value: view)?.nsView else {
            Swift.print("Could not get NSView for adding subview. \(JSView(value: view))")
            return
        }
        addSubview(nsView)
    }
    
    public func jsRemoveFromSuperview() {
        removeFromSuperview()
    }
    
    /* Visibility */
    public var jsHidden: Bool {
        get {
            return isHidden
        }
        set {
            isHidden = newValue
        }
    }
    
    /* Style */
    public var jsBackgroundColor: JSValue {
        get {
            let color: NSColor
            if let cgColor = assuredLayer.backgroundColor, let nsColor = NSColor(cgColor: cgColor) {
                color = nsColor
            } else {
                color = NSColor.clear
            }
            return JSColor(context: Quark.context, nsColor: color)?.value ?? JSValue()
        }
        set {
            assuredLayer.backgroundColor = JSColor(value: newValue)?.nsColor.cgColor
        }
    }
    public var jsAlpha: Double {
        get {
            return jsAlpha
        }
        set {
            jsAlpha = newValue
        }
    }
    public var jsShadow: JSValue {
        get {
            guard
                let nsShadow = self.shadow,
                let shadow = JSShadow(context: Quark.context, nsShadow: nsShadow)
            else {
                    print("Could not get shadow.")
                    return JSValue()
            }
            return shadow.value
        }
        set {
            shadow = JSShadow(value: newValue)?.nsShadow
        }
    }
    public var jsCornerRadius: Double {
        get {
            return Double(layer!.cornerRadius)
        }
        set {
            layer?.cornerRadius = CGFloat(newValue)
        }
    }
    
    /* TODO: Animations like SpriteKit */
    
    /* Initiator */
    /// Creates a new view with a JSView.
    public convenience init(jsView: JSValue) {
        self.init()
    }
}

extension NSView {
    /// Returns or creates the NSView's layer.
    var assuredLayer: CALayer {
        if let layer = layer {
            // Return the existing layer
            return layer
        } else {
            // Create a layer
            wantsLayer = true
            
            // Recursively ask for layer again, since it should exist now
            return assuredLayer
        }
    }
}

//@objc
//public class QKView: NSObject, View {
//    /// Returns the underlying `NSView` for the `QKView`
//    public private(set) var nsView: NSView
//    public var caLayer: CALayer {
//        if let layer = nsView.layer { // Return the existing layer
//            return layer
//        } else { // Add a new layer and return it
//            return addLayer()
//        }
//    }
//    
//    private var _jsView: JSValue?
//    public var jsView: JSValue? {
//        if let jsView = _jsView {
//            return jsView
//        } else if let jsView = self.makeJSView(context: contex)
//    }
//    
//    /**
//     Creates a new `QKView` with an underlying `NSView`.
//     
//     - parameter nsView: The `NSView` that drives the `QKView`.
//     */
//    public init(nsView view: NSView) throws {
//        // Set the view
//        nsView = view
//        
//        super.init()
//        
//        // Add a layer if needed
//        if view.layer == nil {
//            _ = addLayer()
//        }
//        
//        // Register the events
//        registerEvents()
//    }
//    
//    /**
//     Creates a new `QKView` with an empty `NSView`.
//     */
//    required public override convenience init() {
//        try! self.init(nsView: NSView())
//    }
//    
//    /**
//     Creates a new `QKView` with a given JavaScript view.
//     */
//    required public convenience init(jsView: JSValue) {
//        self.init()
//        self.jsView = jsView
//    }
//    
//    deinit {
//        // Remove from `NotificationCenter`
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    /// Registers the events for the `NSView`.
//    private func registerEvents() {
//        // Register a notification listener for the frame change
//        nsView.postsFrameChangedNotifications = true
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(frameChanged),
//            name: Notification.Name.NSViewFrameDidChange,
//            object: nil
//        )
//    }
//    
//    /// Adds a layer to the NSView.
//    private func addLayer() -> CALayer {
//        // Creates a layer
//        let layer = CALayer()
//        nsView.wantsLayer = true
//        nsView.layer = layer
//        return layer
//    }
//    
//    /// Listens for frame changes on the view.
//    @objc private func frameChanged(notification: Notification) {
//        // Test if the associated view is this view (use `equal()` because
//        // it's more efficient than optionally casing to `NSView` then checking
//        // equality)
//        if nsView.isEqual(notification.object) {
//            // Tell the layout handler to layout
//            frameChangedHandler?.call(withArguments: [self])
//        }
//    }
//    
//    // MARK: Positioning
//    public var rect: Rect {
//        get {
//            return QKRect(cgRect: nsView.frame)
//        }
//        set {
//            nsView.frame = newValue.cgRect
//        }
//    }
//    
//    // MARK: View heiarchy
//    public var subviews: [View] {
//        return nsView.subviews.map { try! QKView(nsView: $0) } // TODO: Safety
//    }
//    
//    public var superview: View? {
//        if let superview = nsView.superview {
//            return try! QKView(nsView: superview) // TODO: Safety
//        } else {
//            return nil
//        }
//    }
//    
//    public func addSubview(_ view: View) {
//        if let view = view as? QKView {
//            nsView.addSubview(view.nsView)
//        } else {
//            // TODO: Handle error
//            print("Invalid view type.")
//        }
//    }
//    
//    public func removeFromSuperview() {
//        nsView.removeFromSuperview()
//    }
//    
//    // MARK: Layout
//    public var frameChangedHandler: JSValue?
//    
//    // MARK: Visibility
//    public var hidden: Bool {
//        get {
//            return nsView.isHidden
//        }
//        set {
//            nsView.isHidden = newValue
//        }
//    }
//    
//    // MARK: Style
//    public var backgroundColor: Color {
//        get {
//            if
//                let cgColor = caLayer.backgroundColor,
//                let nsColor = NSColor(cgColor: cgColor)
//            { // Attempt to get background
//                return QKColor(nsColor: nsColor)
//            } else { // Could not get layer
//                return QKColor(nsColor: NSColor.clear)
//            }
//        }
//        set {
//            caLayer.backgroundColor = newValue.nsColor.cgColor
//        }
//    }
//    public var alpha: Double {
//        get {
//            return nsView.alphaValue.double
//        }
//        set {
//            nsView.alphaValue = newValue.cgFloat
//        }
//    }
//    
//    public var shadow: Shadow {
//        get {
//            return QKShadow(nsShadow: nsView.shadow!)
//        }
//        set {
//            nsView.shadow = newValue.nsShadow
//        }
//    }
//    
//    public var cornerRadius: Double {
//        get {
//            return nsView.layer!.cornerRadius.double
//        }
//        set {
//            nsView.layer!.cornerRadius = newValue.cgFloat
//        }
//    }
//}
