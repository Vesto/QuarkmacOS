//
//  QKView.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/13/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkCore

/*
 - For arrays, need an adapter so it doesn't generate an entire array every time you index it
    - e.g. subviews
    - JavaScript: view.subviews[0] will make the program take every subview and convert it to JS then be thrown back into the garbage collector
    - Make ArrayAdapter<JSView> { index: Int in return view.subviews[index].jsView }
    - Then when JavaSript wants to subscript it, do view.subviews.atIndex(0)
    - Or get the whole thing by view.subviews.all() (goes through every item and converts it)
 - Add parameter callsMethods to determine if the NSView should call the native methods (e.g. if there is a subclass that it should be, otherwise just don't call it at all, default to false)
 - Maybe find a way to determine if there should be a designated JSValue stored on the NSView
    - Maybe just have JavaScript assign the jsView themselves so the subclasses cand do it
    - Or do it in the View constructor if the QKView is nil and it creates it
 */

extension NSView {
    /// `JSContext` that holds the `JSValue` for this view.
    public var context: JSContext? {
        return jsView?.context
    }

    /// `QKInstance` that this view belongs to.
    public var instance: QKInstance? {
        return context?.instance
    }
}

extension NSView: Swizzlable {
    fileprivate struct AssociatedKeys {
        static var HasInitialized = "HasInitialized"
        static var HasSwizzled = "HasSwizzled"
    }

    public static var swizzled: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasSwizzled) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.HasSwizzled,
                    newValue,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    public static func swizzle() {
        hookTo(original: #selector(viewWillMove(toWindow:)), swizzled: #selector(qk_viewWillMove(toWindow:)))
        hookTo(original: #selector(layout), swizzled: #selector(qk_layout))
    }
    
    func qk_viewWillMove(toWindow newWindow: NSWindow?) {
        self.qk_viewWillMove(toWindow: newWindow)
        
        qk_init()
    }

    internal func qk_layout() {
        self.qk_layout()

        _ = jsView?.invokeMethod("layout", withArguments: [])
    }
    
    internal private(set) var hasInitialized: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasInitialized) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.HasInitialized,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }

    internal func qk_init() {
        // Assure it has not initiated yet
        guard !hasInitialized else {
            return
        }
        
        // Set initiated
        hasInitialized = true

        // Flag this view needs `layout` called
        needsLayout = true
    }
}

extension NSView: View {
    /* JavaScript Interop */
    public var jsView: JSValue? {
        get {
            return jsValue
        }
        set {
            jsValue = newValue
        }
    }
    
    /* Positioning */
    public var jsRect: JSValue {
        get {
            guard
                let instance = instance,
                let rect = JSRect(instance: instance, cgRect: frame)?.value
            else {
                Swift.print("Unable to convert CGRect.")
                return JSValue()
            }
            return rect
        }
        set {
            guard let rect = JSRect(value: newValue) else {
                Swift.print("Invalid JSRect.")
                return
            }
            frame = rect.cgRect
        }
    }
    
    /* View hierarchy */
    public var jsSubviews: [JSValue] {
        get {
            guard let instance = instance else {
                Swift.print("Cannot get instance for jsSubviews.")
                return []
            }
            
            return subviews.map { $0.readOrCreateJSValue(instance: instance) }
        }
    }
    
    public var jsSuperview: JSValue? {
        guard let instance = instance else {
            Swift.print("Cannot get instance for jsSuperview.")
            return nil
        }
        
        return superview?.readOrCreateJSValue(instance: instance)
    }
    
    public func jsAddSubview(_ view: JSValue) {
        guard let nsView = JSView(value: view)?.nsView else {
            Swift.print("Could not get NSView for adding subview. \(view)")
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
            guard let instance = instance else {
                Swift.print("Could not get instance for background color.")
                return JSValue()
            }
            
            let color: NSColor
            if let cgColor = assuredLayer.backgroundColor, let nsColor = NSColor(cgColor: cgColor) {
                color = nsColor
            } else {
                color = NSColor.clear
            }
            return JSColor(instance: instance, nsColor: color)?.value ?? JSValue()
        }
        set {
            assuredLayer.backgroundColor = JSColor(value: newValue)?.nsColor.cgColor
        }
    }
    public var jsAlpha: Double {
        get {
            return alphaValue.double
        }
        set {
            alphaValue = newValue.cgFloat
        }
    }
    public var jsShadow: JSValue {
        get {
            guard
                let instance = instance,
                let nsShadow = self.shadow,
                let shadow = JSShadow(instance: instance, nsShadow: nsShadow)
            else {
                    Swift.print("Could not get shadow.")
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
            return assuredLayer.cornerRadius.double
        }
        set {
            assuredLayer.cornerRadius = CGFloat(newValue)
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
    // This is here because `createJSValue` cannot be overriden on a protocol for some reason.
    public static func createJSValue(instance: QKInstance) -> JSValue? {
        return NSView.createJSView(instance: instance)?.value
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
            
            // Return the new layer
            return layer!
        }
    }
}
