import SwiftUI
import AppKit

public struct IslandView: View {
    @ObservedObject var vm: IslandViewModel
    @State private var isTargetedForDrop: Bool = false
    
    public init(vm: IslandViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // 1. Clipped Base & Content (Guarantees album art and widgets never spill outside the pill)
                ZStack {
                    RoundedRectangle(
                        cornerRadius: vm.isExpanded ? 20 : 16,
                        style: .continuous
                    )
                    .fill(Color.black)
                    
                    // Content Switcher
                    if vm.isExpanded {
                        expandedContent
                            .transition(
                                .asymmetric(
                                    insertion: .opacity
                                        .combined(with: .scale(scale: 0.96, anchor: .top))
                                        .animation(.easeOut(duration: 0.16).delay(0.06)),
                                    removal: .opacity
                                        .combined(with: .scale(scale: 0.96, anchor: .top))
                                        .animation(.easeIn(duration: 0.10))
                                )
                            )
                    } else {
                        compactContent
                            .transition(
                                .asymmetric(
                                    insertion: .opacity
                                        .animation(.easeOut(duration: 0.14).delay(0.08)),
                                    removal: .opacity
                                        .animation(.easeIn(duration: 0.08))
                                )
                            )
                    }
                }
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: vm.isExpanded ? 20 : 16,
                        style: .continuous
                    )
                )
                
                // 2. Outer Border & Natural Diffusion Shadow (Unclipped)
                RoundedRectangle(
                    cornerRadius: vm.isExpanded ? 20 : 16,
                    style: .continuous
                )
                .strokeBorder(
                    isTargetedForDrop ? Color.cyan.opacity(0.8) : Color.white.opacity(vm.isExpanded ? 0.12 : 0.05),
                    lineWidth: isTargetedForDrop ? 2 : 1
                )
                .shadow(
                    color: Color.black.opacity(vm.isExpanded ? 0.5 : 0.1),
                    radius: vm.isExpanded ? 20 : 4,
                    x: 0,
                    y: vm.isExpanded ? 8 : 2
                )
                .allowsHitTesting(false)
            }
            .frame(width: islandWidth, height: islandHeight)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: vm.isExpanded)
            .animation(.spring(response: 0.32, dampingFraction: 0.82), value: islandWidth)
            .onHover { hovering in
                if hovering {
                    vm.onMouseEnter()
                } else {
                    vm.onMouseLeave()
                }
            }
            .onDrop(of: [.fileURL], isTargeted: $isTargetedForDrop) { providers in
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        if let url = url {
                            DispatchQueue.main.async {
                                vm.addFile(url: url)
                            }
                        }
                    }
                }
                return true
            }
            .onChange(of: isTargetedForDrop) { _, targeted in
                if targeted {
                    vm.onDragTargetChanged(isTargeted: true)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    // Dynamic dimensions
    private var islandWidth: CGFloat {
        if vm.isExpanded {
            return vm.currentExpandedWidth
        }
        if isTargetedForDrop {
            return 320
        }
        if vm.media.isAudioPlaying || vm.isTimerActive {
            return ScreenMetrics.notchWidth + 80
        }
        return ScreenMetrics.notchWidth + 20
    }
    
    private var islandHeight: CGFloat {
        if vm.isExpanded {
            return vm.currentExpandedHeight
        }
        return ScreenMetrics.notchHeight
    }
    
    // MARK: - Compact Content
    private var compactContent: some View {
        HStack(spacing: 0) {
            // Left Ear: exactly 40pt to the left of the physical camera cutout
            HStack {
                if vm.media.hasActiveMedia, let data = vm.media.currentTrack.artworkData, let nsImg = NSImage(data: data) {
                    Image(nsImage: nsImg)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 19, height: 19)
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                } else if vm.media.hasActiveMedia && vm.media.isAudioPlaying {
                    Circle()
                        .fill(LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 8))
                                .foregroundColor(.white)
                        )
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 40, alignment: .center)
            
            // Middle: Sits directly behind physical camera notch
            Spacer(minLength: 0)
                .frame(width: ScreenMetrics.notchWidth)
            
            // Right Ear: exactly 40pt to the right of the physical camera cutout
            HStack {
                if isTargetedForDrop {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.cyan)
                } else if vm.updater.isUpdateAvailable && !vm.updater.isDismissed {
                    HStack(spacing: 2) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 5, height: 5)
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 8.5))
                            .foregroundColor(.cyan)
                    }
                } else if vm.isTimerActive {
                    Text(vm.formattedTimer)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.orange)
                } else if vm.media.isAudioPlaying {
                    CompactWaveformView()
                } else {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40, alignment: .center)
        }
        .frame(width: islandWidth, height: islandHeight)
        .contentShape(Rectangle())
        .onTapGesture {
            vm.toggleExpand()
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 5) {
            // Header Bar
            HStack(spacing: 0) {
                // Dashboard Tab (Left)
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        vm.activeTab = .dashboard
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: IslandTab.dashboard.iconName)
                            .font(.system(size: 10))
                        Text(IslandTab.dashboard.rawValue)
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(vm.activeTab == .dashboard ? .white : .white.opacity(0.5))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(vm.activeTab == .dashboard ? Color.white.opacity(0.15) : Color.clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 24)
                
                // Right Button Group (Shifted right to give physical camera notch plenty of clearance)
                HStack(spacing: 5) {
                    // Shelf Tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            vm.activeTab = .shelf
                        }
                    }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: IslandTab.shelf.iconName)
                                .font(.system(size: 9.5))
                            if !vm.isCompactDashboard {
                                Text(IslandTab.shelf.rawValue)
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                            
                            if !vm.droppedFiles.isEmpty {
                                Text("\(vm.droppedFiles.count)")
                                    .font(.system(size: 8, weight: .bold))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Color.white.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        .foregroundColor(vm.activeTab == .shelf ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(vm.activeTab == .shelf ? Color.white.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    // Timer Tab
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            vm.activeTab = .timer
                        }
                    }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: IslandTab.timer.iconName)
                                .font(.system(size: 9.5))
                            if !vm.isCompactDashboard {
                                Text(IslandTab.timer.rawValue)
                                    .font(.system(size: 9.5, weight: .medium))
                            }
                        }
                        .foregroundColor(vm.activeTab == .timer ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(vm.activeTab == .timer ? Color.white.opacity(0.15) : Color.clear)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    
                    // Shrink / Expand toggle in Dashboard tab
                    if vm.activeTab == .dashboard {
                        Button(action: {
                            vm.toggleDashboardSize()
                        }) {
                            Image(systemName: vm.isCompactDashboard ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.65))
                                .padding(4.5)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .help(vm.isCompactDashboard ? "Expand to Full Dashboard" : "Shrink to Compact Player")
                    }
                    
                    // Pin Button
                    Button(action: {
                        vm.isPinned.toggle()
                    }) {
                        Image(systemName: vm.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 9.5))
                            .foregroundColor(vm.isPinned ? .orange : .white.opacity(0.4))
                            .padding(4.5)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help(vm.isPinned ? "Unpin Island" : "Pin Island open")
                    
                    // Collapse Button
                    Button(action: {
                        vm.toggleExpand()
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(4.5)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 10)
            .padding(.trailing, 8)
            .padding(.top, 6)
            
            // Tab Body
            Group {
                switch vm.activeTab {
                case .dashboard:
                    DashboardSplitView(vm: vm)
                case .shelf:
                    FilePocketView(vm: vm)
                case .timer:
                    TimerWidgetView(vm: vm)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
        }
    }
}

// Side-by-side Music + Calendar Dashboard
struct DashboardSplitView: View {
    @ObservedObject var vm: IslandViewModel
    
    var body: some View {
        VStack(spacing: 5) {
            if vm.updater.isUpdateAvailable && !vm.updater.isDismissed {
                updateAvailableBanner
            } else if let alert = vm.activeMeetingAlert {
                meetingAlertBanner(alert: alert)
            } else if vm.isCompactDashboard {
                compactContent
            } else {
                fullContent
            }
            
            bottomUtilityRow
        }
    }
    
    private var updateAvailableBanner: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 30, height: 30)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.cyan)
            }
            
            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 5) {
                    Text("UPDATE AVAILABLE")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(Color.cyan.opacity(0.18))
                        .clipShape(Capsule())
                    
                    Text("Atoll \(vm.updater.latestVersion)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Text(vm.updater.isUpdating ? vm.updater.updateStatusMessage : "A faster, smoother release is ready.")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if vm.updater.isUpdating {
                ProgressView()
                    .scaleEffect(0.65)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .padding(.trailing, 6)
            } else {
                Button(action: {
                    vm.updater.triggerUpdate()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 9.5))
                        Text("Update Now")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: Color.blue.opacity(0.4), radius: 4, x: 0, y: 1.5)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    vm.updater.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .padding(4)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private func meetingAlertBanner(alert: MeetingEvent) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Image(systemName: "video.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text("STARTING NOW")
                        .font(.system(size: 8, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(Color.green.opacity(0.18))
                        .clipShape(Capsule())
                    
                    if let platform = alert.videoPlatformName {
                        Text(platform)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    if let email = alert.accountEmail {
                        Text("• \(email)")
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                }
                
                Text(alert.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button(action: {
                vm.joinActiveMeetingAlert()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "video.fill")
                        .font(.system(size: 9))
                    Text("Join Call")
                        .font(.system(size: 10.5, weight: .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color.blue.opacity(0.5), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                vm.dismissMeetingAlert()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .strokeBorder(Color.green.opacity(0.35), lineWidth: 1)
                )
        )
    }
    
    private var compactContent: some View {
        Group {
            if vm.media.isAudioPlaying || !vm.media.currentTrack.title.isEmpty {
                musicPlayerCard
            } else if vm.calendar.nextMeeting != nil {
                calendarCard
            } else {
                musicPlayerCard
            }
        }
    }
    
    private var fullContent: some View {
        HStack(spacing: 8) {
            musicPlayerCard
            
            // Sleek Divider
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(width: 1, height: 68)
            
            calendarCard
        }
    }
    
    private var musicPlayerCard: some View {
        Group {
            if vm.media.hasActiveMedia {
                activeMusicPlayerCard
            } else {
                emptyMusicPlayerCard
            }
        }
    }
    
    private var emptyMusicPlayerCard: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.35))
            }
            .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("No Media Playing")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Play on Spotify, Apple Music, or YouTube")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var activeMusicPlayerCard: some View {
        HStack(spacing: 8) {
                    // Album Art
                    ZStack {
                        if let data = vm.media.currentTrack.artworkData, let nsImage = NSImage(data: data) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .blur(radius: 6)
                                .opacity(0.35)
                            
                            Image(nsImage: nsImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(LinearGradient(colors: [.purple.opacity(0.6), .blue.opacity(0.5)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: "music.note")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 44, height: 44)
                    
                    // Track Details & Controls
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Text(vm.media.currentTrack.title)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            
                            Spacer(minLength: 2)
                            
                            // If in compact mode and there is an upcoming meeting later today, show a subtle chip
                            if vm.isCompactDashboard, let next = vm.calendar.nextMeeting {
                                Button(action: { vm.toggleDashboardSize() }) {
                                    HStack(spacing: 2.5) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 7.5))
                                        Text(next.timeUntilFormatted)
                                            .font(.system(size: 7.5, weight: .bold))
                                    }
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 4.5)
                                    .padding(.vertical, 1.5)
                                    .background(Color.cyan.opacity(0.14))
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                                .help("Next meeting: \(next.title). Click to expand.")
                            }
                            
                            Circle()
                                .fill(vm.media.currentTrack.source == .spotify ? Color.green : Color.pink)
                                .frame(width: 4.5, height: 4.5)
                        }
                        
                        Text(vm.media.currentTrack.artist)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                        
                        // Progress Bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 2.5)
                                
                                let progress = vm.media.currentTrack.duration > 0 ?
                                    min(max(vm.media.currentTrack.position / vm.media.currentTrack.duration, 0), 1) : 0
                                
                                Capsule()
                                    .fill(Color.white.opacity(0.85))
                                    .frame(width: geo.size.width * CGFloat(progress), height: 2.5)
                            }
                        }
                        .frame(height: 2.5)
                        .padding(.vertical, 1)
                        
                        // Controls Row
                        HStack(spacing: 12) {
                            Button(action: { vm.media.previousTrack() }) {
                                Image(systemName: "backward.fill")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { vm.media.togglePlayPause() }) {
                                Image(systemName: vm.media.isAudioPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 17))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                            
                            Button(action: { vm.media.nextTrack() }) {
                                Image(systemName: "forward.fill")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 2.5) {
                if !vm.calendar.hasCalendarAccess {
                    VStack(spacing: 4) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 18))
                            .foregroundColor(.cyan)
                        
                        Text("Connect Calendar")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Button(action: {
                            if vm.calendar.authorizationStatus == .denied {
                                vm.calendar.openCalendarSettings()
                            } else {
                                vm.calendar.requestAccess()
                            }
                        }) {
                            Text(vm.calendar.authorizationStatus == .denied ? "Settings" : "Allow")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Color.white)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let next = vm.calendar.nextMeeting {
                    HStack {
                        Text(next.timeUntilFormatted)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(next.isOngoing ? .green : (next.isAllDay ? .purple : .cyan))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background((next.isOngoing ? Color.green : (next.isAllDay ? Color.purple : Color.cyan)).opacity(0.15))
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        Text(next.timeRangeFormatted)
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Text(next.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 5) {
                        if let loc = next.location, !loc.isEmpty {
                            HStack(spacing: 3) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 8))
                                Text(loc)
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.white.opacity(0.55))
                            .lineLimit(1)
                        } else if let platform = next.videoPlatformName, !next.canJoinNow {
                            HStack(spacing: 3) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 8))
                                Text(platform)
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        if next.canJoinNow, let link = next.meetingLink {
                            Button(action: { CalendarController.openMeeting(url: link, accountEmail: next.accountEmail) }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 8.5))
                                    Text("Join Call")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                                )
                                .clipShape(Capsule())
                                .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 1)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Second upcoming meeting or all-day note
                    if let second = vm.calendar.upcomingMeetings.dropFirst().first {
                        HStack(spacing: 3) {
                            Text("Later:")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                            Text("\(second.title) (\(second.timeUntilFormatted))")
                                .font(.system(size: 8.5))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    } else if let allDay = vm.calendar.allDayEvent, allDay.id != next.id {
                        HStack(spacing: 3) {
                            Text("All Day:")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                            Text(allDay.title)
                                .font(.system(size: 8.5))
                                .foregroundColor(.white.opacity(0.5))
                                .lineLimit(1)
                        }
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green.opacity(0.85))
                        Text("No Upcoming Meetings")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                        Text("All clear for today")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    private var bottomUtilityRow: some View {
        HStack(spacing: 8) {
            // Left: Mute & Lock Quick Action Buttons
            HStack(spacing: 6) {
                // Mute / Unmute
                Button(action: { vm.toggleMute() }) {
                    HStack(spacing: 4) {
                        Image(systemName: vm.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 10))
                            .foregroundColor(vm.isMuted ? .red : .white.opacity(0.8))
                        Text(vm.isMuted ? "Unmute" : "Mute")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(vm.isMuted ? .red : .white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(vm.isMuted ? Color.red.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(vm.isMuted ? Color.red.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                
                // Lock Screen
                Button(action: { vm.lockScreen() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                        Text("Lock")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Right: Focus Timer & File Shelf Quick Access
            HStack(spacing: 6) {
                // Focus Timer
                HStack(spacing: 4) {
                    Image(systemName: "timer")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.orange)
                    
                    if vm.isTimerActive {
                        Text(vm.formattedTimer)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        
                        Button(action: { vm.stopTimer() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 3) {
                            ForEach([5, 15, 25], id: \.self) { mins in
                                Button(action: { vm.startTimer(minutes: mins) }) {
                                    Text("\(mins)m")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.white.opacity(0.08))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .clipShape(Capsule())
                

            }
            .padding(.horizontal, 2)
        }
    }
}

struct CompactWaveformView: View {
    @State private var animating: Bool = false
    
    var body: some View {
        HStack(spacing: 2) {
            bar(duration: 0.45)
            bar(duration: 0.35)
            bar(duration: 0.55)
            bar(duration: 0.4)
        }
        .onAppear { animating = true }
    }
    
    private func bar(duration: Double) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.green)
            .frame(width: 2.5, height: animating ? CGFloat.random(in: 4...12) : 4)
            .animation(
                Animation.easeInOut(duration: duration)
                    .repeatForever(autoreverses: true),
                value: animating
            )
    }
}
