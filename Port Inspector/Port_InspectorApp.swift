//
//  Port_InspectorApp.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import SwiftUI

@main
struct Port_InspectorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
