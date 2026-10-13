import AppKit
import Foundation

public struct ScreenMetrics {
    /// Returns the target screen for Dynamic Island.
    /// Strictly targets the built-in MacBook display (with the notch/camera)
    /// and prevents the Dynamic Island from ever displaying on external screens.
    public static var currentScreen: NSScreen? {
        // Priority 1: Built-in display with physical notch/camera
        if let builtin = NSScreen.screens.first(where: { isBuiltinDisplay($0) }) {
            return builtin
        }
        
        // If no built-in screen is active (e.g. clamshell mode with only external displays),
        // return nil so the island will not display on external monitors.
        return nil
    }
    
    public static var hasBuiltinDisplay: Bool {
        NSScreen.screens.contains(where: { isBuiltinDisplay($0) })
    }
    
    public static func isBuiltinDisplay(_ screen: NSScreen) -> Bool {
        // 1. Direct CoreGraphics hardware query
        if let screenNum = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID {
            if CGDisplayIsBuiltin(screenNum) != 0 {
                return true
            }
        }
        
        // 2. Notch geometry check (MacBook safe area insets)
        if screen.auxiliaryTopLeftArea != nil || screen.safeAreaInsets.top > 0 {
            return true
        }
        
        // 3. Localized name check
        if screen.localizedName.localizedCaseInsensitiveContains("built-in") {
            return true
        }
        
        return false
    }
    
    public static var hasPhysicalNotch: Bool {
        guard let screen = currentScreen else { return false }
        return screen.safeAreaInsets.top > 0
    }
    
    public static var notchHeight: CGFloat {
        guard let screen = currentScreen else { return 32 }
        let inset = screen.safeAreaInsets.top
        return inset > 0 ? inset : 32
    }
    
    public static var notchWidth: CGFloat {
        guard let screen = currentScreen else { return 185 }
        if let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            let width = right.minX - left.maxX
            if width > 50 { return width }
        }
        return 185
    }
    
    public static var screenFrame: NSRect {
        currentScreen?.frame ?? NSRect(x: 0, y: 0, width: 1512, height: 982)
    }
    
    public static var notchCenter: CGPoint {
        let frame = screenFrame
        return CGPoint(x: frame.midX, y: frame.maxY)
    }
}
