//
//  NSResponder+Quark.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 12/10/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkCore

fileprivate enum EventType {
    case interaction(JSInteractionEvent.JSInteractionType, JSEventPhase), key(isDown: Bool), scroll
}

extension NSResponder {
    internal func handleInput(_ event: NSEvent, _ jsValue: JSValue?, _ instance: QKInstance?) -> Bool { // Returns if event absorbed
        guard
            let jsValue = jsValue,
            let instance = instance,
            let window = instance.window as? QuarkViewController
        else {
            return false
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
            return false
        }
        
        // Get the location into window's coordinates
        let location = window.view.convert(event.locationInWindow, from: nil)
        guard let jsLocation = JSPoint(instance: instance, cgPoint: location) else {
            print("Could not convert location.")
            return false
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
                    return false
            }
            
            // Send the event
            return jsValue.optionalInvoke("interactionEvent", withArguments: [event.value])?.toBool() ?? false
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
                // Unsupported modifier flag, do nothing
                break
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
                    return false
            }
            
            // Send the event
            return jsValue.optionalInvoke("keyEvent", withArguments: [event.value])?.toBool() ?? false
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
                // Unsupported phase, do nothing
                return false
            }
            
            // Get the delta scroll
            guard let deltaScroll = JSVector(
                instance: instance,
                x: event.scrollingDeltaX.double,
                y: event.scrollingDeltaY.double
                ) else {
                    Swift.print("Could not get scrolling delta.")
                    return false
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
                    return false
            }
            
            // Send the event
            return jsValue.optionalInvoke("scrollEvent", withArguments: [event.value])?.toBool() ?? false
        }
    }
}

extension NSView {
    open override var acceptsFirstResponder: Bool {
        return true
    }
    
    /* Mouse Events */
    open override func mouseDown(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseDown(with: event)
        }
    }
    
    open override func mouseDragged(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseDragged(with: event)
        }
    }
    
    open override func mouseUp(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseUp(with: event)
        }
    }
    
    open override func mouseMoved(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseMoved(with: event)
        }
    }
    
    open override func mouseEntered(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseEntered(with: event)
        }
    }
    
    open override func mouseExited(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.mouseExited(with: event)
        }
    }
    
    open override func scrollWheel(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.scrollWheel(with: event)
        }
    }
    
    open override func rightMouseDown(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.rightMouseDown(with: event)
        }
    }
    
    open override func rightMouseDragged(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.rightMouseDragged(with: event)
        }
    }
    
    open override func rightMouseUp(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.rightMouseUp(with: event)
        }
    }
    
    open override func otherMouseDown(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.otherMouseDown(with: event)
        }
    }
    
    open override func otherMouseDragged(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.otherMouseDragged(with: event)
        }
    }
    
    open override func otherMouseUp(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.otherMouseUp(with: event)
        }
    }
    
    /* Keyboard Events */
    open override func keyDown(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.keyDown(with: event)
        }
    }
    
    open override func keyUp(with event: NSEvent) {
        if !handleInput(event, jsValue, instance) {
            super.keyUp(with: event)
        }
    }
    
    /* Tracking area */
    func createTrackingArea() { // Used so mousein and mouseout events get called
        guard trackingAreas.count == 0 else {
            return
        }
        
        var options: NSTrackingAreaOptions = [.mouseEnteredAndExited, .activeInActiveApp, .inVisibleRect, .enabledDuringMouseDrag]
        let trackingArea = NSTrackingArea(rect: CGRect.zero, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
}

extension QuarkViewController {
    open override var acceptsFirstResponder: Bool {
        return true
    }
    
    /* Mouse Events */
    open override func mouseDown(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseDown(with: event)
        }
    }
    
    open override func mouseDragged(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseDragged(with: event)
        }
    }
    
    open override func mouseUp(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseUp(with: event)
        }
    }
    
    open override func mouseMoved(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseMoved(with: event)
        }
    }
    
    open override func mouseEntered(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseEntered(with: event)
        }
    }
    
    open override func mouseExited(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.mouseExited(with: event)
        }
    }
    
    open override func scrollWheel(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.scrollWheel(with: event)
        }
    }
    
    open override func rightMouseDown(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.rightMouseDown(with: event)
        }
    }
    
    open override func rightMouseDragged(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.rightMouseDragged(with: event)
        }
    }
    
    open override func rightMouseUp(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.rightMouseUp(with: event)
        }
    }
    
    open override func otherMouseDown(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.otherMouseDown(with: event)
        }
    }
    
    open override func otherMouseDragged(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.otherMouseDragged(with: event)
        }
    }
    
    open override func otherMouseUp(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.otherMouseUp(with: event)
        }
    }
    
    /* Keyboard Events */
    open override func keyDown(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.keyDown(with: event)
        }
    }
    
    open override func keyUp(with event: NSEvent) {
        if !handleInput(event, instance.moduleDelegate, instance) {
            super.keyUp(with: event)
        }
    }
}
