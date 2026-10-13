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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppSwitch),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        
        // Heartbeat check every 0.5s to continuously synchronize with real active app
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.evaluateCurrentApp()
            }
            .store(in: &cancellables)
        
        evaluateCurrentApp()
    }
    
    @objc private func handleAppSwitch() {
        evaluateCurrentApp()
    }
    
    public func targetApplication() -> NSRunningApplication? {
        var candidate: NSRunningApplication?
        
        if #available(macOS 14.0, *) {
            if let mbApp = NSWorkspace.shared.menuBarOwningApplication,
               mbApp.bundleIdentifier != Bundle.main.bundleIdentifier,
               mbApp.bundleIdentifier != "com.danielumoren.dynamicisland" {
                candidate = mbApp
            }
        }
        
        if candidate == nil {
            if let front = NSWorkspace.shared.frontmostApplication,
               front.bundleIdentifier != Bundle.main.bundleIdentifier,
               front.bundleIdentifier != "com.danielumoren.dynamicisland" {
                candidate = front
            }
        }
        
        // If candidate is a background helper, find its parent main app
        if let app = candidate, let bundle = app.bundleIdentifier?.lowercased(), bundle.contains(".helper") {
            let baseId = bundle.replacingOccurrences(of: ".helper", with: "")
            if let parent = NSWorkspace.shared.runningApplications.first(where: {
                $0.bundleIdentifier?.lowercased() == baseId
            }) {
                candidate = parent
            }
        }
        
        return candidate
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
        
        // Full island half-width is 290pt.
        // A threshold of 280pt accommodates Slack (rightEdge 455pt, clearance 301pt)
        // while safely constraining apps whose menus extend into the island zone.
        let clearance = screenMidX - rightEdge
        let constrained = clearance < 280
        
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
        
        // 2. Fallback heuristic only if Accessibility is unavailable
        if let bundleId = app.bundleIdentifier?.lowercased() {
            let massiveApps = [
                "xcode", "intellij", "sublime", "antigravity",
                "photoshop", "illustrator", "premiere", "aftereffects"
            ]
            if massiveApps.contains(where: { bundleId.contains($0) }) {
                return 520
            }
        }
        
        return 430
    }
}
