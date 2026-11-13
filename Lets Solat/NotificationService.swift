import Foundation
import UserNotifications
#if os(macOS)
import AppKit
#endif

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    public static let shared = NotificationService()
    
    private let center = UNUserNotificationCenter.current()
    private let testNotificationId = "solat_test_notification"
    
    #if os(macOS)
    private var activeSound: NSSound?
    #endif
    
    public var isShortAdhanEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettings.shortAdhanKey)
    }
    
    public override init() {
        super.init()
        center.delegate = self
        ensureSoundsInLibrarySounds()
    }
    
    /// Ensures adhan sound files exist in ~/Library/Sounds inside the app container,
    /// which allows macOS's usernoted daemon to reliably locate custom notification sounds.
    private func ensureSoundsInLibrarySounds() {
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else { return }
        let soundsURL = libraryURL.appendingPathComponent("Sounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: soundsURL, withIntermediateDirectories: true)
        
        for ext in ["caf", "aiff"] {
            let filename = "adhan.\(ext)"
            let destURL = soundsURL.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: destURL.path) {
                if let bundleURL = Bundle.main.url(forResource: "adhan", withExtension: ext) {
                    try? FileManager.default.copyItem(at: bundleURL, to: destURL)
                }
            }
        }
    }
    
    /// Play Adhan sound directly via NSSound (macOS)
    public func playAdhanSound() {
        guard isShortAdhanEnabled else { return }
        #if os(macOS)
        let soundURL = Bundle.main.url(forResource: "adhan", withExtension: "caf")
            ?? Bundle.main.url(forResource: "adhan", withExtension: "aiff")
            ?? FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
                .appendingPathComponent("Sounds/adhan.caf")
        
        if let soundURL = soundURL {
            activeSound?.stop()
            activeSound = NSSound(contentsOf: soundURL, byReference: true)
            activeSound?.play()
        }
        #endif
    }
    
    /// Request notification authorization
    public func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
            let granted = try await center.requestAuthorization(options: options)
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current notification authorization status
    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Open macOS System Settings directly to Notifications
    public func openSystemNotificationSettings() {
        #if os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
        #endif
    }
    
    /// Schedule prayer notifications for today's data and optionally tomorrow's data
    public func schedulePrayerNotifications(
        for dayData: PrayerTimeDayData,
        tomorrowData: PrayerTimeDayData? = nil,
        locationName: String? = nil
    ) async {
        // Clear previously scheduled prayer notifications first
        await cancelAllPrayerNotifications()
        
        let now = Date()
        let calendar = Calendar.current
        let loc = locationName ?? LocalizationManager.shared.string(for: .yourLocation)
        
        // 1. Schedule today's future prayers
        await scheduleDayPrayers(dayData, now: now, calendar: calendar, loc: loc)
        
        // 2. Schedule tomorrow's prayers if available
        if let tomorrow = tomorrowData {
            await scheduleDayPrayers(tomorrow, now: now, calendar: calendar, loc: loc)
        }
    }
    
    private func scheduleDayPrayers(
        _ dayData: PrayerTimeDayData,
        now: Date,
        calendar: Calendar,
        loc: String
    ) async {
        for prayer in SolatPrayer.allCases {
            guard let prayerDate = dayData.dateForPrayer(prayer.rawValue) else { continue }
            
            // Only schedule future prayers
            guard prayerDate > now else { continue }
            
            let content = UNMutableNotificationContent()
            content.title = LocalizationManager.shared.string(for: .notificationTitle(prayer.displayName))
            content.body = LocalizationManager.shared.string(for: .notificationBody(prayer.displayName, loc))
            
            // When short adhan is enabled, do not play notification sound so only short adhan plays.
            // Otherwise, play the standard notification sound.
            if isShortAdhanEnabled {
                content.sound = nil
            } else {
                content.sound = .default
            }
            
            content.interruptionLevel = .active
            content.userInfo = ["prayer": prayer.rawValue, "type": "solat_alert"]
            
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayerDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            
            let identifier = "solat_notification_\(prayer.rawValue)_\(dayData.date)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            try? await center.add(request)
        }
    }
    
    /// Trigger an immediate test notification
    public func sendTestNotification(title: String? = nil, body: String? = nil) async {
        // Play Short Adhan if enabled
        if isShortAdhanEnabled {
            playAdhanSound()
        }
        
        // Ensure notification authorization
        let status = await checkAuthorizationStatus()
        if status == .notDetermined {
            _ = await requestAuthorization()
        }
        
        // Clear any previous test notification so macOS presents a fresh banner
        center.removeDeliveredNotifications(withIdentifiers: [testNotificationId])
        center.removePendingNotificationRequests(withIdentifiers: [testNotificationId])
        
        // Construct content
        let content = UNMutableNotificationContent()
        content.title = title ?? LocalizationManager.shared.string(for: .appTitle)
        content.body = body ?? LocalizationManager.shared.string(for: .testNotificationBody)
        
        // When short adhan is enabled, do not play notification sound so only short adhan plays.
        if isShortAdhanEnabled {
            content.sound = nil
        } else {
            content.sound = .default
        }
        content.interruptionLevel = .active
        
        // Post immediate notification request
        let request = UNNotificationRequest(identifier: testNotificationId, content: content, trigger: nil)
        
        do {
            try await center.add(request)
        } catch {
            print("Failed to add test notification request: \(error)")
        }
    }
    
    /// Cancel all prayer notifications
    public func cancelAllPrayerNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let prayerIds = pending
            .filter { $0.identifier.hasPrefix("solat_notification_") }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: prayerIds)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if isShortAdhanEnabled {
            // Play only the short adhan; omit .sound from presentation options to suppress the system notification sound
            playAdhanSound()
            
            #if os(macOS)
            if #available(macOS 11.0, *) {
                completionHandler([.banner, .badge, .list])
            } else {
                completionHandler([.alert, .badge])
            }
            #else
            completionHandler([.banner, .badge])
            #endif
        } else {
            // Play standard notification sound
            #if os(macOS)
            if #available(macOS 11.0, *) {
                completionHandler([.banner, .badge, .sound, .list])
            } else {
                completionHandler([.alert, .badge, .sound])
            }
            #else
            completionHandler([.banner, .sound, .badge])
            #endif
        }
    }
}
