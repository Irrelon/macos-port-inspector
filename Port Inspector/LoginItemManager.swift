//
//  LoginItemManager.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import Foundation
import ServiceManagement

class LoginItemManager: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var errorMessage: String?
    
    init() {
        checkLoginItemStatus()
    }
    
    func checkLoginItemStatus() {
        // For macOS 13+ we use SMAppService
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            isEnabled = service.status == .enabled
        } else {
            // Fallback for older macOS versions
            isEnabled = false
        }
    }
    
    func toggleLoginItem() {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            let wasEnabled = isEnabled
            
            print("=== toggleLoginItem called ===")
            print("Current status: \(service.status.rawValue)")
            print("Attempting to: \(isEnabled ? "disable" : "enable")")
            
            do {
                if isEnabled {
                    // Disable login item
                    print("Calling service.unregister()...")
                    try service.unregister()
                    isEnabled = false
                    errorMessage = nil
                    print("Successfully unregistered")
                } else {
                    // Enable login item
                    print("Calling service.register()...")
                    try service.register()
                    isEnabled = true
                    errorMessage = nil
                    print("Successfully registered")
                }
                
                // Check final status
                print("Final status: \(service.status.rawValue)")
            } catch {
                print("=== ERROR occurred ===")
                print("Error type: \(type(of: error))")
                print("Error description: \(error.localizedDescription)")
                print("Error details: \(error)")
                
                // Revert the toggle state on error
                isEnabled = wasEnabled
                
                // Set error message for display
                let errorDescription = error.localizedDescription
                let errorString = "\(error)"
                
                if errorDescription.contains("notFound") || errorDescription.contains("not found") || errorString.contains("notFound") {
                    errorMessage = "Failed to register login item. The app may need to be in the Applications folder."
                } else if errorDescription.contains("permission") || errorDescription.contains("authorized") || errorString.contains("notAuthorized") {
                    errorMessage = "Permission denied. Please check System Settings > General > Login Items and allow Port Inspector."
                } else {
                    errorMessage = "Failed to toggle login item: \(errorDescription)"
                }
            }
        }
    }
}
