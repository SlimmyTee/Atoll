import Foundation
import EventKit
import SwiftUI
import Combine

public struct MeetingEvent: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let meetingLink: URL?
    public let calendarTitle: String
    public let accountEmail: String?
    
    public var isOngoing: Bool {
        if isAllDay { return false }
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    public var minutesUntilStart: Int {
        let diff = startDate.timeIntervalSince(Date())
        return max(0, Int(diff / 60))
    }
    
    public var secondsUntilStart: Int {
        let diff = startDate.timeIntervalSince(Date())
        return Int(diff)
    }
    
    // An event is imminent if it is ongoing or starts within 45 minutes
    public var isImminent: Bool {
        if isOngoing { return true }
        if isAllDay { return false }
        return minutesUntilStart <= 45
    }
    
    // Only show join action when the meeting is ongoing or within 10 minutes of starting
    public var canJoinNow: Bool {
        guard meetingLink != nil else { return false }
        if isOngoing { return true }
        return minutesUntilStart <= 10
    }
    
    public var videoPlatformName: String? {
        guard let link = meetingLink else { return nil }
        let str = link.absoluteString.lowercased()
        if str.contains("meet.google.com") { return "Google Meet" }
        if str.contains("zoom.us") { return "Zoom" }
        if str.contains("teams.microsoft.com") { return "Teams" }
        if str.contains("webex.com") { return "Webex" }
        if str.contains("facetime.apple.com") { return "FaceTime" }
        return "Video Call"
    }
    
    public var timeUntilFormatted: String {
        if isAllDay {
            return "All day"
        }
        if isOngoing {
            return "Happening now"
        }
        let mins = minutesUntilStart
        if mins < 1 {
            return "Starting now"
        } else if mins < 60 {
            return "In \(mins)m"
        } else {
            let hours = mins / 60
            let remMins = mins % 60
            return remMins > 0 ? "In \(hours)h \(remMins)m" : "In \(hours)h"
        }
    }
    
    public var timeRangeFormatted: String {
        if isAllDay {
            return "All day"
        }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: endDate))"
    }
}

// MARK: - Smart Chrome & Multi-Profile Tab Integration
public struct ChromeIntegration {
    /// Checks if Google Chrome already has a tab open matching this meeting URL/code, and brings it forward.
    public static func activateExistingMeetingTab(meetingURL: URL) -> Bool {
        guard let slug = extractMeetingSlug(from: meetingURL), !slug.isEmpty else { return false }
        
        let script = """
        tell application "System Events"
            set isRunning to (name of processes) contains "Google Chrome"
        end tell
        if isRunning then
            tell application "Google Chrome"
                repeat with w in windows
                    set tabIndex to 1
                    repeat with t in tabs of w
                        if (URL of t contains "\(slug)") then
                            set active tab index of w to tabIndex
                            set index of w to 1
                            activate
                            return true
                        end if
                        set tabIndex to tabIndex + 1
                    end repeat
                end repeat
            end tell
        end if
        return false
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            let result = appleScript.executeAndReturnError(&error)
            if error == nil && result.booleanValue {
                return true
            }
        }
        return false
    }
    
    /// Extracts the unique meeting code or slug (e.g. "abc-defg-hij" for Google Meet, or "123456789" for Zoom)
    public static func extractMeetingSlug(from url: URL) -> String? {
        let str = url.absoluteString.lowercased()
        
        // Google Meet: meet.google.com/xxx-yyyy-zzz
        if str.contains("meet.google.com") {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !path.isEmpty {
                return path.components(separatedBy: "/").last ?? path
            }
        }
        
        // Zoom: zoom.us/j/123456789 or zoom.us/my/slug
        if str.contains("zoom.us/j/") || str.contains("zoom.us/my/") {
            let comps = url.path.components(separatedBy: "/").filter { !$0.isEmpty }
            if let idx = comps.firstIndex(where: { $0 == "j" || $0 == "my" }), idx + 1 < comps.count {
                return comps[idx + 1]
            }
        }
        
        // Microsoft Teams meeting ID in path
        if str.contains("teams.microsoft.com") {
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            if !path.isEmpty {
                return path.components(separatedBy: "/").last
            }
        }
        
        return nil
    }
    
    /// Looks up Chrome's Local State to find which Profile folder belongs to the given email address
    public static func findProfileDirectory(for email: String) -> String? {
        let localStatePath = ("~/Library/Application Support/Google/Chrome/Local State" as NSString).expandingTildeInPath
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: localStatePath)),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let profileDict = json["profile"] as? [String: Any],
              let infoCache = profileDict["info_cache"] as? [String: [String: Any]] else {
            return nil
        }
        
        let target = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !target.isEmpty else { return nil }
        
        for (profileDir, info) in infoCache {
            let userName = (info["user_name"] as? String)?.lowercased() ?? ""
            let name = (info["name"] as? String)?.lowercased() ?? ""
            
            if userName == target || userName.contains(target) || target.contains(userName) && !userName.isEmpty {
                return profileDir
            }
            if name == target {
                return profileDir
            }
        }
        return nil
    }
    
    /// Launches or focuses Google Chrome with the specific profile directory and appends authuser query parameter
    public static func openInChrome(url: URL, accountEmail: String?) {
        var finalURL = url
        
        // If it's a Google Meet link and we have an account email, append ?authuser=<email>
        if let email = accountEmail, url.absoluteString.lowercased().contains("meet.google.com") {
            if var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                var items = components.queryItems ?? []
                if !items.contains(where: { $0.name == "authuser" }) {
                    items.append(URLQueryItem(name: "authuser", value: email))
                    components.queryItems = items
                    if let newURL = components.url {
                        finalURL = newURL
                    }
                }
            }
        }
        
        // Try finding the exact Chrome profile directory
        let profileDir = accountEmail.flatMap { findProfileDirectory(for: $0) }
        
        let task = Process()
        task.launchPath = "/usr/bin/open"
        
        if let profile = profileDir {
            task.arguments = ["-a", "Google Chrome", "--args", "--profile-directory=\(profile)", finalURL.absoluteString]
        } else {
            task.arguments = ["-a", "Google Chrome", finalURL.absoluteString]
        }
        
        do {
            try task.run()
        } catch {
            NSWorkspace.shared.open(finalURL)
        }
    }
}

@MainActor
public class CalendarController: ObservableObject {
    @Published public var upcomingMeetings: [MeetingEvent] = []
    @Published public var nextMeeting: MeetingEvent?
    @Published public var allDayEvent: MeetingEvent?
    @Published public var hasCalendarAccess: Bool = false
    @Published public var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    /// Callback invoked when a meeting is starting or imminent (within 90s)
    public var onMeetingAlert: ((MeetingEvent) -> Void)?
    
    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    private var alertCheckTimer: Timer?
    private var alertedMeetingIds: Set<String> = []
    
    public init() {
        checkAuthorization()
        
        // Periodic calendar events refresh (every 60s)
        let timer = Timer(timeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
        
        // High-precision proximity alert check (every 10s)
        let alertTimer = Timer(timeInterval: 10.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkProximityAlerts()
            }
        }
        RunLoop.main.add(alertTimer, forMode: .common)
        alertCheckTimer = alertTimer
    }
    
    public func checkAuthorization() {
        let status = EKEventStore.authorizationStatus(for: .event)
        self.authorizationStatus = status
        
        if #available(macOS 14.0, *) {
            if status == .fullAccess || status == .writeOnly || status.rawValue == 3 {
                hasCalendarAccess = true
                refreshEvents()
                return
            }
        }
        
        if status == .authorized {
            hasCalendarAccess = true
            refreshEvents()
            return
        }
        
        hasCalendarAccess = false
        upcomingMeetings = []
        nextMeeting = nil
    }
    
    public func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                Task { @MainActor in
                    self?.hasCalendarAccess = granted
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self?.refreshEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                Task { @MainActor in
                    self?.hasCalendarAccess = granted
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    if granted {
                        self?.refreshEvents()
                    }
                }
            }
        }
    }
    
    public func openCalendarSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
    
    public func refreshEvents() {
        guard hasCalendarAccess else {
            upcomingMeetings = []
            nextMeeting = nil
            allDayEvent = nil
            return
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let endOfTomorrow = Calendar.current.date(byAdding: .day, value: 2, to: startOfDay) ?? now.addingTimeInterval(86400 * 2)
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfTomorrow, calendars: nil)
        
        let rawEvents = eventStore.events(matching: predicate)
        
        var timedList: [MeetingEvent] = []
        var allDayList: [MeetingEvent] = []
        
        for ev in rawEvents {
            // Only show events that have not ended yet
            if ev.endDate < now { continue }
            
            let durationHours = Calendar.current.dateComponents([.hour], from: ev.startDate, to: ev.endDate).hour ?? 0
            let isAllDay = ev.isAllDay || durationHours >= 23
            
            let meetingLink = Self.extractLink(from: ev)
            let email = Self.extractAccountEmail(from: ev)
            
            let item = MeetingEvent(
                id: ev.eventIdentifier ?? UUID().uuidString,
                title: ev.title ?? "Untitled Event",
                startDate: ev.startDate,
                endDate: ev.endDate,
                isAllDay: isAllDay,
                location: ev.location,
                meetingLink: meetingLink,
                calendarTitle: ev.calendar.title,
                accountEmail: email
            )
            
            if isAllDay {
                allDayList.append(item)
            } else {
                timedList.append(item)
            }
        }
        
        // Sort timed events: ongoing events first, then upcoming chronologically
        timedList.sort { a, b in
            if a.isOngoing != b.isOngoing {
                return a.isOngoing && !b.isOngoing
            }
            return a.startDate < b.startDate
        }
        
        allDayList.sort { $0.startDate < $1.startDate }
        
        self.allDayEvent = allDayList.first
        
        // Priority: Timed meetings/events ALWAYS take precedence!
        if let topTimed = timedList.first {
            self.nextMeeting = topTimed
            self.upcomingMeetings = timedList
        } else if let topAllDay = allDayList.first {
            self.nextMeeting = topAllDay
            self.upcomingMeetings = allDayList
        } else {
            self.nextMeeting = nil
            self.upcomingMeetings = []
        }
        
        checkProximityAlerts()
    }
    
    /// Evaluates if a meeting is about to start or has just started, firing the onMeetingAlert notification
    public func checkProximityAlerts() {
        guard let meeting = nextMeeting, meeting.meetingLink != nil else { return }
        let now = Date()
        let secs = meeting.startDate.timeIntervalSince(now)
        
        // Trigger alert if meeting starts in <= 90 seconds (1.5 minutes) OR just started within the last 60 seconds
        if (secs <= 90 && secs >= -60) && !alertedMeetingIds.contains(meeting.id) {
            alertedMeetingIds.insert(meeting.id)
            onMeetingAlert?(meeting)
        }
    }
    
    // MARK: - Account Email Extraction
    private nonisolated static func extractAccountEmail(from event: EKEvent) -> String? {
        // 1. Current user attendee
        if let attendees = event.attendees {
            for att in attendees where att.isCurrentUser {
                let spec = (att.url as NSURL).resourceSpecifier ?? att.url.absoluteString.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive)
                if isValidEmail(spec) {
                    return spec
                }
            }
        }
        
        // 2. Calendar title (e.g. "danielumoren@enyata.com")
        let calTitle = event.calendar.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidEmail(calTitle) {
            return calTitle
        }
        if let email = findEmail(in: calTitle) {
            return email
        }
        
        // 3. Calendar source title
        let srcTitle = event.calendar.source.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if isValidEmail(srcTitle) {
            return srcTitle
        }
        if let email = findEmail(in: srcTitle) {
            return email
        }
        
        // 4. Organizer
        if let org = event.organizer {
            let spec = (org.url as NSURL).resourceSpecifier ?? org.url.absoluteString.replacingOccurrences(of: "mailto:", with: "", options: .caseInsensitive)
            if isValidEmail(spec) {
                return spec
            }
        }
        
        return nil
    }
    
    private nonisolated static func isValidEmail(_ str: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return str.range(of: pattern, options: .regularExpression) != nil
    }
    
    private nonisolated static func findEmail(in text: String) -> String? {
        let pattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            if let match = regex.firstMatch(in: text, options: [], range: range),
               let r = Range(match.range, in: text) {
                return String(text[r])
            }
        }
        return nil
    }
    
    private nonisolated static func extractLink(from event: EKEvent) -> URL? {
        if let url = event.url, isMeetingURL(url) {
            return url
        }
        if let location = event.location, let url = findMeetingURL(in: location) {
            return url
        }
        if let notes = event.notes, let url = findMeetingURL(in: notes) {
            return url
        }
        return event.url
    }
    
    private nonisolated static func isMeetingURL(_ url: URL) -> Bool {
        let str = url.absoluteString.lowercased()
        return str.contains("meet.google.com") ||
               str.contains("zoom.us") ||
               str.contains("teams.microsoft.com") ||
               str.contains("webex.com") ||
               str.contains("facetime.apple.com")
    }
    
    private nonisolated static func findMeetingURL(in text: String) -> URL? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        for match in matches {
            if let url = match.url, isMeetingURL(url) {
                return url
            }
        }
        return nil
    }
    
    // MARK: - Smart Meeting App & Chrome Launcher
    public static func openMeeting(url: URL, accountEmail: String? = nil) {
        // 1. Check if Chrome already has this meeting open in any tab!
        if ChromeIntegration.activateExistingMeetingTab(meetingURL: url) {
            return
        }
        
        // 2. Check for native app deep-link (Teams, Zoom, Webex)
        if let native = nativeMeetingURL(for: url) {
            let success = NSWorkspace.shared.open(native)
            if success { return }
        }
        
        // 3. Open in Google Chrome with the matching email profile!
        let chromeAppURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome")
        if chromeAppURL != nil {
            ChromeIntegration.openInChrome(url: url, accountEmail: accountEmail)
            return
        }
        
        // 4. Fallback to default system browser
        var targetURL = url
        if let email = accountEmail, url.absoluteString.lowercased().contains("meet.google.com") {
            if var comps = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                var items = comps.queryItems ?? []
                if !items.contains(where: { $0.name == "authuser" }) {
                    items.append(URLQueryItem(name: "authuser", value: email))
                    comps.queryItems = items
                    if let u = comps.url { targetURL = u }
                }
            }
        }
        NSWorkspace.shared.open(targetURL)
    }
    
    public static func nativeMeetingURL(for url: URL) -> URL? {
        let str = url.absoluteString
        let lower = str.lowercased()
        
        // Microsoft Teams (New and Classic)
        if lower.contains("teams.microsoft.com") || lower.contains("teams.live.com") || lower.contains("teams.microsoft.us") {
            let probe = URL(string: "msteams:")!
            if NSWorkspace.shared.urlForApplication(toOpen: probe) != nil {
                let nativeStr = str.replacingOccurrences(of: "https://", with: "msteams://")
                                   .replacingOccurrences(of: "http://", with: "msteams://")
                return URL(string: nativeStr)
            }
        }
        
        // Zoom
        if lower.contains("zoom.us/j/") || lower.contains("zoom.us/my/") {
            let probe = URL(string: "zoommtg:")!
            if NSWorkspace.shared.urlForApplication(toOpen: probe) != nil {
                if let components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    let pathComponents = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
                    if let keyIndex = pathComponents.firstIndex(where: { $0 == "j" || $0 == "my" }), keyIndex + 1 < pathComponents.count {
                        let meetingId = pathComponents[keyIndex + 1]
                        var zoomComponents = URLComponents(string: "zoommtg://zoom.us/join")!
                        var queryItems = [URLQueryItem(name: "confno", value: meetingId)]
                        if let existing = components.queryItems {
                            queryItems.append(contentsOf: existing)
                        }
                        zoomComponents.queryItems = queryItems
                        return zoomComponents.url
                    }
                }
            }
        }
        
        // Cisco Webex
        if lower.contains("webex.com") {
            let probe = URL(string: "webex:")!
            if NSWorkspace.shared.urlForApplication(toOpen: probe) != nil {
                let nativeStr = str.replacingOccurrences(of: "https://", with: "webex://")
                                   .replacingOccurrences(of: "http://", with: "webex://")
                return URL(string: nativeStr)
            }
        }
        
        return nil
    }
}
