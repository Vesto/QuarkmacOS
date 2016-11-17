//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import QuarkExports
import QuarkCore

/// An override class that manages things only subclasses can do.
public class NSButtonOverride: NSButton, NSViewOverrideProtocol {
    // Callbacks
    public var layoutCallback: (() -> Void)?
    
    // Overrides
    public override func layout() {
        super.layout()
        
        layoutCallback?()
    }
}

@objc
public class QKButton: QKView, Button {
    var nsButton: NSButtonOverride {
        return nsView as! NSButtonOverride // TODO: Find a safe way for this
    }
    
    override convenience init(nsView view: NSViewOverrideProtocol) throws {
        // Try to convert the view to a button or throw an error
        if let button = view as? NSButtonOverride {
            try self.init(nsButton: button)
        } else {
            throw QKError.invalidViewType(type: NSButtonOverride.self)
        }
    }
    
    init(nsButton button: NSButtonOverride) throws {
        try super.init(nsView: button)
    }
    
    convenience required public init() {
        try! self.init(nsButton: NSButtonOverride()) // TODO: Safety
    }
}

extension QKButton {
    public var title: String {
        get {
            return nsButton.title
        }
        set {
            nsButton.title = newValue
        }
    }
}
