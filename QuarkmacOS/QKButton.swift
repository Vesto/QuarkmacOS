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
    public var jsTitle: String {
        get {
            return title
        }
        set(newValue) {
            title = newValue
        }
    }

    public var actionHandler: JSValue? {
        get {
            return nil
        }
        set {
            
        }
    }
    
    
}
