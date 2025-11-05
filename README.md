# Port Inspector

A macOS menu bar utility for monitoring active network ports and processes.

## What It Does

- Displays all active network ports on your Mac
- Shows which processes are using each port
- Lists TCP and UDP connections
- Shows connection states (LISTEN, ESTABLISHED, etc.)
- Allows filtering by protocol and state
- Displays process IDs and full command lines
- Terminate processes directly from the menu

## Features

- Lives in your macOS menu bar
- Real-time port scanning using lsof
- Search and filter capabilities
- On-demand command line viewing
- Kill processes with one click
- No Dock icon (menu bar only)

## Requirements

- macOS 15.2 or later

## Installation

- Download the release zip file: https://github.com/Irrelon/macos-port-inspector/releases
- Open the zip and move `Port Inspector.app` to Applications folder
- Launch the app
- A new icon will appear in your menu bar
- Click the icon to see the app

## Usage

- Click the menu bar icon to view active ports
- Use checkboxes to filter by state or protocol
- Search for specific ports or processes
- Click any port to see details and command line
- Click "Kill Process" button to terminate a process
- Click refresh to update the port list

## Distribution

This app is distributed outside the Mac App Store to provide full system access without sandbox restrictions.

## Technical Details

- Uses lsof to enumerate network connections
- Native Swift and SwiftUI implementation
- Requires disabled App Sandbox for system access
- Code signed with Developer ID for security

## License

MIT License
