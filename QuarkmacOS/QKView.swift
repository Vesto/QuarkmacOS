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
        static var HasJSInitialized = "HasJSInitialized"
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

    public class func swizzle() {
        Swift.print("View swizzle")
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
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.HasInitialized,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    internal private(set) var hasJSInitialized: Bool {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.HasJSInitialized) as? Bool ?? false
        }
        set {
            objc_setAssociatedObject(
                self,
                &AssociatedKeys.HasJSInitialized,
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
    }
    
    internal func qk_js_init() { // When the JavaScript object is set, do some stuff
        // Flag this view needs `layout` called
        needsLayout = true
        
        // Add a tracking area
        createTrackingArea()
    }
    
    internal func qk_layout() {
        self.qk_layout()
        
        _ = jsView?.invokeMethod("layout", withArguments: [])
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

extension NSView { // https://developer.apple.com/reference/appkit/nsresponder // TODO: Tablet stuff?
    /* Mouse Events */
    open override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        handleInput(event)
    }
    
    open override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        handleInput(event)
    }
    
    open override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        handleInput(event)
    }
    
    open override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        handleInput(event)
    }
    
    open override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        handleInput(event)
    }
    
    open override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        handleInput(event)
    }
    
    open override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        handleInput(event)
    }
    
    open override func rightMouseDown(with event: NSEvent) {
        super.rightMouseDown(with: event)
        handleInput(event)
    }
    
    open override func rightMouseDragged(with event: NSEvent) {
        super.rightMouseDragged(with: event)
        handleInput(event)
    }
    
    open override func rightMouseUp(with event: NSEvent) {
        super.rightMouseUp(with: event)
        handleInput(event)
    }
    
    open override func otherMouseDown(with event: NSEvent) {
        super.otherMouseDown(with: event)
        handleInput(event)
    }
    
    open override func otherMouseDragged(with event: NSEvent) {
        super.otherMouseDragged(with: event)
        handleInput(event)
    }
    
    open override func otherMouseUp(with event: NSEvent) {
        super.otherMouseUp(with: event)
        handleInput(event)
    }
    
    /* Keyboard Events */
    open override func keyDown(with event: NSEvent) {
        super.keyDown(with: event)
        handleInput(event)
    }
    
    open override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
        handleInput(event)
    }
    
    /* Tracking area */
    func createTrackingArea() {
        guard trackingAreas.count == 0 else {
            return
        }
        
        var options: NSTrackingAreaOptions = [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect, .enabledDuringMouseDrag]
        let trackingArea = NSTrackingArea(rect: CGRect.zero, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    /* Input handler */
    enum EventType {
        case interaction(JSInteractionEvent.JSInteractionType, JSEventPhase), key(isDown: Bool), scroll
    }
    
    func handleInput(_ event: NSEvent) {
        guard let jsView = jsView else {
            return
        }
        
//        Swift.print("~~~~~~~~~~~")
//        Swift.print("Event: \(event)")
        
        // Get the event
        let e: EventType
        switch event.type {
        case .leftMouseDown:
            e = .interaction(.leftMouse, .began)
        case .leftMouseDragged:
            e = .interaction(.leftMouse, .changed)
        case .leftMouseUp:
            e = .interaction(.leftMouse, .ended)
            
        case .rightMouseDown:
            e = .interaction(.rightMouse, .began)
        case .rightMouseDragged:
            e = .interaction(.rightMouse, .changed)
        case .rightMouseUp:
            e = .interaction(.rightMouse, .ended)
            
        case .otherMouseDown:
            e = .interaction(.otherMouse, .began)
        case .otherMouseUp:
            e = .interaction(.otherMouse, .changed)
        case .otherMouseDragged:
            e = .interaction(.otherMouse, .ended)
            
        case .mouseEntered:
            e = .interaction(.hover, .began)
        case .mouseMoved:
            e = .interaction(.hover, .changed)
        case .mouseExited:
            e = .interaction(.hover, .ended)
            
        case .scrollWheel:
            e = .scroll
            
        case .keyDown:
            e = .key(isDown: true)
        case .keyUp:
            e = .key(isDown: false)
        
        default:
            // Unsupported input type
            return
        }
        
        // Create the event object
        guard let instance = instance, let window = instance.window as? QuarkViewController else {
            print("Could not get instance and window for event.")
            return
        }
        
        // Get the location into window's coordinates
        let location = window.view.convert(event.locationInWindow, from: nil)
        guard let jsLocation = JSPoint(instance: instance, cgPoint: location) else {
            print("Could not convert location.")
            return
        }
        
        switch e {
        case .interaction(let type, let phase):
            // Get the click-specific events
            let count: Int
            let pressure: Float
            if case .hover = type { // Not a click
                count = 0
                pressure = 0
            } else { // Is a click
                count = event.clickCount
                pressure = event.pressure
            }
            
            // Create the event
            guard let event = JSInteractionEvent(
                instance: instance,
                time: event.timestamp,
                type: type,
                phase: phase,
                location: jsLocation, // Convert point from the window
                count: UInt32(count),
                pressure: Double(pressure)
            ) else {
                Swift.print("Could not create JSInteractionEvent.")
                return
            }
            
            // Send the event
            jsView.invokeMethod("interactionEvent", withArguments: [event.value])
        case .key(let isDown):
            // Process the modifiers
            var modifiers = Array<JSKeyEvent.JSKeyModifier>()
            switch event.modifierFlags {
            case NSEventModifierFlags.capsLock:
                modifiers.append(.capsLock)
            case NSEventModifierFlags.command:
                modifiers.append(.meta)
            case NSEventModifierFlags.control:
                modifiers.append(.control)
            case NSEventModifierFlags.option:
                modifiers.append(.option)
            case NSEventModifierFlags.shift:
                modifiers.append(.shift)
            default:
                Swift.print("Unsupported NSEventModifierFlags used: \(event.modifierFlags)")
            }
            
            // Create the event
            guard let event = JSKeyEvent(
                instance: instance,
                time: event.timestamp,
                phase: isDown ? .keyDown : .keyUp,
                isRepeat: event.isARepeat,
                keyCode: UInt32(event.keyCode),
                modifiers: []
            ) else {
                Swift.print("Could not create JSKeyEvent.")
                return
            }
            
            // Send the event
            jsView.invokeMethod("keyEvent", withArguments: [event.value])
        case .scroll:
            // Get the scrolling phase
            let phase: JSEventPhase
            switch event.phase {
            case NSEventPhase.began:
                phase = .began
            case NSEventPhase.stationary:
                phase = .stationary
            case NSEventPhase.changed:
                phase = .changed
            case NSEventPhase.ended:
                phase = .ended
            case NSEventPhase.cancelled:
                phase = .cancelled
            default:
                Swift.print("Unsupported NSEventPhase used: \(event.phase)")
                return
            }
            
            // Get the delta scroll
            guard let deltaScroll = JSPoint(
                instance: instance,
                x: event.scrollingDeltaX.double,
                y: event.scrollingDeltaY.double
            ) else {
                Swift.print("Could not get scrolling delta.")
                return
            }
            
            // Create the event
            guard let event = JSScrollEvent(
                instance: instance,
                time: event.timestamp,
                phase: phase,
                location: jsLocation,
                deltaScroll: deltaScroll
            ) else {
                Swift.print("Could not create JSScrollEvent.")
                return
            }
            
            // Send the event
            jsView.invokeMethod("scrollEvent", withArguments: [event.value])
        }
        
//        Swift.print("~~~~~~~~~~~")
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
