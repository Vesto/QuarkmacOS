//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkExports
import QuarkCore

extension NSButton: Button {
    public var jsTitle: String { // TODO: Implement
        get {
            return title
        }
        set(newValue) {
            title = newValue
        }
    }

    public var actionHandler: JSValue? { // TODO: Implement. Weak? (need to call instead)
        get {
            return nil
        }
        set {
            
        }
    }
}

extension NSButton {
    override func qk_init() {
        super.qk_init()
        
        // Set the button style
//        bezelStyle = NSBezelStyle.rounded
        bezelStyle = NSBezelStyle.regularSquare
    }
}
