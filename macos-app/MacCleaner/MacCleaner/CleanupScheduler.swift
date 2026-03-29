import Foundation
import Combine
import UserNotifications

/// Manages scheduled cleanup operations
@MainActor
class CleanupScheduler: ObservableObject {
    
    static let shared = CleanupScheduler()
    
    @Published var isScheduleEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isScheduleEnabled, forKey: "CleanupScheduleEnabled")
            if isScheduleEnabled {
                scheduleNextCleanup()
            } else {
                cancelScheduledCleanup()
            }
        }
    }
    
    @Published var scheduleFrequency: ScheduleFrequency {
        didSet {
            UserDefaults.standard.set(scheduleFrequency.rawValue, forKey: "CleanupScheduleFrequency")
            if isScheduleEnabled {
                scheduleNextCleanup()
            }
        }
    }
    
    @Published var lastCleanupDate: Date? {
        didSet {
            if let date = lastCleanupDate {
                UserDefaults.standard.set(date, forKey: "LastCleanupDate")
            }
        }
    }
    
    private init() {
        self.isScheduleEnabled = UserDefaults.standard.bool(forKey: "CleanupScheduleEnabled")
        if let rawValue = UserDefaults.standard.string(forKey: "CleanupScheduleFrequency"),
           let frequency = ScheduleFrequency(rawValue: rawValue) {
            self.scheduleFrequency = frequency
        } else {
            self.scheduleFrequency = .weekly
        }
        self.lastCleanupDate = UserDefaults.standard.object(forKey: "LastCleanupDate") as? Date
    }
    
    enum ScheduleFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var days: Int {
            switch self {
            case .daily: return 1
            case .weekly: return 7
            case .monthly: return 30
            }
        }
    }
    
    /// Request notification permissions
    func requestNotificationPermissions() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
    
    /// Schedule the next cleanup
    func scheduleNextCleanup() {
        cancelScheduledCleanup()
        
        let center = UNUserNotificationCenter.current()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "MacBook Cleaner"
        content.body = "Time for your scheduled cleanup!"
        content.sound = .default
        content.categoryIdentifier = "CLEANUP_REMINDER"
        
        // Calculate next run date
        let nextDate = calculateNextRunDate()
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: nextDate)
        
        // Create trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(identifier: "scheduledCleanup", content: content, trigger: trigger)
        
        // Schedule
        center.add(request) { error in
            if let error = error {
                print("Error scheduling cleanup: \(error)")
            }
        }
    }
    
    /// Cancel scheduled cleanup
    func cancelScheduledCleanup() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["scheduledCleanup"])
    }
    
    /// Calculate when the next cleanup should run
    func calculateNextRunDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // If never run before, schedule for tomorrow at 10 AM
        guard let lastRun = lastCleanupDate else {
            var components = calendar.dateComponents([.year, .month, .day], from: now)
            components.hour = 10
            components.minute = 0
            components.day? += 1
            return calendar.date(from: components) ?? now.addingTimeInterval(86400)
        }
        
        // Calculate next run based on frequency
        let daysToAdd = scheduleFrequency.days
        return calendar.date(byAdding: .day, value: daysToAdd, to: lastRun) ?? now
    }
    
    /// Check if cleanup should run now
    func shouldRunCleanup() -> Bool {
        guard isScheduleEnabled else { return false }
        
        guard let lastRun = lastCleanupDate else {
            return true // Never run before
        }
        
        let nextRun = calculateNextRunDate()
        return Date() >= nextRun
    }
    
    /// Mark cleanup as completed
    func markCleanupCompleted() {
        lastCleanupDate = Date()
        if isScheduleEnabled {
            scheduleNextCleanup()
        }
    }
    
    /// Get next scheduled date as string
    var nextScheduledDateString: String {
        guard isScheduleEnabled else { return "Not scheduled" }
        
        let nextDate = calculateNextRunDate()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextDate)
    }
}
