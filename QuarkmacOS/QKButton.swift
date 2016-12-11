//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkCore

extension NSButton: Button {
    public var jsTitle: String {
        get {
            return title
        }
        set(newValue) {
            title = newValue
        }
    }
}

extension NSButton {
    public override class func swizzle() {
        
    }
}

extension NSButton {
    override func qk_init() {
        super.qk_init()
        
        // Set the button style
        bezelStyle = NSBezelStyle.regularSquare
    }
    
    open override func mouseDown(with event: NSEvent) {
        // Has to call `handleInput` manually because the superclass
        // `NSButton` overrides it and doesn't call its superclass.
        if !handleInput(event, jsValue, instance) {
            nextResponder?.mouseDown(with: event)
        }
        
        // Has to manually highlight the button since not calling the
        // superclass.
        isHighlighted = true
    }
    
    open override func mouseUp(with event: NSEvent) {
        // Call `super` to have the event handled
        super.mouseUp(with: event)
        
        // Unhighlight and send event.
        isHighlighted = false
        performClick(self)
    }
}


// TODO: Deal with weird events: http://stackoverflow.com/questions/22389685/nsbutton-mousedown-mouseup-behaving-differently-on-enabled
// TODO: Probably want to set target/action since some events don't even register
