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
    
    var detailedInfo: String {
        """
        Port: \(port)
        Protocol: \(protocolType.uppercased())
        State: \(state)
        Address: \(address)
        Process: \(processName)
        PID: \(processID)
        """
    }
}
