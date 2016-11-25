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
 - For arrays, need an adapter so it doesn't generate an entire array every time you index it
    - e.g. suviews
    - JavaScript: view.subviews[0] will make the program take every subview and convert it to JS then be thrown back into the garbage collector
    - Make ArrayAdapter<JSView> { index: Int in return view.subviews[index].jsView }
    - Then when JavaSript wants to subscript it, do view.subviews.atIndex(0)
    - Or get the whole thing by view.subviews.all() (goes through every item and converts it)
 - Add parameter callsMethods to determine if the NSView should call the native methods (e.g. if there is a subclass that it should be, otherwise just don't call it at all, default to false) 
 */

extension NSObject {
    static func hookTo(original originalSelector: Selector, swizzled swizzledSelector: Selector) {
        let originalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let didAddMethod = class_addMethod(
            self, originalSelector,
            method_getImplementation(swizzledMethod),
            method_getTypeEncoding(swizzledMethod)
        )
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }
}

extension NSView {
    fileprivate struct AssociatedKeys {
        static var JSViewName = "JSViewName"
        static var HasInitialized = "HasInitialized"
    }
    
    public static func swizzle() { // http://nshipster.com/swift-objc-runtime/
//        let originalSelector = Selector("viewWillMoveToWindow:")
//        let swizzledSelector = Selector("qk_viewWillMoveToWindow:")
//        
//        let originalMethod = class_getInstanceMethod(self, originalSelector)
//        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
//        
//        let didAddMethod = class_addMethod(
//            self, originalSelector,
//            method_getImplementation(swizzledMethod),
//            method_getTypeEncoding(swizzledMethod)
//        )
//        
//        if didAddMethod {
//            class_replaceMethod(self, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
//        } else {
//            method_exchangeImplementations(originalMethod, swizzledMethod)
//        }
        
        hookTo(original: Selector("viewWillMoveToWindow:"), swizzled: Selector("qk_viewWillMoveToWindow:"))
        hookTo(original: Selector("layout"), swizzled: Selector("qk_layout"))
    }
    
    func qk_viewWillMove(toWindow newWindow: NSWindow?) {
        self.qk_viewWillMove(toWindow: newWindow)
        
        qk_init()
    }
    
    func qk_layout() {
        self.qk_layout()
        
    }
    
    private var hasInitialized: Bool {
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
    
    private func qk_init() {
        // Assure it has not initiated yet
        guard !hasInitialized else {
            return
        }
        
        // Set initiated
        hasInitialized = true
        
        Swift.print("Initialize \(self).")
    }
}

extension NSView: View {
    /* JavaScript Interop */
    public var jsView: JSValue? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.JSViewName) as? JSValue
        }
        set {
            if let newValue = newValue {
                objc_setAssociatedObject(
                    self,
                    &AssociatedKeys.JSViewName,
                    newValue,
                    .OBJC_ASSOCIATION_RETAIN_NONATOMIC
                )
            }
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
