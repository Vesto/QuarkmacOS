//
//  QuarkViewController.swift
//  QuarkmacOS
//
//  Created by Nathan Flurry on 10/12/16.
//  Copyright © 2016 Vesto. All rights reserved.
//

import Cocoa
import JavaScriptCore
import QuarkExports
import QuarkCore

// TODO: Parse sourcemaps for original source location https://github.com/mozilla/source-map
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
    
    /// The URL at which the module is located.
    public let moduleURL: URL
    
    /// The module that this Quark instance is based on.
    public let module: QKModule
    
    /// The app delegate.
    public var appDelegate: JSValue?
    
    /// The context in which the main script runs in
    public let context: JSContext
    
    /// Wether or not Quark is running
    public private(set) var running: Bool = false
    
    // MARK: Initiators
    /**
     Creates a new Quark instance and starts it.
     
     - parameter script: The JavaScript script to execute.
     - parameter virtualMachine: An optional virtual machine that can be
     provided.
     */
    public init(moduleURL: URL, virtualMachine: JSVirtualMachine? = nil) throws {
        // Create the context
        if let virtualMachine = virtualMachine {
            context = JSContext(virtualMachine: virtualMachine)
        } else {
            context = JSContext()
        }
        
        // TEMP: Sets the context
        QuarkViewController.context = context
        
        // Save the URL
        self.moduleURL = moduleURL
        
        // Load the module
        self.module = try QKModule(url: moduleURL)
        
        super.init(nibName: nil, bundle: nil)!
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle
    public override func loadView() {
        // Don't call super.loadView() because it will try and load the XIB
        
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
        
        // Inject the program into the context
        do {
            try module.import(intoContext: context)
        } catch {
            print("Could not import module. \(error)")
        }
        
        // Creates an app delegate
        guard let appDelegateName = module.info?.appDelegate else {
            print("Could not get app delegate.")
            return
        }
        appDelegate = context.objectForKeyedSubscript(appDelegateName).construct(withArguments: [])
        
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
            
            // Call the appropriate method on the app delegate
            guard let parentView = JSView(context: context, view: view)?.value else {
                print("Could not get parent view.")
                return
            }
            // TODO: Construct and save app delegate
            appDelegate?.invokeMethod("begin", withArguments: [parentView])
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
}
