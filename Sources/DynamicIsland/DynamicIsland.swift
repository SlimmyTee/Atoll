import AppKit
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    var windowController: IslandWindowController?
    var statusItem: NSStatusItem?
    let viewModel = IslandViewModel()
    private var activityToken: NSObjectProtocol?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Prevent macOS App Nap from throttling background status & media polling
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated, .latencyCritical],
            reason: "Dynamic Island real-time status monitoring"
        )
        
        // Run as accessory without Dock icon
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize Island Window Controller
        windowController = IslandWindowController(viewModel: viewModel)
        
        // Setup Status Bar Menu
        setupStatusItem()
    }
    
    func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "capsule.fill", accessibilityDescription: "Dynamic Island")
            button.imagePosition = .imageOnly
        }
        
        let menu = NSMenu()
        
        let titleItem = NSMenuItem(title: "Dynamic Island", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleItem = NSMenuItem(title: "Toggle Island", action: #selector(toggleIsland), keyEquivalent: "i")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let pinItem = NSMenuItem(title: "Pin Expanded", action: #selector(togglePin), keyEquivalent: "p")
        pinItem.target = self
        menu.addItem(pinItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let dashboardItem = NSMenuItem(title: "Dashboard (Music & Meetings)", action: #selector(switchToDashboard), keyEquivalent: "1")
        dashboardItem.target = self
        menu.addItem(dashboardItem)
        
        let shelfItem = NSMenuItem(title: "File Shelf", action: #selector(switchToShelf), keyEquivalent: "2")
        shelfItem.target = self
        menu.addItem(shelfItem)
        
        let timerItem = NSMenuItem(title: "Focus Timer", action: #selector(switchToTimer), keyEquivalent: "3")
        timerItem.target = self
        menu.addItem(timerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    @objc func toggleIsland() {
        viewModel.toggleExpand()
    }
    
    @objc func togglePin() {
        viewModel.isPinned.toggle()
        if viewModel.isPinned {
            viewModel.isExpanded = true
        }
    }
    
    @objc func switchToDashboard() {
        viewModel.activeTab = .dashboard
        viewModel.isExpanded = true
    }
    
    @objc func switchToShelf() {
        viewModel.activeTab = .shelf
        viewModel.isExpanded = true
    }
    
    @objc func switchToTimer() {
        viewModel.activeTab = .timer
        viewModel.isExpanded = true
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

@main
struct DynamicIslandMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
