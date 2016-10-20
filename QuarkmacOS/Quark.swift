//
//  Quark.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkCore

/*
 Notes:
 
 - Can't use exported protocols because they refer to other generics which don't bridge.
 - Make a radar about generics in JSCore
*/

public class Quark {
    /// A map of the classes to export to the `JSContext`
    private let exports: [String: Any] = [
        // UI
        "View": QKView.self,
        "Button": QKButton.self,
        
        // Data types
        "Rect": QKRect.self,
        "Point": QKPoint.self,
        "Size": QKSize.self,
        "Shadow": QKShadow.self,
        
        // Core
        "Logger": Logger.self
    ]
    
    /// The window to present Quark in
    public let window: NSWindow
    
    /// The context in which the main script runs in
    public let context: JSContext
    
    /// The script to be executed when `start` called
    public let script: String
    
    /// Wether or not Quark is running
    public private(set) var running: Bool = false
    
    /**
     Creates a new Quark instance and starts it.
     
     - parameter script: The JavaScript script to execute.
     - parameter virtualMachine: An optional virtual machine that can be
     provided.
     */
    public init(script: String, virtualMachine: JSVirtualMachine? = nil) {
        // Create the window
        window = NSWindow()
        
        // Create the context
        if let virtualMachine = virtualMachine {
            context = JSContext(virtualMachine: virtualMachine)
        } else {
            context = JSContext()
        }
        
        // Save the script
        self.script = script
        
        // Add the exports to the context
        addExports()
    }
    
    /**
     Starts the Quark instance, concequently showing the window and
     executing the script.
     */
    public func start() {
        if !running {
            // Save the running state
            running = true
            
            // Show the window // TODO: Use NSWindowController and pass it here
            window.makeKeyAndOrderFront(nil)
            
            // Evaluates the script
            context.evaluateScript(script)
        }
    }
    
    /**
     Adds exports to the `JSContext` for the appropriate classes.
     */
    private func addExports() {
        // Go through every export and expose it to the context
        for (key, object) in exports {
            context.setObject(object, forKeyedSubscript: NSString(string: key))
        }
    }
}
