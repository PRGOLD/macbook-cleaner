import Foundation
import Combine

/// Global settings for cleanup operations
struct CleanupSettings: Codable {
    
    // MARK: - Retention Periods
    
    /// Number of days after which log files should be deleted
    var logRetentionDays: Int = 30
    
    /// Number of days after which temp files should be deleted
    var tempFileRetentionDays: Int = 3
    
    /// Number of days for cache files in /private/var/folders
    var cacheRetentionDays: Int = 7
    
    /// Number of days for downloads folder cleanup
    var downloadRetentionDays: Int = 90
    
    // MARK: - Safety Options
    
    /// Enable dry run mode (preview without deleting)
    var dryRunMode: Bool = false
    
    /// Require confirmation before deleting
    var confirmBeforeDelete: Bool = true
    
    /// Create backup before deleting (for undo functionality)
    var autoBackupBeforeDelete: Bool = false
    
    /// Maximum size (in bytes) for auto-backup (prevents backing up huge files)
    var maxBackupSize: Int64 = 1024 * 1024 * 1024 // 1 GB
    
    // MARK: - Cleanup Thresholds
    
    /// Minimum file size (in bytes) to consider for cleanup
    var minimumFileSize: Int64 = 0
    
    /// Skip files accessed within this many days
    var skipRecentlyAccessedDays: Int = 7
    
    // MARK: - Browser Cleanup
    
    /// Clear Safari cache
    var clearSafariCache: Bool = true
    
    /// Clear Safari cookies
    var clearSafariCookies: Bool = false
    
    /// Clear Safari history
    var clearSafariHistory: Bool = false
    
    // MARK: - Developer Options
    
    /// Clear npm cache
    var clearNpmCache: Bool = true
    
    /// Clear Homebrew cache
    var clearHomebrewCache: Bool = true
    
    /// Clear CocoaPods cache
    var clearCocoaPodsCache: Bool = true
    
    // MARK: - Persistence
    
    private static let userDefaultsKey = "CleanupSettings"
    
    /// Shared settings instance
    static var shared: CleanupSettings = {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let settings = try? JSONDecoder().decode(CleanupSettings.self, from: data) {
            return settings
        }
        return CleanupSettings()
    }()
    
    /// Save settings to UserDefaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
    }
    
    /// Reset to defaults
    static func reset() {
        shared = CleanupSettings()
        shared.save()
    }
}

// MARK: - Settings View Model

@MainActor
class CleanupSettingsViewModel: ObservableObject {
    @Published var settings: CleanupSettings
    
    init() {
        self.settings = CleanupSettings.shared
    }
    
    func save() {
        settings.save()
        CleanupSettings.shared = settings
    }
    
    func reset() {
        settings = CleanupSettings()
        save()
    }
}
