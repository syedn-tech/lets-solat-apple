import Foundation

// MARK: - Location Model
public struct Location: Codable, Equatable {
    public var zone: String?
    public var state: String?
    public var country: String?
    public var display: String?
    public var latitude: Double?
    public var longitude: Double?
    
    public init(
        zone: String? = nil,
        state: String? = nil,
        country: String? = nil,
        display: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.zone = zone
        self.state = state
        self.country = country
        self.display = display
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - Prayer Times API Response
public struct PrayerTimeResponse: Codable {
    public let location: Location?
    public let data: [PrayerTimeDayData]?
    public let providers: [String]?
}

// MARK: - Single Day Prayer Times
public struct PrayerTimeDayData: Codable, Identifiable, Equatable {
    public var id: String { date }
    public let date: String
    public let hijriDate: String?
    public let prayerTimes: [String: Double]?
    
    enum CodingKeys: String, CodingKey {
        case date
        case hijriDate = "hijri_date"
        case prayerTimes = "prayer_times"
    }
    
    public init(date: String, hijriDate: String? = nil, prayerTimes: [String: Double]? = nil) {
        self.date = date
        self.hijriDate = hijriDate
        self.prayerTimes = prayerTimes
    }
    
    /// Helper to get specific prayer Date
    public func dateForPrayer(_ prayerName: String) -> Date? {
        guard let ms = prayerTimes?[prayerName.lowercased()] else { return nil }
        return Date(timeIntervalSince1970: ms / 1000.0)
    }
}

// MARK: - Display Prayer Item for View Lists
public struct PrayerDisplayItem: Identifiable, Equatable {
    public let id: String
    public let prayer: SolatPrayer
    public let date: Date?
    public let dayData: PrayerTimeDayData
    public let isTomorrow: Bool
    
    public init(id: String, prayer: SolatPrayer, date: Date?, dayData: PrayerTimeDayData, isTomorrow: Bool = false) {
        self.id = id
        self.prayer = prayer
        self.date = date
        self.dayData = dayData
        self.isTomorrow = isTomorrow
    }
}

// MARK: - Standard Ordered Prayers
public enum SolatPrayer: String, CaseIterable, Identifiable {
    case imsak = "imsak"
    case fajr = "fajr"
    case sunrise = "sunrise"
    case dhuhr = "dhuhr"
    case asr = "asr"
    case maghrib = "maghrib"
    case isha = "isha"
    
    public var id: String { rawValue }
    
    public func displayName(isMalay: Bool) -> String {
        switch self {
        case .imsak: return "Imsak"
        case .fajr: return isMalay ? "Subuh" : "Fajr"
        case .sunrise: return isMalay ? "Syuruk" : "Sunrise"
        case .dhuhr: return isMalay ? "Zohor" : "Dhuhr"
        case .asr: return isMalay ? "Asar" : "Asr"
        case .maghrib: return isMalay ? "Maghrib" : "Maghrib"
        case .isha: return isMalay ? "Isyak" : "Isha"
        }
    }
    
    public var displayName: String {
        displayName(isMalay: LocalizationManager.shared.isMalay)
    }
    
    public var systemIcon: String {
        switch self {
        case .imsak: return "moon.stars"
        case .fajr: return "sun.horizon"
        case .sunrise: return "sun.max"
        case .dhuhr: return "sun.max.fill"
        case .asr: return "sun.haze.fill"
        case .maghrib: return "sunset.fill"
        case .isha: return "moon.fill"
        }
    }
    
    public var isMainPrayer: BooleanLiteralType {
        switch self {
        case .imsak, .sunrise:
            return false
        default:
            return true
        }
    }
}

// MARK: - Active & Upcoming Prayer Status
public struct PrayerStatus {
    public let currentPrayer: SolatPrayer?
    public let nextPrayer: SolatPrayer?
    public let nextPrayerDate: Date?
    public let timeRemaining: TimeInterval?
    
    public var countdownFormatted: String {
        guard let timeRemaining = timeRemaining, timeRemaining > 0 else {
            return "--:--"
        }
        let hours = Int(timeRemaining) / 3600
        let minutes = (Int(timeRemaining) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
