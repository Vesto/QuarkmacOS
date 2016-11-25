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

//@objc
//public class QKButton: QKView, Button {
//    var nsButton: NSButton {
//        return nsView as! NSButton // TODO: Find a safe way for this
//    }
//    
//    override convenience init(nsView view: NSView) throws {
//        // Try to convert the view to a button or throw an error
//        if let button = view as? NSButton {
//            try self.init(nsButton: button)
//        } else {
//            throw QKError.invalidViewType(type: NSButton.self)
//        }
//    }
//    
//    init(nsButton button: NSButton) throws {
//        try super.init(nsView: button)
//        
//        // Register the events
//        registerEvents()
//    }
//    
//    convenience required public init() {
//        try! self.init(nsButton: NSButton()) // TODO: Safety
//    }
//    
//    /// Registers the events for the `NSButton`.
//    private func registerEvents() {
//        nsButton.target = self
//        nsButton.action = #selector(onClick)
//    }
//    
//    // MARK: Events
//    @objc private func onClick(sender: NSButton) {
//        actionHandler?.call(withArguments: [self])
//    }
//    
//    // MARK: Impementation
//    public var title: String {
//        get {
//            return nsButton.title
//        }
//        set {
//            nsButton.title = newValue
//        }
//    }
//    
//    public var actionHandler: JSValue?
//}
