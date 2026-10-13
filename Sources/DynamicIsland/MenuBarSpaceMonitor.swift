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
        
        // Initial measurement
        evaluateCurrentApp()
    }
    
    @objc private func handleAppSwitch() {
        // Debounce slightly to allow the newly focused application's menu bar to populate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.evaluateCurrentApp()
        }
    }
    
    public func evaluateCurrentApp() {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let appName = app.localizedName ?? "App"
        self.activeAppName = appName
        
        let rightEdge = measureAppMenuRightEdge(app: app)
        self.measuredMenuRightEdge = rightEdge
        
        let screen = ScreenMetrics.currentScreen ?? NSScreen.main
        let screenWidth = screen?.frame.width ?? 1512
        let screenMidX = screenWidth / 2
        
        // Full island half-width is 290pt (580 / 2) + 25pt clearance buffer = 315pt
        let clearance = screenMidX - rightEdge
        let constrained = clearance < 315
        
        if constrained != self.isSpaceConstrained {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                self.isSpaceConstrained = constrained
            }
            #if DEBUG
            print("🧭 [MenuBarSpaceMonitor] App '\(appName)' menuRightEdge: \(rightEdge)pt -> spaceConstrained: \(constrained)")
            #endif
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
        
        // 2. Intelligent bundle heuristic fallback if AX not granted
        if let bundleId = app.bundleIdentifier?.lowercased() {
            let wideApps = [
                "ide", "code", "xcode", "studio", "intellij", "sublime",
                "photoshop", "illustrator", "premiere", "aftereffects",
                "blender", "logic", "finalcut", "davinci"
            ]
            if wideApps.contains(where: { bundleId.contains($0) }) {
                return 520
            }
        }
        
        return 380 // Standard app clearance
    }
}
