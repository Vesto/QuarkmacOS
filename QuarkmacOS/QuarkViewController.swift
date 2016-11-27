//
//  QuarkViewController.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkCore
import QuarkExports

public class QuarkViewController: NSViewController {
    // TEMP: Static context for quick use, need to remove
    static var context: JSContext!
    
    /// The prefix for all the exports if classes
    private let exportsPrefix = "QK"
    
    /// A map of the classes to export to the `JSContext`
    private let exports: [String: Any] = [
        // UI
        "View": NSView.self,
        "Button": NSButton.self,
        
        // Core
        "Logger": Logger.self
    ]
    
    /// The context in which the main script runs in
    public let context: JSContext
    
    /// The script to be executed when `start` called
    public let script: String
    
    /// Wether or not Quark is running
    public private(set) var running: Bool = false
    
    // MARK: Initiators
    /**
     Creates a new Quark instance and starts it.
     
     - parameter script: The JavaScript script to execute.
     - parameter virtualMachine: An optional virtual machine that can be
     provided.
     */
    public init(script: String, virtualMachine: JSVirtualMachine? = nil) {
        // Create the context
        if let virtualMachine = virtualMachine {
            context = JSContext(virtualMachine: virtualMachine)
        } else {
            context = JSContext()
        }
        
        // TEMP: Sets the context
        QuarkViewController.context = context
        
        // Save the script
        self.script = script
        
        super.init(nibName: nil, bundle: nil)!
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    public override func loadView() {
//        super.loadView()
        
        view = NSView()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        // Swizzle classes // TODO: Check if they've been swizzled already
        NSView.swizzle()
        
        // Add the exports to the context
        addExports()
        
        // Import the Quark Library
        do {
            try importQuarkLibrary()
        } catch {
            print("Could not import Quark library. \(error)")
        }
        
        // Set the context
        setContext()
        
        // Start quark
        start()
    }
    
    // MARK: Methods
    /**
     Starts the Quark instance, concequently showing the window and
     executing the script.
     */
    private func start() {
        if !running {
            // Save the running state
            running = true
            
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
            context.setObject(object, forKeyedSubscript: NSString(string: exportsPrefix + key))
        }
    }
    
    /**
     Imports the Quark Library to the context for use.
    */
    private func importQuarkLibrary() throws {
        // Run the built library
        let script = try String(contentsOf: try QuarkLibrary.getLibrary())
        context.evaluateScript(script)
    }
    
    /**
     Sets the appropriate parameters so documents can work in this view controller's
     context.
    */
    private func setContext() {
        // Set the parent view so it can manipulate objects // TODO: Safety
        context.setObject(JSView(context: context, view: view)!.value, forKeyedSubscript: NSString(string: "parentView"))
        print(context.objectForKeyedSubscript("parentView"))
    }
}