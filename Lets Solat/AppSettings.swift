import Foundation

// MARK: - App Setting Keys & Metadata
public enum AppSettings {
    public static let shortAdhanKey = "letssolat_short_adhan_enabled"
    public static let highlightOptionKey = "letssolat_highlight_option"
    public static let menuBarDisplayOptionKey = "letssolat_menubar_display_option"
    
    // MARK: - App Version & Release Info
    public static let gitHubReleasesURL = URL(string: "https://github.com/syedn-tech/lets-solat-apple/releases")!
    
    public static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    public static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    public static var formattedVersion: String {
        "v\(appVersion) (\(buildNumber))"
    }
    
    public static var versionDisplay: String {
        "\(appVersion) (\(buildNumber))"
    }
}

// MARK: - Highlight Choice in App Views
public enum HighlightOption: String, CaseIterable, Identifiable {
    case next = "next"
    case current = "current"
    case both = "both"
    
    public var id: String { rawValue }
    
    public func displayName(isMalay: Bool) -> String {
        switch self {
        case .next:
            return isMalay ? "Waktu Seterusnya" : "Next Prayer"
        case .current:
            return isMalay ? "Waktu Semasa" : "Current Prayer"
        case .both:
            return isMalay ? "Kedua-duanya" : "Both"
        }
    }
}

// MARK: - Menu Bar Display Options
public enum MenuBarDisplayOption: String, CaseIterable, Identifiable {
    case nextPrayerWithCountdown = "next_countdown"  // e.g. "Dhuhr in 3h 33m" / "Zohor dalam 3h 33m"
    case nextPrayerTime = "next_time"               // e.g. "Next: Dhuhr (1:02 PM)" / "Seterusnya: Zohor (1:02 PM)"
    case currentPrayer = "current_prayer"           // e.g. "Isha 8:11 PM" / "Isyak 8:11 PM"
    
    public var id: String { rawValue }
    
    public func displayName(isMalay: Bool) -> String {
        switch self {
        case .nextPrayerWithCountdown:
            return isMalay ? "Waktu Seterusnya + Baki Masa (cth: Zohor dalam 3h 33m)" : "Next Prayer + Countdown (e.g. Dhuhr in 3h 33m)"
        case .nextPrayerTime:
            return isMalay ? "Waktu Solat Seterusnya (cth: Seterusnya: Zohor 1:02 PM)" : "Next Prayer Time (e.g. Next: Dhuhr 1:02 PM)"
        case .currentPrayer:
            return isMalay ? "Waktu Solat Semasa (cth: Isyak 8:11 PM)" : "Current Prayer Time (e.g. Isha 8:11 PM)"
        }
    }
    
    public func shortLabel(isMalay: Bool) -> String {
        switch self {
        case .nextPrayerWithCountdown:
            return isMalay ? "Waktu Seterusnya (Baki Masa)" : "Next Prayer (Countdown)"
        case .nextPrayerTime:
            return isMalay ? "Waktu Solat Seterusnya" : "Next Prayer Time"
        case .currentPrayer:
            return isMalay ? "Waktu Solat Semasa" : "Current Prayer Time"
        }
    }
}
