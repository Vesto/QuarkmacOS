//
//  Quark.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore

public class Quark {
    /// The window to present Quark in
    let window: NSWindow
    
    /// The context in which the main script runs in
    let context: JSContext
    
    /// The script to be executed when `start` called
    let script: String
    
    /// Wether or not Quark is running
    private(set) var running: Bool = false
    
    /**
     Creates a new Quark instance and starts it.
     
     - parameter script: The JavaScript script to execute.
     - parameter virtualMachine: An optional virtual machine that can be
     provided.
     */
    init(script: String, virtualMachine: JSVirtualMachine? = nil) {
        // Create the window
        window = NSWindow()
        
        // Create the context
        context = JSContext(virtualMachine: virtualMachine)
        
        // Save the script
        self.script = script
    }
    
    /**
     Starts the Quark instance, concequently showing the window and
     executing the script.
     */
    func start() {
        if !running {
            // Save the running state
            running = true
            
            // Show the window // TODO: Use NSWindowController and pass it here
            window.makeKeyAndOrderFront(nil)
            
            // Evaluates the script
            context.evaluateScript(script)
        }
    }
}
