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
}


// TODO: Deal with weird events: http://stackoverflow.com/questions/22389685/nsbutton-mousedown-mouseup-behaving-differently-on-enabled
// TODO: Probably want to set target/action since some events don't even register
