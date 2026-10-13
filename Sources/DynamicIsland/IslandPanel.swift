import AppKit
import SwiftUI

public class IslandPanel: NSPanel {
    public init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .statusBar
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        self.isMovable = false
        self.hidesOnDeactivate = false
        self.acceptsMouseMovedEvents = true
    }
    
    public override var canBecomeKey: Bool {
        return false
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
}

public class IslandHostingView<Content: View>: NSHostingView<Content> {
    public var isPointInside: ((NSPoint) -> Bool)?
    
    public override func hitTest(_ point: NSPoint) -> NSView? {
        if let check = isPointInside {
            if !check(point) {
                return nil
            }
        }
        return super.hitTest(point)
    }
}

@MainActor
public class IslandWindowController: NSObject {
    public let panel: IslandPanel
    public let viewModel: IslandViewModel
    
    private let windowWidth: CGFloat = 720
    private let windowHeight: CGFloat = 280
    
    public init(viewModel: IslandViewModel) {
        self.viewModel = viewModel
        self.panel = IslandPanel()
        super.init()
        
        setupContent()
        updatePosition()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }
    
    private func setupContent() {
        let islandView = IslandView(vm: viewModel)
        let hostingView = IslandHostingView(rootView: islandView)
        
        hostingView.isPointInside = { [weak self] point in
            guard let self = self else { return false }
            let isExp = self.viewModel.isExpanded
            let currentW: CGFloat = isExp ? (self.viewModel.currentExpandedWidth + 12) : (ScreenMetrics.notchWidth + 90)
            let currentH: CGFloat = isExp ? (self.viewModel.currentExpandedHeight + 16) : (ScreenMetrics.notchHeight + 10)
            
            let minX = (self.windowWidth - currentW) / 2
            let minY = self.windowHeight - currentH
            
            let rect = NSRect(x: minX, y: minY, width: currentW, height: currentH)
            return rect.contains(point)
        }
        
        panel.contentView = hostingView
    }
    
    public func updatePosition() {
        guard let screen = ScreenMetrics.currentScreen else {
            panel.orderOut(nil)
            return
        }
        let screenFrame = screen.frame
        
        let originX = screenFrame.midX - (windowWidth / 2)
        let originY = screenFrame.maxY - windowHeight
        
        panel.setFrame(NSRect(x: originX, y: originY, width: windowWidth, height: windowHeight), display: true)
        panel.orderFrontRegardless()
    }
    
    @objc private func screenParametersChanged() {
        Task { @MainActor in
            self.updatePosition()
        }
    }
}
