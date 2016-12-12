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

public class QuarkViewController: NSViewController {
    /// A map of the classes to export to the `JSContext`
    let exports: [String: Any] = [
        // UI
        "View": NSView.self,
        "Button": NSButton.self,
        
        // Core
        "Logger": JSLogger.self,
        "Module": JSModule.self
    ]
    
    /// The jsValue of this window.
    public var jsWindow: JSWindow!
    
    /// The quark instance that manages everything.
    public let instance: QKInstance
    
    // MARK: Initiators
    /**
     Creates a new Quark instance and starts it.
     
     - parameter script: The JavaScript script to execute.
     - parameter virtualMachine: An optional virtual machine that can be
     provided.
     */
    public init(module: QKModule, virtualMachine: JSVirtualMachine? = nil) throws {
        // Swizzle the appropriate views
        Swizzler.swizzle(classes: [ NSView.self, NSButton.self ])

        // Create an instance
        self.instance = try QKInstance(module: module, exports: exports, virtualMachine: virtualMachine)
        
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
        
        // Create the `JSWindow`
        jsWindow = JSWindow(instance: instance, window: self)
        
        // Start the instance
        instance.start(window: self)
    }

    public override func viewDidLayout() {
        super.viewDidLayout()

        // Override this so view.layout is called (otherwise, it isn't for some reason)
    }
}

// MARK: Window
extension QuarkViewController: Window {
    public var jsRootView: View {
        get {
            return view
        }
        set(newValue) {
            guard let nsView = newValue as? NSView else {
                Swift.print("Could not get NSView for setting Window root view. \(view)")
                return
            }
            
            // Tell the current view not to suppress superviews anymore
            view.suppressSuperview = false
            
            // Tell the new view to suppress the superviews
            nsView.suppressSuperview = true
            
            // Set the view
            view = nsView
        }
    }
}
