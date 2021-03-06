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
        return jsValue?.context
    }

    /// `QKInstance` that this view belongs to.
    public var instance: QKInstance? {
        return context?.instance
    }
}

extension NSView: Swizzlable {
    fileprivate struct AssociatedKeys {
        static var HasInitialized = "HasInitialized"
        static var HasJSInitialized = "HasJSInitialized"
        static var HasSwizzled = "HasSwizzled"
        static var SuppressSuperview = "SuppressSuperview"
    }

    public static var swizzled: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasSwizzled) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.HasSwizzled, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    public class func swizzle() {
        hookTo(original: #selector(viewWillMove(toWindow:)), swizzled: #selector(qk_viewWillMove(toWindow:)))
        hookTo(original: #selector(layout), swizzled: #selector(qk_layout))
    }
    
    func qk_viewWillMove(toWindow newWindow: NSWindow?) {
        self.qk_viewWillMove(toWindow: newWindow)
        
        qk_init()
    }
    
    internal private(set) var hasInitialized: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasInitialized) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.HasInitialized, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    internal private(set) var hasJSInitialized: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasJSInitialized) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.HasJSInitialized, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    internal func qk_init() {
        // Assure it has not initiated yet
        guard !hasInitialized else {
            return
        }
        
        // Set initiated
        hasInitialized = true
    }
    
    internal func qk_js_init() { // When the JavaScript object is set, do some stuff
        // Flag this view needs `layout` called
        needsLayout = true
        
        // Add a tracking area
        createTrackingArea()
    }
    
    internal func qk_layout() {
        self.qk_layout()
        
        _ = jsValue?.invokeMethod("layout", withArguments: [])
    }
}

extension NSView: View {
    /* JavaScript Interop */
    public var jsView: JSValue {
        get {
            guard let instance = instance else { // TODO: Catch 22 here, cannot get instance if cannot get jsValue // Maybe use old method of recursively going through next responders to find partent
                Swift.print("Could not get instance for jsView.")
                return JSValue()
            }
            
            return readOrCreateJSValue(instance: instance)
        }
        set {
            jsValue = newValue
            qk_js_init()
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
    internal var suppressSuperview: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.SuppressSuperview) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.SuppressSuperview, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    public var jsSubviews: [View] {
        get {
            return subviews
        }
    }
    
    public var jsSuperview: View? {
        if suppressSuperview { // Don't give superview if not supposed to
            return nil
        } else {
            return superview
        }
    }
    
    public func jsAddSubview(_ view: View, _ index: Int) {
        guard let nsView = view as? NSView else {
            Swift.print("Could not get NSView for adding subview. \(view)")
            return
        }
        
        let isLast = index >= subviews.endIndex
        
        if isLast {
            // Adds the subview at the top (aka the largest index)
            addSubview(nsView)
        } else {
            // Adds the subview below the view at the index
            addSubview(nsView, positioned: isLast ? .above : .below, relativeTo: subviews[index])
        }
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
    public var jsShadow: JSValue? {
        get {
            guard let instance = instance else {
                print("Could not get instance for shadow.")
                return JSValue()
            }
            
            if let nsShadow = self.shadow, let shadow = JSShadow(instance: instance, nsShadow: nsShadow) {
                return shadow.value
            } else {
                return JSValue(undefinedIn: instance.context)
            }
        }
        set {
            if let newValue = newValue {
                shadow = JSShadow(value: newValue)?.nsShadow
            } else {
                shadow = nil
            }
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
}

extension NSView {
    public func createJSValue(instance: QKInstance) -> JSValue? {
        // new View(<QKView>, false)
        return instance.quarkLibrary.objectForKeyedSubscript("View").construct(withArguments: [self, false])
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
