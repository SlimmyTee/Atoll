import Foundation
import Combine
import AppKit

public struct TrackInfo: Sendable, Equatable {
    public var title: String
    public var artist: String
    public var album: String
    public var isPlaying: Bool
    public var position: Double
    public var duration: Double
    public var source: MediaSource
    public var artworkUrl: String?
    public var artworkData: Data?
    
    public enum MediaSource: String, Sendable {
        case spotify = "Spotify"
        case appleMusic = "Apple Music"
        case demo = "Now Playing"
    }
    
    public static var demoTrack: TrackInfo {
        TrackInfo(
            title: "Starboy",
            artist: "The Weeknd ft. Daft Punk",
            album: "Starboy",
            isPlaying: true,
            position: 45.0,
            duration: 230.0,
            source: .demo,
            artworkUrl: "https://i.scdn.co/image/ab67616d00001e025551adb75cf7c4737f93ed1d",
            artworkData: nil
        )
    }
}

@MainActor
public class MediaController: ObservableObject {
    @Published public var currentTrack: TrackInfo = .demoTrack
    @Published public var isAudioPlaying: Bool = true
    
    private var pollTimer: DispatchSourceTimer?
    private let pollQueue = DispatchQueue(label: "com.danielumoren.dynamicisland.mediaPoll", qos: .userInitiated)
    private var artworkCache: [String: Data] = [:]
    
    // Persistent disk cache directory for instant 0ms artwork loads
    private nonisolated static let cacheDirectory: URL? = {
        let urls = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        guard let cacheDir = urls.first?.appendingPathComponent("DynamicIsland/Artwork") else { return nil }
        try? FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()
    
    // Persistent URLSession with HTTP/2 and disk caching enabled
    private nonisolated static let imageSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.httpMaximumConnectionsPerHost = 6
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    
    public init() {
        setupDistributedNotifications()
        startPolling()
    }
    
    deinit {
        pollTimer?.cancel()
    }
    
    private func setupDistributedNotifications() {
        let center = DistributedNotificationCenter.default()
        
        // Listen for immediate Spotify track & state changes
        center.addObserver(
            forName: NSNotification.Name("com.spotify.client.PlaybackStateChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMedia()
            }
        }
        
        // Listen for immediate Apple Music track & state changes
        center.addObserver(
            forName: NSNotification.Name("com.apple.Music.playerInfo"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshMedia()
            }
        }
    }
    
    public func startPolling() {
        pollTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(flags: .strict, queue: pollQueue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(750), leeway: .milliseconds(50))
        timer.setEventHandler { [weak self] in
            let track = Self.fetchCurrentTrack()
            Task { @MainActor [weak self] in
                self?.applyTrackUpdate(track)
            }
        }
        timer.resume()
        self.pollTimer = timer
        refreshMedia()
    }
    
    public func refreshMedia() {
        pollQueue.async { [weak self] in
            let track = Self.fetchCurrentTrack()
            Task { @MainActor [weak self] in
                self?.applyTrackUpdate(track)
            }
        }
    }
    
    private func applyTrackUpdate(_ track: TrackInfo?) {
        if var foundTrack = track {
            let artUrl = foundTrack.artworkUrl
            
            // 1. Check in-memory cache
            if let url = artUrl, !url.isEmpty, let cached = self.artworkCache[url] {
                foundTrack.artworkData = cached
            } else if let url = artUrl, !url.isEmpty, let diskData = Self.loadCachedArtworkFromDisk(for: url) {
                // 2. Check persistent disk cache (loads in <1ms)
                self.artworkCache[url] = diskData
                foundTrack.artworkData = diskData
            } else if foundTrack.title == self.currentTrack.title, let existingData = self.currentTrack.artworkData {
                // Same track: retain existing artwork
                foundTrack.artworkData = existingData
            } else if self.currentTrack.source != .demo, let previousData = self.currentTrack.artworkData {
                // Smooth transition: temporarily keep previous artwork between real tracks to prevent purple placeholder flash
                foundTrack.artworkData = previousData
            }
            
            self.currentTrack = foundTrack
            self.isAudioPlaying = foundTrack.isPlaying
            
            // Asynchronously fetch fast-resolution artwork if not already cached
            if let url = artUrl, !url.isEmpty, self.artworkCache[url] == nil {
                Task { [weak self] in
                    let data = await Self.downloadImageData(from: url)
                    guard let self = self, let data = data else { return }
                    await MainActor.run {
                        self.artworkCache[url] = data
                        Self.saveArtworkToDisk(data: data, for: url)
                        if self.currentTrack.artworkUrl == url {
                            self.currentTrack.artworkData = data
                        }
                    }
                }
            }
        } else {
            // No native player active, simulate demo track progression
            if self.currentTrack.source == .demo {
                if self.isAudioPlaying {
                    var updated = self.currentTrack
                    updated.position += 0.8
                    if updated.position > updated.duration { updated.position = 0 }
                    self.currentTrack = updated
                }
                
                if self.currentTrack.artworkData == nil, let url = self.currentTrack.artworkUrl {
                    if let cached = self.artworkCache[url] {
                        self.currentTrack.artworkData = cached
                    } else if let diskData = Self.loadCachedArtworkFromDisk(for: url) {
                        self.artworkCache[url] = diskData
                        self.currentTrack.artworkData = diskData
                    } else {
                        Task { [weak self] in
                            let data = await Self.downloadImageData(from: url)
                            guard let self = self, let data = data else { return }
                            await MainActor.run {
                                self.artworkCache[url] = data
                                Self.saveArtworkToDisk(data: data, for: url)
                                if self.currentTrack.artworkUrl == url {
                                    self.currentTrack.artworkData = data
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Disk Caching
    private nonisolated static func cacheKey(for urlString: String) -> String {
        let clean = urlString.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()
        return String(clean.suffix(48)) + ".jpg"
    }
    
    private nonisolated static func loadCachedArtworkFromDisk(for urlString: String) -> Data? {
        guard let dir = cacheDirectory else { return nil }
        let fileURL = dir.appendingPathComponent(cacheKey(for: urlString))
        return try? Data(contentsOf: fileURL)
    }
    
    private nonisolated static func saveArtworkToDisk(data: Data, for urlString: String) {
        guard let dir = cacheDirectory else { return }
        let fileURL = dir.appendingPathComponent(cacheKey(for: urlString))
        try? data.write(to: fileURL, options: .atomic)
        pruneDiskCacheIfNeeded()
    }
    
    /// Ensures disk cache stays bounded under ~3 MB (max 150 songs) by evicting oldest artwork
    private nonisolated static func pruneDiskCacheIfNeeded() {
        guard let dir = cacheDirectory else { return }
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }
        
        if files.count > 150 {
            let sorted = files.sorted { f1, f2 in
                let d1 = (try? f1.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                let d2 = (try? f2.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
                return d1 < d2
            }
            for file in sorted.prefix(30) {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }
    
    // MARK: - Image Downloader
    private nonisolated static func downloadImageData(from urlString: String) async -> Data? {
        // Optimize Spotify images: use 300x300 (00001e02) instead of 640x640 (0000b273)
        // 300x300 is 7x smaller, perfectly sharp for 80x80 Retina, and downloads in <200ms
        var targetUrlString = urlString
        if targetUrlString.contains("ab67616d0000b273") {
            targetUrlString = targetUrlString.replacingOccurrences(of: "ab67616d0000b273", with: "ab67616d00001e02")
        }
        
        guard let url = URL(string: targetUrlString) else { return nil }
        do {
            let (data, response) = try await imageSession.data(from: url)
            if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
                return data
            }
        } catch {
            // Fallback to original URL if modified failed
            if targetUrlString != urlString, let origUrl = URL(string: urlString) {
                if let (data, resp) = try? await imageSession.data(from: origUrl),
                   (resp as? HTTPURLResponse)?.statusCode == 200 {
                    return data
                }
            }
        }
        return nil
    }
    
    // MARK: - Multi-Artist & Featured Singer Parser
    public nonisolated static func parseTrackDisplay(title rawTitle: String, artist rawArtist: String, albumArtist: String? = nil) -> (title: String, artist: String) {
        var title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        var artist = rawArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Patterns to match featured singers in song titles:
        // "(feat. Singer)", "(ft. Singer)", "(with Singer)", "[feat. Singer]", "featuring Singer"
        let patterns = [
            #"(?i)\s*[\(\[]\s*(?:feat\.?|ft\.?|featuring)\s+([^\)\]]+)[\)\]]"#,
            #"(?i)\s*[\(\[]\s*with\s+([^\)\]]+)[\)\]]"#
        ]
        
        var featuredArtists: [String] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let nsTitle = title as NSString
                let matches = regex.matches(in: title, options: [], range: NSRange(location: 0, length: nsTitle.length))
                if let match = matches.first, match.numberOfRanges > 1 {
                    let featRange = match.range(at: 1)
                    let featString = nsTitle.substring(with: featRange).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !featString.isEmpty {
                        featuredArtists.append(featString)
                    }
                    title = regex.stringByReplacingMatches(in: title, options: [], range: NSRange(location: 0, length: nsTitle.length), withTemplate: "").trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        if !featuredArtists.isEmpty {
            let featCombined = featuredArtists.joined(separator: ", ")
            if !artist.lowercased().contains(featCombined.lowercased()) {
                if artist.isEmpty {
                    artist = featCombined
                } else {
                    artist = "\(artist) ft. \(featCombined)"
                }
            }
        } else if let albumArtist = albumArtist?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !albumArtist.isEmpty,
                  albumArtist.lowercased() != "various artists",
                  !artist.lowercased().contains(albumArtist.lowercased()),
                  !albumArtist.lowercased().contains(artist.lowercased()) {
            // Joint / collaborative album (e.g. Drake & 21 Savage on Her Loss)
            artist = "\(artist), \(albumArtist)"
        }
        
        return (title, artist)
    }
    
    private nonisolated static func fetchCurrentTrack() -> TrackInfo? {
        if let spotify = checkSpotify() {
            return spotify
        }
        if let music = checkAppleMusic() {
            return music
        }
        return nil
    }
    
    private nonisolated static func checkSpotify() -> TrackInfo? {
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty else {
            return nil
        }
        
        let script = """
        tell application "Spotify"
            set pState to (player state as string)
            set tName to name of current track
            set aName to artist of current track
            set alArtist to ""
            try
                set alArtist to album artist of current track
            end try
            set alName to album of current track
            set pos to player position
            set dur to (duration of current track) / 1000
            set artUrl to ""
            try
                set artUrl to artwork url of current track
            end try
            return pState & "|||" & tName & "|||" & aName & "|||" & alName & "|||" & (pos as string) & "|||" & (dur as string) & "|||" & artUrl & "|||" & alArtist
        end tell
        """
        guard let output = runAppleScriptQuery(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let isPlaying = parts[0].lowercased().contains("playing")
        let rawTitle = parts[1]
        let rawArtist = parts[2]
        let album = parts[3]
        let pos = Double(parts[4]) ?? 0
        let dur = Double(parts[5]) ?? 180
        let artUrl = parts.count >= 7 && !parts[6].isEmpty ? parts[6] : nil
        let alArtist = parts.count >= 8 ? parts[7] : nil
        
        let (title, artist) = parseTrackDisplay(title: rawTitle, artist: rawArtist, albumArtist: alArtist)
        
        return TrackInfo(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            position: pos,
            duration: dur,
            source: .spotify,
            artworkUrl: artUrl,
            artworkData: nil
        )
    }
    
    private nonisolated static func checkAppleMusic() -> TrackInfo? {
        guard !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty else {
            return nil
        }
        
        let script = """
        tell application "Music"
            set pState to (player state as string)
            set tName to name of current track
            set aName to artist of current track
            set alArtist to ""
            try
                set alArtist to album artist of current track
            end try
            set alName to album of current track
            set pos to player position
            set dur to duration of current track
            return pState & "|||" & tName & "|||" & aName & "|||" & alName & "|||" & (pos as string) & "|||" & (dur as string) & "|||" & alArtist
        end tell
        """
        guard let output = runAppleScriptQuery(script), !output.isEmpty else { return nil }
        let parts = output.components(separatedBy: "|||")
        guard parts.count >= 6 else { return nil }
        
        let isPlaying = parts[0].lowercased().contains("playing")
        let rawTitle = parts[1]
        let rawArtist = parts[2]
        let album = parts[3]
        let pos = Double(parts[4]) ?? 0
        let dur = Double(parts[5]) ?? 180
        let alArtist = parts.count >= 7 ? parts[6] : nil
        
        let (title, artist) = parseTrackDisplay(title: rawTitle, artist: rawArtist, albumArtist: alArtist)
        
        return TrackInfo(
            title: title,
            artist: artist,
            album: album,
            isPlaying: isPlaying,
            position: pos,
            duration: dur,
            source: .appleMusic,
            artworkUrl: nil,
            artworkData: nil
        )
    }
    
    public func togglePlayPause() {
        isAudioPlaying.toggle()
        currentTrack.isPlaying = isAudioPlaying
        
        let src = currentTrack.source
        Task.detached(priority: .userInitiated) {
            if src == .spotify {
                Self.runAppleScriptCommand("tell application \"Spotify\" to playpause")
            } else if src == .appleMusic {
                Self.runAppleScriptCommand("tell application \"Music\" to playpause")
            } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty {
                Self.runAppleScriptCommand("tell application \"Spotify\" to playpause")
            } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty {
                Self.runAppleScriptCommand("tell application \"Music\" to playpause")
            }
        }
        scheduleFollowUpRefreshes()
    }
    
    public func nextTrack() {
        let src = currentTrack.source
        if src == .spotify {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Spotify\" to next track")
            }
            scheduleFollowUpRefreshes()
        } else if src == .appleMusic {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Music\" to next track")
            }
            scheduleFollowUpRefreshes()
        } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Spotify\" to next track")
            }
            scheduleFollowUpRefreshes()
        } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Music\" to next track")
            }
            scheduleFollowUpRefreshes()
        } else {
            currentTrack = TrackInfo(
                title: "Blinding Lights",
                artist: "The Weeknd",
                album: "After Hours",
                isPlaying: true,
                position: 0,
                duration: 200,
                source: .demo,
                artworkUrl: "https://i.scdn.co/image/ab67616d00001e025551adb75cf7c4737f93ed1d",
                artworkData: artworkCache["https://i.scdn.co/image/ab67616d00001e025551adb75cf7c4737f93ed1d"]
            )
        }
    }
    
    public func previousTrack() {
        let src = currentTrack.source
        if src == .spotify {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Spotify\" to previous track")
            }
            scheduleFollowUpRefreshes()
        } else if src == .appleMusic {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Music\" to previous track")
            }
            scheduleFollowUpRefreshes()
        } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").isEmpty {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Spotify\" to previous track")
            }
            scheduleFollowUpRefreshes()
        } else if !NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Music").isEmpty {
            Task.detached(priority: .userInitiated) {
                Self.runAppleScriptCommand("tell application \"Music\" to previous track")
            }
            scheduleFollowUpRefreshes()
        } else {
            currentTrack = .demoTrack
        }
    }
    
    private func scheduleFollowUpRefreshes() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000) // 120ms
            self?.refreshMedia()
            try? await Task.sleep(nanoseconds: 250_000_000) // 370ms
            self?.refreshMedia()
        }
    }
    
    private nonisolated static func runAppleScriptCommand(_ source: String) {
        let timedSource = """
        with timeout of 2 seconds
            \(source)
        end timeout
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: timedSource) {
            _ = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return
            }
        }
        
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", timedSource]
        process.standardOutput = Pipe()
        process.standardError = Pipe()
        try? process.run()
        
        // Ensure process cannot hang the background thread indefinitely
        let deadline = Date().addingTimeInterval(2.0)
        while process.isRunning && Date() < deadline {
            usleep(50_000) // 50ms
        }
        if process.isRunning {
            process.terminate()
        }
    }
    
    private nonisolated static func runAppleScriptQuery(_ source: String) -> String? {
        let timedSource = """
        with timeout of 2 seconds
            \(source)
        end timeout
        """
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: timedSource) {
            let output: NSAppleEventDescriptor = scriptObject.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue ?? ""
            }
        }
        
        let process = Process()
        let pipe = Pipe()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", timedSource]
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            let deadline = Date().addingTimeInterval(2.0)
            while process.isRunning && Date() < deadline {
                usleep(50_000)
            }
            if process.isRunning {
                process.terminate()
                return nil
            }
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return result
            }
        } catch {}
        
        return nil
    }
}
