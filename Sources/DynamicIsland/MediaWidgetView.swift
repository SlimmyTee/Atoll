import SwiftUI
import AppKit

public struct MediaWidgetView: View {
    @ObservedObject var media: MediaController
    
    public var body: some View {
        HStack(spacing: 16) {
            // Album art with ambient glow
            ZStack {
                if let data = media.currentTrack.artworkData, let nsImage = NSImage(data: data) {
                    // Ambient glow
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .blur(radius: 14)
                        .opacity(0.55)
                    
                    // Main Artwork
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .shadow(color: Color.purple.opacity(0.4), radius: 12, x: 0, y: 4)
                    
                    Image(systemName: "music.note")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 80, height: 80)
            .animation(.easeInOut(duration: 0.3), value: media.currentTrack.artworkData != nil)
            
            // Track Info & Controls
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(media.currentTrack.title)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(media.currentTrack.artist)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.72))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    // Source badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(media.currentTrack.source == .spotify ? Color.green : Color.pink)
                            .frame(width: 6, height: 6)
                        Text(media.currentTrack.source.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                
                // Progress Bar
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 4)
                            
                            let progress = media.currentTrack.duration > 0 ?
                                min(max(media.currentTrack.position / media.currentTrack.duration, 0), 1) : 0
                            
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * CGFloat(progress), height: 4)
                        }
                    }
                    .frame(height: 4)
                    
                    HStack {
                        Text(formatTime(media.currentTrack.position))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Text(formatTime(media.currentTrack.duration))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Playback Buttons
                HStack(spacing: 24) {
                    Spacer()
                    
                    Button(action: { media.previousTrack() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { media.togglePlayPause() }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                            
                            Image(systemName: media.isAudioPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.black)
                                .offset(x: media.isAudioPlaying ? 0 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { media.nextTrack() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 6)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
