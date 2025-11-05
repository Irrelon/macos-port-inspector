//
//  PortInfo.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import Foundation

struct PortInfo: Identifiable, Hashable {
    let id = UUID()
    let port: Int
    let processName: String
    let processID: Int
    let protocolType: String
    let state: String
    let address: String
    
    var displayName: String {
        "\(protocolType.uppercased()) :\(port) - \(processName) (PID: \(processID))"
    }
    
    func getCommandLine() -> String {
        // Fetch command line on-demand using ps
        let psTask = Process()
        psTask.executableURL = URL(fileURLWithPath: "/bin/ps")
        psTask.arguments = ["-p", "\(processID)", "-o", "command="]
        
        let outputPipe = Pipe()
        psTask.standardOutput = outputPipe
        psTask.standardError = Pipe()
        
        do {
            try psTask.run()
            
            // Read pipe before waiting to prevent deadlock
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            
            psTask.waitUntilExit()
            
            if let output = String(data: outputData, encoding: .utf8) {
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "N/A" : trimmed
            }
        } catch {
            return "N/A"
        }
        
        return "N/A"
    }
}
