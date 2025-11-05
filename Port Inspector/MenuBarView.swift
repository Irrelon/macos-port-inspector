//
//  MenuBarView.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var portScanner: PortScanner
    @ObservedObject var loginItemManager: LoginItemManager
    @State private var searchText = ""
    @State private var selectedPort: PortInfo?
    
    // Filter toggles
    @State private var showListen = true
    @State private var showEstablished = true
    @State private var showOther = true
    @State private var showTCP = true
    @State private var showUDP = true
    
    var filteredPorts: [PortInfo] {
        var ports = portScanner.ports
        
        // Filter by state
        ports = ports.filter { port in
            let state = port.state.uppercased()
            if state.contains("LISTEN") {
                return showListen
            } else if state.contains("ESTABLISHED") {
                return showEstablished
            } else {
                return showOther
            }
        }
        
        // Filter by protocol
        ports = ports.filter { port in
            let proto = port.protocolType.lowercased()
            if proto.contains("tcp") {
                return showTCP
            } else if proto.contains("udp") {
                return showUDP
            }
            return true
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            ports = ports.filter { port in
                "\(port.port)".contains(searchText) ||
                port.processName.localizedCaseInsensitiveContains(searchText) ||
                port.protocolType.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return ports
    }
    
    func killProcess(pid: Int) {
        // Kill the process using kill command
        let killTask = Process()
        killTask.executableURL = URL(fileURLWithPath: "/bin/kill")
        killTask.arguments = ["-9", "\(pid)"]
        
        do {
            try killTask.run()
            killTask.waitUntilExit()
            
            print("Killed process \(pid), waiting before refresh...")
            
            // Clear selection immediately
            selectedPort = nil
            
            // Give the system time to clean up the process
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Refreshing port list after kill...")
                // Refresh the port list
                portScanner.scanPorts()
            }
        } catch {
            print("Failed to kill process \(pid): \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Irrelon Port Inspector")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    portScanner.scanPorts()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh port list")
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Quit Port Inspector")
            }
            .padding()
            
            Divider()
            
            // Auto-start toggle
            HStack {
                Toggle("Start at login", isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { newValue in
                        if newValue != loginItemManager.isEnabled {
                            loginItemManager.toggleLoginItem()
                        }
                    }
                ))
                .toggleStyle(.checkbox)
                .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search ports or processes...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Filter toggles
            VStack(spacing: 8) {
                // State filters
                HStack(spacing: 12) {
                    Text("State:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Listen", isOn: $showListen)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Toggle("Established", isOn: $showEstablished)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Toggle("Other", isOn: $showOther)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Spacer()
                }
                
                // Protocol filters
                HStack(spacing: 12) {
                    Text("Protocol:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("TCP", isOn: $showTCP)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Toggle("UDP", isOn: $showUDP)
                        .toggleStyle(.checkbox)
                        .font(.caption)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Content
            if portScanner.isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning ports...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = portScanner.errorMessage {
                VStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    Text("Error")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("Try Again") {
                        portScanner.scanPorts()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredPorts.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: searchText.isEmpty ? "network.slash" : "magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty ? "No active ports found" : "No matching ports")
                        .font(.headline)
                    Text(searchText.isEmpty ? "No listening ports detected on your system" : "Try a different search term")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(filteredPorts) { port in
                            PortRowView(
                                port: port,
                                isSelected: selectedPort?.id == port.id,
                                onKillProcess: killProcess
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if selectedPort?.id == port.id {
                                    selectedPort = nil
                                } else {
                                    selectedPort = port
                                }
                            }
                        }
                    }
                }
            }
            
            // Footer
            if !portScanner.isLoading && !filteredPorts.isEmpty {
                Divider()
                HStack {
                    Text("\(filteredPorts.count) port\(filteredPorts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Updated: \(Date().formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(8)
            }
        }
        .frame(width: 400, height: 500)
        .onAppear {
            // Check login item status when menu opens
            loginItemManager.checkLoginItemStatus()
            
            if portScanner.ports.isEmpty {
                portScanner.scanPorts()
            }
        }
        .alert("Login Item Error", isPresented: .constant(loginItemManager.errorMessage != nil)) {
            Button("OK") {
                loginItemManager.errorMessage = nil
            }
        } message: {
            Text(loginItemManager.errorMessage ?? "")
        }
    }
}

struct PortRowView: View {
    let port: PortInfo
    let isSelected: Bool
    let onKillProcess: (Int) -> Void
    
    @State private var commandLine: String = ""
    @State private var isLoadingCommand = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Protocol badge
                Text(port.protocolType.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(protocolColor.opacity(0.2))
                    .foregroundColor(protocolColor)
                    .cornerRadius(4)
                
                // Port number
                Text(":\(String(port.port))")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                
                Spacer()
                
                // State
                Text(port.state)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                // Process info
                Text(port.processName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("PID: \(port.processID)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Show details when selected
            if isSelected {
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    Text("Address: \(port.address)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Command:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if isLoadingCommand {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(height: 10)
                        } else {
                            Text(commandLine)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                                .truncationMode(.middle)
                        }
                    }
                    
                    Button(action: {
                        onKillProcess(port.processID)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                            Text("Kill Process (PID: \(port.processID))")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(4)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Terminate this process")
                }
                .transition(.opacity)
                .onAppear {
                    loadCommandLine()
                }
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
    }
    
    private var protocolColor: Color {
        switch port.protocolType.lowercased() {
        case "tcp", "tcp4", "tcp6":
            return .blue
        case "udp", "udp4", "udp6":
            return .green
        default:
            return .gray
        }
    }
    
    private func loadCommandLine() {
        guard commandLine.isEmpty else { return }
        
        isLoadingCommand = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let cmd = port.getCommandLine()
            
            DispatchQueue.main.async {
                commandLine = cmd
                isLoadingCommand = false
            }
        }
    }
}

#Preview {
    MenuBarView(portScanner: PortScanner(), loginItemManager: LoginItemManager())
}
