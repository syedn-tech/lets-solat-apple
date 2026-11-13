import Foundation
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case malay = "ms"
    
    public var id: String { rawValue }
    
    public var displayName: String {
        switch self {
        case .english: return "English"
        case .malay: return "Bahasa Melayu"
        }
    }
}

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    private let languageKey = "letssolat_preferred_language"
    
    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: languageKey)
        }
    }
    
    public init() {
        if let saved = UserDefaults.standard.string(forKey: languageKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Detect device preferred language. Default to English unless user device language starts with "ms"
            let devicePreferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
            if devicePreferred.hasPrefix("ms") {
                self.currentLanguage = .malay
            } else {
                self.currentLanguage = .english
            }
        }
    }
    
    public var isMalay: Bool {
        currentLanguage == .malay
    }
    
    // MARK: - Strings
    public func string(for key: StringKey) -> String {
        switch key {
        case .appTitle:
            return "Let's Solat"
        case .detectingLocation:
            return isMalay ? "Mengesan Lokasi..." : "Detecting Location..."
        case .yourLocation:
            return isMalay ? "Kawasan Anda" : "Your Location"
        case .nextPrayer:
            return isMalay ? "Seterusnya" : "Next"
        case .inTime(let time):
            return isMalay ? "Dalam \(time)" : "In \(time)"
        case .nowOngoing:
            return isMalay ? "Sekarang" : "Ongoing"
        case .completed:
            return isMalay ? "Selesai" : "Completed"
        case .noPrayerData:
            return isMalay ? "Tiada data waktu solat" : "No prayer time data"
        case .loading:
            return isMalay ? "Sedang memuatkan waktu solat..." : "Loading prayer times..."
        case .reload:
            return isMalay ? "Muat Semula" : "Reload"
        case .refreshLocation:
            return isMalay ? "Kemas Kini Lokasi" : "Update Location"
        case .refresh:
            return isMalay ? "Segar Semula" : "Refresh"
        case .testNotification:
            return isMalay ? "Uji Notifikasi" : "Test Notification"
        case .testNotificationSent:
            return isMalay ? "Ujian Dihantar" : "Test Sent"
        case .holdToTestNotification:
            return isMalay ? "Tekan & tahan untuk uji notifikasi" : "Press & hold to test notification"
        case .openNotificationSettings:
            return isMalay ? "Tetapan Notifikasi macOS..." : "macOS Notification Settings..."
        case .quit:
            return isMalay ? "Keluar" : "Quit"
        case .openMainWindow:
            return isMalay ? "Buka Let's Solat" : "Open Let's Solat"
        case .currentPrayer:
            return isMalay ? "Semasa" : "Current"
        case .settings:
            return isMalay ? "Tetapan" : "Settings"
        case .highlightPreference:
            return isMalay ? "Pilihan Warna Waktu Solat" : "Highlight Option"
        case .menuBarDisplay:
            return isMalay ? "Paparan Menu Bar" : "Menu Bar Display"
        case .testNotificationBody:
            return isMalay ? "Ujian notifikasi waktu solat berjaya!" : "Prayer time test notification successful!"
        case .notificationTitle(let prayer):
            return isMalay ? "Waktu \(prayer) Telah Masuk" : "It's Time for \(prayer)"
        case .notificationBody(let prayer, let location):
            if isMalay {
                return "Kini masuk waktu solat \(prayer) bagi kawasan \(location) dan kawasan yang sewaktu dengannya."
            } else {
                return "It is now prayer time for \(prayer) in \(location) and surrounding areas."
            }
        case .shortAdhan:
            return isMalay ? "Azan Pendek" : "Short Adhan"
        case .playShortAdhan:
            return isMalay ? "Mainkan Azan Pendek" : "Play Short Adhan"
        case .today:
            return isMalay ? "Hari Ini" : "Today"
        case .tomorrow:
            return isMalay ? "Esok" : "Tomorrow"
        case .tomorrowPrayerTimes:
            return isMalay ? "WAKTU SOLAT ESOK" : "TOMORROW'S PRAYER TIMES"
        }
    }
    
    public enum StringKey {
        case appTitle
        case detectingLocation
        case yourLocation
        case nextPrayer
        case currentPrayer
        case settings
        case highlightPreference
        case menuBarDisplay
        case inTime(String)
        case nowOngoing
        case completed
        case noPrayerData
        case loading
        case reload
        case refreshLocation
        case refresh
        case testNotification
        case testNotificationSent
        case holdToTestNotification
        case openNotificationSettings
        case quit
        case openMainWindow
        case testNotificationBody
        case notificationTitle(String)
        case notificationBody(String, String)
        case shortAdhan
        case playShortAdhan
        case today
        case tomorrow
        case tomorrowPrayerTimes
    }
}
