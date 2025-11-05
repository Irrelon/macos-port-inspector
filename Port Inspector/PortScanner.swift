//
//  PortScanner.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import Foundation

class PortScanner: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func scanPorts() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let scannedPorts = self?.fetchActivePorts() ?? []
            
            DispatchQueue.main.async {
                self?.ports = scannedPorts.sorted { $0.port < $1.port }
                self?.isLoading = false
            }
        }
    }
    
    private func fetchActivePorts() -> [PortInfo] {
        var portInfoArray: [PortInfo] = []
        
        // Use lsof to get listening ports and their processes
        // -i: internet connections
        // -P: no port names
        // -n: no host names
        let lsofTask = Process()
        lsofTask.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        lsofTask.arguments = ["-i", "-P", "-n"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        lsofTask.standardOutput = outputPipe
        lsofTask.standardError = errorPipe
        
        do {
            try lsofTask.run()
            lsofTask.waitUntilExit()
            
            let exitCode = lsofTask.terminationStatus
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
            
            if exitCode != 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "lsof failed (exit code \(exitCode)): \(errorOutput)"
                }
                return []
            }
            
            if let output = String(data: outputData, encoding: .utf8) {
                print("lsof output length: \(output.count) characters")
                print("First 500 chars: \(String(output.prefix(500)))")
                portInfoArray = parseListeningPorts(output: output)
                print("Parsed \(portInfoArray.count) ports")
                
                if portInfoArray.isEmpty && !output.isEmpty {
                    DispatchQueue.main.async { [weak self] in
                        self?.errorMessage = "No ports parsed from lsof output. Raw output length: \(output.count)"
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.errorMessage = "Failed to decode lsof output"
                }
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage = "Failed to execute lsof: \(error.localizedDescription)"
            }
        }
        
        return portInfoArray
    }
    
    private func parseListeningPorts(output: String) -> [PortInfo] {
        var ports: [PortInfo] = []
        let lines = output.components(separatedBy: "\n")
        
        for line in lines.dropFirst() { // Skip header line
            let components = line.split(separator: " ", omittingEmptySubsequences: true)
            
            guard components.count >= 9 else { continue }
            
            let processName = String(components[0])
            let pidString = String(components[1])
            
            guard let pid = Int(pidString) else { continue }
            
            // Look for the connection info (usually at index 8)
            var connectionInfo = ""
            for i in 8..<components.count {
                let part = String(components[i])
                if part.contains(":") || part.contains("->") {
                    connectionInfo = part
                    break
                }
            }
            
            guard !connectionInfo.isEmpty else { continue }
            
            // Parse protocol from column 7 (TCP/UDP)
            let protocolType = components.count > 7 ? String(components[7]).lowercased() : "unknown"
            
            // Extract port and state
            if let portInfo = parseConnectionInfo(connectionInfo, protocolName: protocolType) {
                let commandLine = getCommandLine(pid: pid)
                let port = PortInfo(
                    port: portInfo.port,
                    processName: processName,
                    processID: pid,
                    protocolType: portInfo.protocolType,
                    state: portInfo.state,
                    address: portInfo.address,
                    commandLine: commandLine
                )
                ports.append(port)
            }
        }
        
        // Remove duplicates based on port and protocol
        var seen = Set<String>()
        return ports.filter { port in
            let key = "\(port.protocolType):\(port.port)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
    }
    
    private func parseConnectionInfo(_ info: String, protocolName: String) -> (port: Int, protocolType: String, state: String, address: String)? {
        // Handle format like "*:8080" or "127.0.0.1:3000" or "[::1]:5432"
        let parts = info.split(separator: "->")
        let localPart = String(parts[0])
        
        // Extract port from local address
        if let portRange = localPart.range(of: ":(\\d+)", options: .regularExpression) {
            let portString = localPart[portRange].dropFirst() // Remove the ':'
            if let port = Int(portString) {
                let state = parts.count > 1 ? "ESTABLISHED" : "LISTEN"
                return (port: port, protocolType: protocolName, state: state, address: localPart)
            }
        }
        
        return nil
    }
    
    private func getCommandLine(pid: Int) -> String {
        // Use ps to get the full command line for the process
        let psTask = Process()
        psTask.executableURL = URL(fileURLWithPath: "/bin/ps")
        psTask.arguments = ["-p", "\(pid)", "-o", "command="]
        
        let outputPipe = Pipe()
        psTask.standardOutput = outputPipe
        psTask.standardError = Pipe()
        
        do {
            try psTask.run()
            psTask.waitUntilExit()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: outputData, encoding: .utf8) {
                let trimmed = output.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.isEmpty ? "N/A" : trimmed
            }
        } catch {
            print("Failed to get command line for PID \(pid): \(error)")
        }
        
        return "N/A"
    }
}
