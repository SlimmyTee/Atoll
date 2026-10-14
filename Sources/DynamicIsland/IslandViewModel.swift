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
    @Published public var isDwellExpanded: Bool = false
    private var dwellTimer: DispatchWorkItem?
    
    // Meeting Alert Heads-Up
    @Published public var activeMeetingAlert: MeetingEvent? = nil
    
    // Auto-Update Manager
    @Published public var updater: UpdateManager = UpdateManager.shared
    
    public func simulateUpdateNotification() {
        updater.isUpdateAvailable = true
        updater.latestVersion = "v1.1.0"
        updater.isDismissed = false
        self.isExpanded = true
    }
    @Published public var isHovered: Bool = false
    private var meetingAlertDismissTimer: DispatchWorkItem?
    
    public var hasImminentMeeting: Bool {
        guard let meeting = calendar.nextMeeting else { return false }
        return meeting.isImminent
    }
    
    // In Dashboard tab: should we show the compact single-card view or full dual-card view?
    public var isCompactDashboard: Bool {
        // 1. If manually toggled full for this session, honor it
        if forceFullDashboard {
            return false
        }
        
        // 2. Dwell Intent: If the cursor has lingered on the island for >= 1.8 seconds,
        // automatically blossom into the full dual-card dashboard!
        if isDwellExpanded {
            return false
        }
        
        // 3. Auto-detect: If the active app consumes menu bar space (e.g. Antigravity IDE, Xcode),
        // stay in compact 340pt mode so menus stay completely visible!
        if menuSpaceMonitor.isSpaceConstrained {
            return true
        }
        
        // When space is ample (e.g. Slack, Finder, Safari, Notes), expand to full dashboard!
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
        
        menuSpaceMonitor.$activeAppName
            .dropFirst()
            .sink { [weak self] _ in
                self?.forceFullDashboard = false
            }
            .store(in: &cancellables)
        
        calendar.onMeetingAlert = { [weak self] meeting in
            Task { @MainActor in
                self?.triggerMeetingAlert(for: meeting)
            }
        }
        
        checkMuteState()
    }
    
    public func triggerMeetingAlert(for meeting: MeetingEvent) {
        meetingAlertDismissTimer?.cancel()
        
        withAnimation(.spring(response: 0.38, dampingFraction: 0.76)) {
            self.activeMeetingAlert = meeting
            self.activeTab = .dashboard
            self.isExpanded = true
        }
        
        // Auto-dismiss after 9.5 seconds if user does not hover or click
        let dismissItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            if !self.isHovered && !self.isPinned {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                    self.activeMeetingAlert = nil
                    self.isExpanded = false
                }
            }
        }
        self.meetingAlertDismissTimer = dismissItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 9.5, execute: dismissItem)
    }
    
    public func dismissMeetingAlert() {
        meetingAlertDismissTimer?.cancel()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            self.activeMeetingAlert = nil
            if !self.isHovered && !self.isPinned {
                self.isExpanded = false
            }
        }
    }
    
    public func joinActiveMeetingAlert() {
        guard let alert = activeMeetingAlert, let link = alert.meetingLink else { return }
        CalendarController.openMeeting(url: link, accountEmail: alert.accountEmail)
        dismissMeetingAlert()
    }

    public func onMouseEnter() {
        isHovered = true
        meetingAlertDismissTimer?.cancel()
        collapseWorkItem?.cancel()
        collapseWorkItem = nil
        checkMuteState()
        menuSpaceMonitor.evaluateCurrentApp()
        
        // Dwell Intent: If the cursor remains hovered for 1.8 seconds, automatically expand fully!
        dwellTimer?.cancel()
        let timerItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.isExpanded else { return }
            withAnimation(.spring(response: 0.36, dampingFraction: 0.78)) {
                self.isDwellExpanded = true
            }
        }
        dwellTimer = timerItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: timerItem)
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.isExpanded = true
        }
    }
    
    public func onMouseLeave() {
        isHovered = false
        dwellTimer?.cancel()
        dwellTimer = nil
        
        guard !isPinned else { return }
        
        collapseWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, !self.isPinned else { return }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                self.isExpanded = false
                self.isDwellExpanded = false
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
        // Collapse the island so it is neat when returning
        self.isExpanded = false
        
        // Method 1: Private login.framework SACLockScreenImmediate (immediate authentic macOS lock screen)
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
        if let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            defer { dlclose(handle) }
            if let sym = dlsym(handle, "SACLockScreenImmediate") {
                let lockFunc = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lockFunc()
                return
            }
        }
        
        // Method 2: Fallback to System Events shortcut (Control + Command + Q)
        let script = "tell application \"System Events\" to keystroke \"q\" using {control down, command down}"
        if let scriptObj = NSAppleScript(source: script) {
            var error: NSDictionary?
            _ = scriptObj.executeAndReturnError(&error)
        }
    }
}
