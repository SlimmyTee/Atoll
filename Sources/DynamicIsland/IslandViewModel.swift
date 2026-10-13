import Foundation
import SwiftUI
import Combine

public enum IslandTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case shelf = "Shelf"
    case timer = "Timer"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .dashboard: return "rectangle.split.2x1.fill"
        case .shelf: return "tray.and.arrow.down.fill"
        case .timer: return "timer"
        }
    }
}

@MainActor
public class IslandViewModel: ObservableObject {
    @Published public var isExpanded: Bool = false
    @Published public var isPinned: Bool = false
    @Published public var activeTab: IslandTab = .dashboard
    
    @Published public var isDragOver: Bool = false
    @Published public var droppedFiles: [FilePocketItem] = []
    
    // Timer state
    @Published public var isTimerActive: Bool = false
    @Published public var timerSecondsRemaining: Int = 300 // 5 min default
    @Published public var timerInitialSeconds: Int = 300
    private var countdownTimer: Timer?
    
    // Quick Settings State
    @Published public var isMuted: Bool = false
    
    // Adaptive Shrink / Expand State
    @Published public var forceFullDashboard: Bool = false
    
    public var hasImminentMeeting: Bool {
        guard let meeting = calendar.nextMeeting else { return false }
        return meeting.isImminent
    }
    
    // In Dashboard tab: should we show the compact single-card view or full dual-card view?
    public var isCompactDashboard: Bool {
        // 1. If the current frontmost app consumes a lot of menu bar space (e.g. Antigravity IDE, Xcode, etc.),
        // automatically shrink to compact mode to prevent any collision or crowding!
        if menuSpaceMonitor.isSpaceConstrained {
            return !forceFullDashboard
        }
        
        // 2. When on an app with ample clearance (Finder, Safari, Notes, Slack, etc.):
        // Automatically expand back to full dual-card dashboard!
        return false
    }
    
    public var currentExpandedWidth: CGFloat {
        switch activeTab {
        case .dashboard:
            return isCompactDashboard ? 340 : 580
        case .shelf:
            return isCompactDashboard ? 380 : 480
        case .timer:
            return 360
        }
    }
    
    public var currentExpandedHeight: CGFloat {
        switch activeTab {
        case .dashboard:
            return 130
        case .shelf:
            return 136
        case .timer:
            return 130
        }
    }
    
    public func toggleDashboardSize() {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
            forceFullDashboard.toggle()
        }
    }
    
    // Controllers
    public let media = MediaController()
    public let calendar = CalendarController()
    public let menuSpaceMonitor = MenuBarSpaceMonitor()
    
    private var collapseWorkItem: DispatchWorkItem?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // Forward updates from nested ObservableObjects
        media.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        calendar.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        menuSpaceMonitor.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
        
        checkMuteState()
    }
    
    public func onMouseEnter() {
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
        checkMuteState()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.isExpanded = true
        }
    }
    
    public func onMouseLeave() {
        guard !isPinned else { return }
        
        collapseWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isPinned else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                self.isExpanded = false
            }
        }
        collapseWorkItem = workItem
        // Tight 0.06s debounce: collapses immediately when cursor exits
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06, execute: workItem)
    }
    
    public func toggleExpand() {
        collapseWorkItem?.cancel()
        withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
            self.isExpanded.toggle()
        }
    }
    
    // File shelf methods
    public func addFile(url: URL) {
        if !droppedFiles.contains(where: { $0.url == url }) {
            withAnimation {
                droppedFiles.insert(FilePocketItem(url: url), at: 0)
                activeTab = .shelf
                isExpanded = true
            }
        }
    }
    
    public func removeFile(_ item: FilePocketItem) {
        withAnimation {
            droppedFiles.removeAll { $0.id == item.id }
        }
    }
    
    public func clearShelf() {
        withAnimation {
            droppedFiles.removeAll()
        }
    }
    
    // Timer controls
    public func startTimer(minutes: Int) {
        timerInitialSeconds = minutes * 60
        timerSecondsRemaining = timerInitialSeconds
        isTimerActive = true
        
        countdownTimer?.invalidate()
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.timerSecondsRemaining > 0 {
                    self.timerSecondsRemaining -= 1
                } else {
                    self.stopTimer()
                    NSSound.beep()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        countdownTimer = timer
    }
    
    public func stopTimer() {
        isTimerActive = false
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    public var formattedTimer: String {
        let mins = timerSecondsRemaining / 60
        let secs = timerSecondsRemaining % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    // Quick Settings
    public func checkMuteState() {
        Task.detached(priority: .background) {
            let script = "output muted of (get volume settings)"
            if let scriptObj = NSAppleScript(source: script) {
                var error: NSDictionary?
                let output = scriptObj.executeAndReturnError(&error)
                if error == nil {
                    let muted = output.booleanValue
                    await MainActor.run {
                        self.isMuted = muted
                    }
                }
            }
        }
    }
    
    public func toggleMute() {
        let newMuted = !isMuted
        self.isMuted = newMuted
        Task.detached(priority: .userInitiated) {
            let script = "set volume output muted \(newMuted)"
            if let scriptObj = NSAppleScript(source: script) {
                var error: NSDictionary?
                _ = scriptObj.executeAndReturnError(&error)
            }
        }
    }
    
    public func lockScreen() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }
}
