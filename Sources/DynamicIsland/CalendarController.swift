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
    
    public var isOngoing: Bool {
        if isAllDay { return false }
        let now = Date()
        return now >= startDate && now <= endDate
    }
    
    public var minutesUntilStart: Int {
        let diff = startDate.timeIntervalSince(Date())
        return max(0, Int(diff / 60))
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

@MainActor
public class CalendarController: ObservableObject {
    @Published public var upcomingMeetings: [MeetingEvent] = []
    @Published public var nextMeeting: MeetingEvent?
    @Published public var allDayEvent: MeetingEvent?
    @Published public var hasCalendarAccess: Bool = false
    @Published public var authorizationStatus: EKAuthorizationStatus = .notDetermined
    
    private let eventStore = EKEventStore()
    private var refreshTimer: Timer?
    
    public init() {
        checkAuthorization()
        
        let timer = Timer(timeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshEvents()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
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
        
        if status == .authorized || status.rawValue == 3 {
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
            let item = MeetingEvent(
                id: ev.eventIdentifier ?? UUID().uuidString,
                title: ev.title ?? "Untitled Event",
                startDate: ev.startDate,
                endDate: ev.endDate,
                isAllDay: isAllDay,
                location: ev.location,
                meetingLink: meetingLink,
                calendarTitle: ev.calendar.title
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
            // Only if there are zero timed events scheduled today does an all-day event take the spotlight
            self.nextMeeting = topAllDay
            self.upcomingMeetings = allDayList
        } else {
            self.nextMeeting = nil
            self.upcomingMeetings = []
        }
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
    
    // MARK: - Native Meeting App Launcher
    public static func openMeeting(url: URL) {
        if let native = nativeMeetingURL(for: url) {
            let success = NSWorkspace.shared.open(native)
            if success { return }
        }
        // Fallback to web browser if native app is not installed or deep-link failed
        NSWorkspace.shared.open(url)
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
