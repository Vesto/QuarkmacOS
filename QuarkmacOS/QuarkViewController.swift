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
    /// Swizzles everything and gets called once, since in the static context.
    static let swizzler: Void = {
        // Set the classes to swizzle
        Swizzler.classesToSwizzle = [ NSView.self ]

        // Swizzle them
        Swizzler.swizzle()
    }()

    /// A map of the classes to export to the `JSContext`
    let exports: [String: Any] = [
        // UI
        "View": NSView.self,
        "Button": NSButton.self,
        
        // Core
        "Logger": Logger.self
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

        // Include this so `view.layout` gets called (doesn't get called otherwise for some reason)
    }

}

extension QuarkViewController: Window {
    public var jsRootView: JSValue {
        get {
            return view.readOrCreateJSValue(instance: instance)
        }
        set(newValue) {
            guard let nsView = JSView(value: newValue)?.nsView else {
                Swift.print("Could not get NSView for setting Window root view. \(view)")
                return
            }

            view = nsView
        }
    }
}

extension QuarkViewController {
    public static func createJSValue(context: JSContext) -> JSValue? {
        print("Cannot create a QuarkViewController from a static context.")
        return nil
    }
}
