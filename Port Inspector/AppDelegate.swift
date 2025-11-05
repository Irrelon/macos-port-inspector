//
//  AppDelegate.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var portScanner: PortScanner!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create the status item in the menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "network", accessibilityDescription: "Port Inspector")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the port scanner instance
        portScanner = PortScanner()
        
        // Create the popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 400, height: 500)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView(portScanner: portScanner)
        )
    }
    
    @objc func togglePopover() {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                // Scan ports when opening the menu
                portScanner.scanPorts()
            }
        }
    }
}
