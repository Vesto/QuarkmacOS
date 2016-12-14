//
//  QKLabel.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 12/11/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkCore

enum JSLineBreakMode: UInt {
    case wordWrap
    case charWrap
    case clip
    case truncateHead
    case truncateTail
    case truncateMiddle
    
    init?(nsLineBreakMode mode: NSLineBreakMode) {
        self.init(rawValue: mode.rawValue)
    }
    
    var nsLineBreakMode: NSLineBreakMode? {
        return NSLineBreakMode(rawValue: rawValue)
    }
}

enum JSTextAlignmentMode: UInt {
    case left
    case right
    case center
    case justified
    
    init?(nsTextAlignment mode: NSTextAlignment) {
        self.init(rawValue: mode.rawValue)
    }
    
    var nsTextAlignment: NSTextAlignment? {
        return NSTextAlignment(rawValue: rawValue)
    }
}

class NSLabel: NSTextField {
    
}

extension NSLabel {
    override func qk_init() {
        isBezeled = false
        drawsBackground = false
        isEditable = false
        isSelectable = false
    }
}

extension NSLabel: Label {
    var jsText: String {
        get {
            return stringValue
        }
        set {
            stringValue = newValue
        }
    }
    
    var jsFont: JSValue { // TODO: JSFont
        get {
            Swift.print("NEED TO IMPLEMENT FONT")
            return JSValue()
        }
        set {
            Swift.print("NEED TO IMPLEMENT FONT")
        }
    }
    
    var jsColor: JSValue {
        get {
            guard let instance = instance else {
                print("Could not get instance for color.")
                return JSValue()
            }
            
            return JSColor(instance: instance, nsColor: textColor ?? NSColor.black)?.value ?? JSValue()
        }
        set {
            textColor = JSColor(value: newValue)?.nsColor
        }
    }
    
    var jsLineCount: Int {
        get {
            return maximumNumberOfLines
        }
        set {
            maximumNumberOfLines = jsLineCount
        }
    }
    
    var jsLineBreakMode: UInt {
        get {
            guard let mode = JSLineBreakMode(nsLineBreakMode: lineBreakMode)?.rawValue else {
                print("Could not get line break mode.")
                return 0
            }
            
            return mode
        }
        set {
            guard let mode = JSLineBreakMode(rawValue: newValue)?.nsLineBreakMode else {
                print("Could not get line break mode.")
                return
            }
            
            lineBreakMode = mode
        }
    }
    
    var jsAlignmentMode: UInt {
        get {
            guard let mode = JSTextAlignmentMode(nsTextAlignment: alignment)?.rawValue else {
                print("Could not get text alignment mode.")
                return 0
            }
            
            return mode
        }
        set {
            guard let mode = JSTextAlignmentMode(rawValue: newValue)?.nsTextAlignment else {
                print("Could not get text alignment mode.")
                return
            }
            
            alignment = mode
        }
    }
}
