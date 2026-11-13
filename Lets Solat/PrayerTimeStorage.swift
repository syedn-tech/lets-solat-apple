import Foundation
import Combine

public final class PrayerTimeStorage {
    public static let shared = PrayerTimeStorage()
    
    private let userDefaults: UserDefaults
    private let cachedDailyKey = "letssolat_cached_daily_prayer"
    private let cachedTomorrowKey = "letssolat_cached_tomorrow_prayer"
    private let cachedLocationKey = "letssolat_cached_location"
    
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    public func saveDailyPrayer(response: PrayerTimeResponse) {
        if let encoded = try? JSONEncoder().encode(response) {
            userDefaults.set(encoded, forKey: cachedDailyKey)
        }
        if let location = response.location, let locEncoded = try? JSONEncoder().encode(location) {
            userDefaults.set(locEncoded, forKey: cachedLocationKey)
        }
    }
    
    public func saveTomorrowPrayer(response: PrayerTimeResponse) {
        if let encoded = try? JSONEncoder().encode(response) {
            userDefaults.set(encoded, forKey: cachedTomorrowKey)
        }
    }
    
    public func getCachedDailyPrayer() -> PrayerTimeResponse? {
        guard let data = userDefaults.data(forKey: cachedDailyKey) else { return nil }
        return try? JSONDecoder().decode(PrayerTimeResponse.self, from: data)
    }
    
    public func getCachedTomorrowPrayer() -> PrayerTimeResponse? {
        guard let data = userDefaults.data(forKey: cachedTomorrowKey) else { return nil }
        return try? JSONDecoder().decode(PrayerTimeResponse.self, from: data)
    }
    
    public func getCachedLocation() -> Location? {
        guard let data = userDefaults.data(forKey: cachedLocationKey) else { return nil }
        return try? JSONDecoder().decode(Location.self, from: data)
    }
}
