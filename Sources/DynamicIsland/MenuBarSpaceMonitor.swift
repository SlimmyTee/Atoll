import AppKit
import ApplicationServices
import Combine
import SwiftUI

@MainActor
public class MenuBarSpaceMonitor: ObservableObject {
    @Published public var isSpaceConstrained: Bool = false
    @Published public var activeAppName: String = ""
    @Published public var measuredMenuRightEdge: CGFloat = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Observe app activations across macOS
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppSwitch),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Observe screen configuration/resolution changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppSwitch),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Periodic heartbeat every 0.5s to guarantee continuous synchronization
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.evaluateCurrentApp()
            }
            .store(in: &cancellables)
        
        // Initial measurement
        evaluateCurrentApp()
    }
    
    @objc private func handleAppSwitch() {
        evaluateCurrentApp()
    }
    
    public func targetApplication() -> NSRunningApplication? {
        // Prefer menuBarOwningApplication so that hovering over or clicking the island
        // panel never causes the island to evaluate itself!
        if #available(macOS 14.0, *) {
            if let mbApp = NSWorkspace.shared.menuBarOwningApplication,
               mbApp.bundleIdentifier != Bundle.main.bundleIdentifier,
               mbApp.bundleIdentifier != "com.danielumoren.dynamicisland" {
                return mbApp
            }
        }
        
        if let front = NSWorkspace.shared.frontmostApplication,
           front.bundleIdentifier != Bundle.main.bundleIdentifier,
           front.bundleIdentifier != "com.danielumoren.dynamicisland" {
            return front
        }
        
        return nil
    }
    
    public func evaluateCurrentApp() {
        guard let app = targetApplication() else { return }
        let appName = app.localizedName ?? "App"
        self.activeAppName = appName
        
        let rightEdge = measureAppMenuRightEdge(app: app)
        self.measuredMenuRightEdge = rightEdge
        
        let screen = ScreenMetrics.currentScreen ?? NSScreen.main
        let screenWidth = screen?.frame.width ?? 1512
        let screenMidX = screenWidth / 2
        
        // Full island half-width is 290pt (580 / 2).
        // If the menu bar reaches beyond (screenMidX - 305pt), it would collide with the full 580pt island!
        let clearance = screenMidX - rightEdge
        let constrained = clearance < 305
        
        if constrained != self.isSpaceConstrained {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.isSpaceConstrained = constrained
            }
        }
    }
    
    private func measureAppMenuRightEdge(app: NSRunningApplication) -> CGFloat {
        // 1. Accessibility API measurement (Live pixel accuracy)
        if AXIsProcessTrusted() {
            let axApp = AXUIElementCreateApplication(app.processIdentifier)
            var mbObj: CFTypeRef?
            if AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &mbObj) == .success,
               let mb = mbObj {
                var childrenObj: CFTypeRef?
                if AXUIElementCopyAttributeValue(mb as! AXUIElement, kAXChildrenAttribute as CFString, &childrenObj) == .success,
                   let children = childrenObj as? [AXUIElement] {
                    var maxRight: CGFloat = 0
                    for child in children {
                        var posVal: CFTypeRef?
                        var sizeVal: CFTypeRef?
                        AXUIElementCopyAttributeValue(child, kAXPositionAttribute as CFString, &posVal)
                        AXUIElementCopyAttributeValue(child, kAXSizeAttribute as CFString, &sizeVal)
                        var p = CGPoint.zero
                        var s = CGSize.zero
                        if let pv = posVal { AXValueGetValue(pv as! AXValue, .cgPoint, &p) }
                        if let sv = sizeVal { AXValueGetValue(sv as! AXValue, .cgSize, &s) }
                        let r = p.x + s.width
                        if r > maxRight { maxRight = r }
                    }
                    if maxRight > 0 {
                        return maxRight
                    }
                }
            }
        }
        
        // 2. Intelligent bundle heuristic fallback if AX is unavailable
        if let bundleId = app.bundleIdentifier?.lowercased() {
            let wideApps = [
                "chrome", "google", "safari", "browser", "firefox", "edge", "arc", "brave", "opera",
                "ide", "code", "xcode", "studio", "intellij", "sublime", "cursor", "windsurf",
                "photoshop", "illustrator", "premiere", "aftereffects", "lightroom",
                "blender", "logic", "finalcut", "davinci", "figma", "slack", "discord", "word", "excel"
            ]
            if wideApps.contains(where: { bundleId.contains($0) }) {
                return 580 // Known wide-menu application
            }
        }
        
        return 380 // Standard clearance
    }
}
