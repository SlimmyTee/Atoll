import SwiftUI
import AppKit

public struct CalendarWidgetView: View {
    @ObservedObject var calendar: CalendarController
    
    public var body: some View {
        VStack(spacing: 12) {
            if let next = calendar.nextMeeting {
                // Primary Upcoming Meeting Card
                HStack(spacing: 14) {
                    // Left Time Indicator
                    VStack(alignment: .leading, spacing: 3) {
                        Text(next.timeUntilFormatted)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(next.isOngoing ? .green : .cyan)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background((next.isOngoing ? Color.green : Color.cyan).opacity(0.15))
                            .clipShape(Capsule())
                        
                        Text(next.timeRangeFormatted)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(width: 110, alignment: .leading)
                    
                    // Meeting Title & Details
                    VStack(alignment: .leading, spacing: 3) {
                        Text(next.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            if let loc = next.location, !loc.isEmpty {
                                HStack(spacing: 3) {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 9))
                                    Text(loc)
                                        .font(.system(size: 11))
                                }
                                .foregroundColor(.white.opacity(0.6))
                            }
                            
                            Text("•")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.4))
                            
                            Text(next.calendarTitle)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer()
                    
                    // Join Call / Action Button
                    if let link = next.meetingLink {
                        Button(action: {
                            CalendarController.openMeeting(url: link)
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 11))
                                Text("Join")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: Color.blue.opacity(0.4), radius: 6, x: 0, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                
                // Secondary / Timeline view for other meetings
                if calendar.upcomingMeetings.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(calendar.upcomingMeetings.dropFirst()) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(Color.cyan)
                                        .frame(width: 6, height: 6)
                                    
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(1)
                                        
                                        Text("\(item.timeUntilFormatted) • \(item.timeRangeFormatted)")
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                    
                                    if let link = item.meetingLink {
                                        Button(action: { CalendarController.openMeeting(url: link) }) {
                                            Image(systemName: "video.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.cyan)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.white.opacity(0.04))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            }
                        }
                    }
                    .frame(height: 38)
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 24))
                        .foregroundColor(.green.opacity(0.8))
                    Text("No upcoming meetings today")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Your calendar is all clear")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            
            // Bottom Status / Access Prompt
            if !calendar.hasCalendarAccess {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text("Showing demo events. Connect macOS Calendar:")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Button(action: {
                        calendar.requestAccess()
                    }) {
                        Text("Grant Calendar Access")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                            .underline()
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }
}
