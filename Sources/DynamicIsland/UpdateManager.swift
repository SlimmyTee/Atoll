import Foundation
import SwiftUI
import Combine
import AppKit

@MainActor
public class UpdateManager: ObservableObject {
    public static let shared = UpdateManager()
    
    @Published public var isUpdateAvailable: Bool = false
    @Published public var latestVersion: String = "v1.1.0"
    @Published public var releaseURL: String = "https://github.com/SlimmyTee/Atoll/releases/latest"
    @Published public var isUpdating: Bool = false
    @Published public var updateStatusMessage: String = ""
    @Published public var isDismissed: Bool = false
    
    public let currentVersion: String = "1.0.0"
    private let repo = "SlimmyTee/Atoll"
    
    public init() {
        Task {
            await checkForUpdates()
        }
    }
    
    public func checkForUpdates() async {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/releases/latest") else { return }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.setValue("Atoll-App", forHTTPHeaderField: "User-Agent")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tagName = json["tag_name"] as? String,
               let htmlUrl = json["html_url"] as? String {
                let cleanedVersion = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
                self.latestVersion = tagName
                self.releaseURL = htmlUrl
                
                if cleanedVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    self.isUpdateAvailable = true
                }
            }
        } catch {
            // Offline or rate-limited; stay silent
        }
    }
    
    public func triggerUpdate() {
        guard !isUpdating else { return }
        isUpdating = true
        updateStatusMessage = "Installing update in background..."
        
        Task.detached(priority: .userInitiated) {
            let task = Process()
            task.launchPath = "/bin/bash"
            task.arguments = ["-c", "curl -sSL https://atoll-nine.vercel.app/install.sh | bash"]
            try? task.run()
            task.waitUntilExit()
            
            await MainActor.run {
                self.updateStatusMessage = "Updated! Relaunching..."
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/Atoll.app"))
                    NSApp.terminate(nil)
                }
            }
        }
    }
    
    public func dismiss() {
        withAnimation(.easeOut(duration: 0.2)) {
            self.isDismissed = true
        }
    }
}
