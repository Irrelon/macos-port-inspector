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
            
            do {
                if isEnabled {
                    // Disable login item
                    try service.unregister()
                    isEnabled = false
                    errorMessage = nil
                } else {
                    // Enable login item
                    try service.register()
                    isEnabled = true
                    errorMessage = nil
                }
            } catch {
                // Revert the toggle state on error
                isEnabled = wasEnabled
                
                // Set error message for display
                let errorDescription = error.localizedDescription
                if errorDescription.contains("notFound") || errorDescription.contains("not found") {
                    errorMessage = "Failed to register login item. The app may need to be in the Applications folder."
                } else if errorDescription.contains("permission") || errorDescription.contains("authorized") {
                    errorMessage = "Permission denied. Please check System Settings > General > Login Items."
                } else {
                    errorMessage = "Failed to toggle login item: \(errorDescription)"
                }
                
                print("Failed to toggle login item: \(error.localizedDescription)")
            }
        }
    }
}
