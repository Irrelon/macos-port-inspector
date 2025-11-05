//
//  MenuBarView.swift
//  Port Inspector
//
//  Created by Rob Evans on 05/11/2025.
//

import SwiftUI

struct MenuBarView: View {
    @ObservedObject var portScanner: PortScanner
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
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Port Inspector")
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
                            PortRowView(port: port, isSelected: selectedPort?.id == port.id)
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
            if portScanner.ports.isEmpty {
                portScanner.scanPorts()
            }
        }
    }
}

struct PortRowView: View {
    let port: PortInfo
    let isSelected: Bool
    
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
                Text(":\(port.port)")
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
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    Text("Address: \(port.address)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
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
}

#Preview {
    MenuBarView(portScanner: PortScanner())
}
