//
//  QKButton.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import QuarkExports

enum QKError: Error {
    case invalidViewType(type: AnyClass)
}

final class QKButton: QKView, Button {
    var nsButton: NSButton {
        return nsView as! NSButton // TODO: Find a safe way for this
    }
    
    override convenience init(nsView view: NSView) throws {
        // Try to convert the view to a button or throw an error
        if let button = view as? NSButton {
            try self.init(nsButton: button)
        } else {
            throw QKError.invalidViewType(type: NSButton.self)
        }
    }
    
    init(nsButton button: NSButton) throws {
        try super.init(nsView: button)
    }
    
    convenience required init() {
        try! self.init(nsButton: NSButton()) // TODO: Safety
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
