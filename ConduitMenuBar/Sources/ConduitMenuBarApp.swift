import SwiftUI
import AppKit

// MARK: - Main App

@main
struct ConduitMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Empty scene - we only use the menu bar
        Settings {
            EmptyView()
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var conduitManager: ConduitManager?
    var updateTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Initialize manager
        conduitManager = ConduitManager()

        // Setup menu
        setupMenu()

        // Start status update timer
        updateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
        updateStatus()
    }

    func setupMenu() {
        let menu = NSMenu()

        // Status header with icon
        let statusItem = NSMenuItem(title: "○ Conduit: Checking...", action: nil, keyEquivalent: "")
        statusItem.tag = 100  // Tag for updating
        menu.addItem(statusItem)

        // Node ID (clickable to copy)
        let nodeIdItem = NSMenuItem(title: "Node: Loading...", action: #selector(copyNodeId), keyEquivalent: "")
        nodeIdItem.tag = 101
        menu.addItem(nodeIdItem)

        // Client stats
        let statsItem = NSMenuItem(title: "Clients: -", action: nil, keyEquivalent: "")
        statsItem.tag = 102
        menu.addItem(statsItem)

        menu.addItem(NSMenuItem.separator())

        // Control items
        let startItem = NSMenuItem(title: "▶ Start", action: #selector(startConduit), keyEquivalent: "s")
        startItem.tag = 200
        menu.addItem(startItem)

        let stopItem = NSMenuItem(title: "■ Stop", action: #selector(stopConduit), keyEquivalent: "x")
        stopItem.tag = 201
        menu.addItem(stopItem)

        menu.addItem(NSMenuItem.separator())

        // Terminal manager
        menu.addItem(NSMenuItem(title: "Open Terminal Manager...", action: #selector(openTerminal), keyEquivalent: "t"))

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        self.statusItem?.menu = menu
    }

    func updateStatus() {
        guard let manager = conduitManager else { return }

        let isRunning = manager.isContainerRunning()

        // Update icon - globe with color indicating status
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "Conduit")
            button.image?.isTemplate = false
            // Green when running, gray when stopped
            button.contentTintColor = isRunning ? NSColor.systemGreen : NSColor.systemGray
        }

        // Update menu items
        if let menu = statusItem?.menu {
            // Status text
            if let statusMenuItem = menu.item(withTag: 100) {
                statusMenuItem.title = isRunning ? "● Conduit: Running" : "○ Conduit: Stopped"
            }

            // Node ID
            if let nodeIdItem = menu.item(withTag: 101) {
                if let nodeId = manager.getNodeId() {
                    let shortId = String(nodeId.prefix(20)) + "..."
                    nodeIdItem.title = "Node: \(shortId)"
                    nodeIdItem.toolTip = "Click to copy full Node ID: \(nodeId)"
                    nodeIdItem.isEnabled = true
                } else {
                    nodeIdItem.title = "Node: Not available"
                    nodeIdItem.isEnabled = false
                }
            }

            // Client stats
            if let statsItem = menu.item(withTag: 102) {
                if isRunning, let stats = manager.getStats() {
                    statsItem.title = "Clients: \(stats.connected) connected"
                } else {
                    statsItem.title = "Clients: -"
                }
            }

            // Update Start/Stop button states
            if let startItem = menu.item(withTag: 200) {
                startItem.title = isRunning ? "↻ Restart" : "▶ Start"
            }

            if let stopItem = menu.item(withTag: 201) {
                stopItem.isEnabled = isRunning
            }
        }
    }

    @objc func startConduit() {
        conduitManager?.startContainer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.updateStatus()
        }
        showNotification(title: "Conduit", body: "Starting Conduit service...")
    }

    @objc func stopConduit() {
        conduitManager?.stopContainer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.updateStatus()
        }
        showNotification(title: "Conduit", body: "Conduit service stopped")
    }

    @objc func copyNodeId() {
        if let nodeId = conduitManager?.getNodeId() {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(nodeId, forType: .string)
            showNotification(title: "Copied", body: "Node ID copied to clipboard")
        }
    }

    @objc func openTerminal() {
        let scriptPath = findConduitScript()
        if let path = scriptPath {
            let script = """
            tell application "Terminal"
                activate
                do script "\(path)"
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        } else {
            showNotification(title: "Error", body: "Conduit script not found")
        }
    }

    func findConduitScript() -> String? {
        let possiblePaths = [
            "\(NSHomeDirectory())/conduit-manager/conduit-mac.sh",
            "/usr/local/bin/conduit",
            "\(NSHomeDirectory())/conduit-mac.sh"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }

    func showNotification(title: String, body: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = body
        notification.soundName = nil
        NSUserNotificationCenter.default.deliver(notification)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }
}

// MARK: - Conduit Manager

class ConduitManager {
    let containerName = "conduit-mac"

    func isContainerRunning() -> Bool {
        let output = runCommand("docker", arguments: ["ps", "--format", "{{.Names}}"])
        return output.contains(containerName)
    }

    func isDockerRunning() -> Bool {
        let output = runCommand("docker", arguments: ["info"])
        return !output.isEmpty && !output.contains("error")
    }

    func startContainer() {
        if !isContainerRunning() {
            // Check if container exists but is stopped
            let allContainers = runCommand("docker", arguments: ["ps", "-a", "--format", "{{.Names}}"])
            if allContainers.contains(containerName) {
                _ = runCommand("docker", arguments: ["start", containerName])
            }
            // If container doesn't exist, user needs to use the terminal script
        } else {
            _ = runCommand("docker", arguments: ["restart", containerName])
        }
    }

    func stopContainer() {
        _ = runCommand("docker", arguments: ["stop", containerName])
    }

    func getNodeId() -> String? {
        // Use docker to read the key file
        let output = runCommand("docker", arguments: [
            "run", "--rm",
            "-v", "conduit-data:/data",
            "alpine",
            "cat", "/data/conduit_key.json"
        ])

        if output.isEmpty || output.contains("error") {
            return nil
        }

        // Parse the JSON to extract privateKeyBase64
        // This is a simplified extraction
        if let range = output.range(of: "privateKeyBase64\":\"") {
            let start = range.upperBound
            if let end = output[start...].firstIndex(of: "\"") {
                let base64Key = String(output[start..<end])
                // Decode and get last 32 bytes, then re-encode
                if let data = Data(base64Encoded: base64Key), data.count >= 32 {
                    let last32 = data.suffix(32)
                    return last32.base64EncodedString().replacingOccurrences(of: "=", with: "")
                }
            }
        }
        return nil
    }

    func getStats() -> (connected: Int, connecting: Int)? {
        let output = runCommand("docker", arguments: ["logs", "--tail", "50", containerName])

        // Parse STATS line
        let lines = output.components(separatedBy: "\n")
        for line in lines.reversed() {
            if line.contains("[STATS]") {
                // Extract Connected: X
                if let connRange = line.range(of: "Connected: ") {
                    let start = connRange.upperBound
                    var numStr = ""
                    for char in line[start...] {
                        if char.isNumber {
                            numStr.append(char)
                        } else {
                            break
                        }
                    }
                    if let connected = Int(numStr) {
                        return (connected, 0)
                    }
                }
            }
        }
        return nil
    }

    private func runCommand(_ command: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()

        // GUI apps don't inherit shell PATH, so we need to use absolute paths
        // Docker Desktop installs docker CLI to /usr/local/bin/docker
        let executablePath: String
        if command == "docker" {
            // Try common Docker paths
            let dockerPaths = [
                "/usr/local/bin/docker",
                "/opt/homebrew/bin/docker",
                "/Applications/Docker.app/Contents/Resources/bin/docker"
            ]
            executablePath = dockerPaths.first { FileManager.default.fileExists(atPath: $0) } ?? "/usr/local/bin/docker"
        } else {
            executablePath = "/usr/bin/env"
        }

        if command == "docker" {
            process.executableURL = URL(fileURLWithPath: executablePath)
            process.arguments = arguments
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
        }

        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
