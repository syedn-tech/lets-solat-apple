import Foundation
import CoreLocation
import Combine

@MainActor
public final class PrayerTimeViewModel: ObservableObject {
    @Published public var todayPrayer: PrayerTimeDayData?
    @Published public var tomorrowPrayer: PrayerTimeDayData?
    @Published public var displayPrayers: [PrayerDisplayItem] = []
    @Published public var location: Location?
    @Published public var currentPrayer: SolatPrayer?
    @Published public var nextPrayer: SolatPrayer?
    @Published public var nextPrayerDate: Date?
    @Published public var countdownString: String = "--:--"
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var lastUpdated: Date?
    
    // User Preferences
    @Published public var highlightOption: HighlightOption {
        didSet {
            UserDefaults.standard.set(highlightOption.rawValue, forKey: AppSettings.highlightOptionKey)
        }
    }
    
    @Published public var menuBarDisplayOption: MenuBarDisplayOption {
        didSet {
            UserDefaults.standard.set(menuBarDisplayOption.rawValue, forKey: AppSettings.menuBarDisplayOptionKey)
        }
    }
    
    @Published public var isShortAdhanEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isShortAdhanEnabled, forKey: AppSettings.shortAdhanKey)
            Task { [weak self] in
                await self?.rescheduleNotifications()
            }
        }
    }
    
    private let apiClient: APIClient
    private let storage: PrayerTimeStorage
    private let locationService: LocationService
    private let notificationService: NotificationService
    private let networkMonitor: NetworkMonitor
    
    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer?
    private var isFetchingTomorrow: Bool = false
    
    public init(
        apiClient: APIClient? = nil,
        storage: PrayerTimeStorage? = nil,
        locationService: LocationService? = nil,
        notificationService: NotificationService? = nil,
        networkMonitor: NetworkMonitor? = nil
    ) {
        self.apiClient = apiClient ?? .shared
        self.storage = storage ?? .shared
        self.locationService = locationService ?? .shared
        self.notificationService = notificationService ?? .shared
        self.networkMonitor = networkMonitor ?? .shared
        
        let savedHighlight = UserDefaults.standard.string(forKey: AppSettings.highlightOptionKey)
        self.highlightOption = savedHighlight.flatMap { HighlightOption(rawValue: $0) } ?? .next
        
        let savedMenuBar = UserDefaults.standard.string(forKey: AppSettings.menuBarDisplayOptionKey)
        self.menuBarDisplayOption = savedMenuBar.flatMap { MenuBarDisplayOption(rawValue: $0) } ?? .nextPrayerWithCountdown
        
        self.isShortAdhanEnabled = UserDefaults.standard.bool(forKey: AppSettings.shortAdhanKey)
        
        loadFromCache()
        setupLocationObserver()
        setupNetworkObserver()
        startTimer()
        
        // Automatically request GPS location on launch
        requestLocationAndRefresh()
    }
    
    deinit {
        countdownTimer?.invalidate()
    }
    
    private func loadFromCache() {
        if let cached = storage.getCachedDailyPrayer() {
            self.todayPrayer = cached.data?.first
            self.location = cached.location
        }
        if let cachedTomorrow = storage.getCachedTomorrowPrayer() {
            self.tomorrowPrayer = cachedTomorrow.data?.first
        }
        self.updatePrayerStatus()
    }
    
    private func setupLocationObserver() {
        locationService.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] loc in
                Task { [weak self] in
                    await self?.fetchPrayerTimes(for: loc.coordinate)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNetworkObserver() {
        // When network transitions to connected, refresh latest location and prayer times
        networkMonitor.$isConnected
            .removeDuplicates()
            .dropFirst() // ignore initial state
            .filter { $0 == true }
            .sink { [weak self] _ in
                print("[NetworkMonitor] Internet reconnected. Fetching latest location & prayer times...")
                self?.requestLocationAndRefresh()
            }
            .store(in: &cancellables)
    }
    
    public func requestLocationAndRefresh() {
        locationService.requestAuthorization()
        locationService.requestCurrentLocation()
    }
    
    public var isAlreadyIsha: Bool {
        guard let dayData = todayPrayer,
              let ishaDate = dayData.dateForPrayer(SolatPrayer.isha.rawValue) else {
            return false
        }
        return Date() >= ishaDate
    }
    
    public func fetchPrayerTimes(for coordinate: CLLocationCoordinate2D? = nil) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: PrayerTimeResponse
            if let coord = coordinate {
                response = try await apiClient.fetchDailyPrayerTimes(latitude: coord.latitude, longitude: coord.longitude)
            } else if let loc = locationService.currentLocation?.coordinate {
                response = try await apiClient.fetchDailyPrayerTimes(latitude: loc.latitude, longitude: loc.longitude)
            } else if let cachedZone = location?.zone {
                response = try await apiClient.fetchDailyPrayerTimes(zone: cachedZone)
            } else {
                // Fallback to Kuala Lumpur default zone
                response = try await apiClient.fetchDailyPrayerTimes(zone: "WLY01")
            }
            
            self.todayPrayer = response.data?.first
            self.location = response.location
            self.lastUpdated = Date()
            self.storage.saveDailyPrayer(response: response)
            
            // When already isha, load next day prayer time
            if self.isAlreadyIsha {
                await fetchTomorrowPrayerTimes(for: coordinate)
            }
            
            self.updatePrayerStatus()
            await rescheduleNotifications()
        } catch {
            self.errorMessage = error.localizedDescription
            print("Failed to fetch prayer times: \(error)")
        }
        
        isLoading = false
    }
    
    public func fetchTomorrowPrayerTimes(for coordinate: CLLocationCoordinate2D? = nil) async {
        guard !isFetchingTomorrow else { return }
        guard let today = todayPrayer, let tomorrowDateStr = getTomorrowDateString(from: today.date) else { return }
        
        isFetchingTomorrow = true
        defer { isFetchingTomorrow = false }
        
        do {
            let response: PrayerTimeResponse
            if let coord = coordinate {
                response = try await apiClient.fetchDailyPrayerTimes(latitude: coord.latitude, longitude: coord.longitude, date: tomorrowDateStr)
            } else if let loc = locationService.currentLocation?.coordinate {
                response = try await apiClient.fetchDailyPrayerTimes(latitude: loc.latitude, longitude: loc.longitude, date: tomorrowDateStr)
            } else if let cachedZone = location?.zone {
                response = try await apiClient.fetchDailyPrayerTimes(zone: cachedZone, date: tomorrowDateStr)
            } else {
                response = try await apiClient.fetchDailyPrayerTimes(zone: "WLY01", date: tomorrowDateStr)
            }
            
            self.tomorrowPrayer = response.data?.first
            self.storage.saveTomorrowPrayer(response: response)
            self.updatePrayerStatus()
            await rescheduleNotifications()
        } catch {
            print("Failed to fetch tomorrow's prayer times: \(error)")
        }
    }
    
    private func getTomorrowDateString(from todayDateString: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        if let date = formatter.date(from: todayDateString),
           let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: date) {
            return formatter.string(from: tomorrow)
        }
        if let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) {
            return formatter.string(from: tomorrow)
        }
        return nil
    }
    
    public func rescheduleNotifications() async {
        guard let dayData = self.todayPrayer else { return }
        let locDisplay = location?.display ?? location?.state ?? LocalizationManager.shared.string(for: .yourLocation)
        await notificationService.schedulePrayerNotifications(
            for: dayData,
            tomorrowData: self.tomorrowPrayer,
            locationName: locDisplay
        )
    }
    
    private func startTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updatePrayerStatus()
            }
        }
    }
    
    public func updatePrayerStatus() {
        guard let dayData = todayPrayer, let times = dayData.prayerTimes else {
            countdownString = "--:--"
            updateDisplayPrayers()
            return
        }
        
        let now = Date()
        var current: SolatPrayer? = nil
        var next: SolatPrayer? = nil
        var nextDate: Date? = nil
        
        for prayer in SolatPrayer.allCases {
            guard let ms = times[prayer.rawValue] else { continue }
            let pDate = Date(timeIntervalSince1970: ms / 1000.0)
            
            if pDate <= now {
                current = prayer
            } else if next == nil {
                next = prayer
                nextDate = pDate
            }
        }
        
        // When already Isha: next prayer is tomorrow's first prayer (Imsak / Fajr)
        if current == .isha && next == nil {
            if let tomTimes = tomorrowPrayer?.prayerTimes {
                for prayer in SolatPrayer.allCases {
                    guard let ms = tomTimes[prayer.rawValue] else { continue }
                    let pDate = Date(timeIntervalSince1970: ms / 1000.0)
                    if pDate > now {
                        next = prayer
                        nextDate = pDate
                        break
                    }
                }
            } else if !isFetchingTomorrow {
                // Asynchronously fetch tomorrow's prayer times
                Task { [weak self] in
                    await self?.fetchTomorrowPrayerTimes()
                }
            }
        }
        
        self.currentPrayer = current
        self.nextPrayer = next
        self.nextPrayerDate = nextDate
        
        if let nextDate = nextDate {
            let diff = max(0, nextDate.timeIntervalSince(now))
            let hours = Int(diff) / 3600
            let minutes = (Int(diff) % 3600) / 60
            let seconds = Int(diff) % 60
            if hours > 0 {
                countdownString = String(format: "%dh %02dm", hours, minutes)
            } else {
                countdownString = String(format: "%02dm %02ds", minutes, seconds)
            }
        } else {
            countdownString = LocalizationManager.shared.string(for: .completed)
        }
        
        updateDisplayPrayers()
    }
    
    private func updateDisplayPrayers() {
        guard let today = todayPrayer else {
            self.displayPrayers = []
            return
        }
        
        if isAlreadyIsha, let tomorrow = tomorrowPrayer {
            var items: [PrayerDisplayItem] = []
            
            // First row: keep today's Isha
            items.append(PrayerDisplayItem(
                id: "today_isha",
                prayer: .isha,
                date: today.dateForPrayer(SolatPrayer.isha.rawValue),
                dayData: today,
                isTomorrow: false
            ))
            
            // Subsequent rows: next day's prayer times
            for prayer in SolatPrayer.allCases {
                items.append(PrayerDisplayItem(
                    id: "tomorrow_\(prayer.rawValue)",
                    prayer: prayer,
                    date: tomorrow.dateForPrayer(prayer.rawValue),
                    dayData: tomorrow,
                    isTomorrow: true
                ))
            }
            self.displayPrayers = items
        } else {
            var items: [PrayerDisplayItem] = []
            for prayer in SolatPrayer.allCases {
                items.append(PrayerDisplayItem(
                    id: "today_\(prayer.rawValue)",
                    prayer: prayer,
                    date: today.dateForPrayer(prayer.rawValue),
                    dayData: today,
                    isTomorrow: false
                ))
            }
            self.displayPrayers = items
        }
    }
    
    public var menuBarTitle: String {
        let isMalay = LocalizationManager.shared.isMalay
        
        switch menuBarDisplayOption {
        case .nextPrayerWithCountdown:
            if let next = nextPrayer {
                return isMalay ? "\(next.displayName) dalam \(countdownString)" : "\(next.displayName) in \(countdownString)"
            } else if let current = currentPrayer {
                return "\(current.displayName)"
            } else {
                return LocalizationManager.shared.string(for: .appTitle)
            }
            
        case .nextPrayerTime:
            if let next = nextPrayer, let date = nextPrayerDate {
                let timeStr = date.formatted(date: .omitted, time: .shortened)
                let prefix = isMalay ? "Seterusnya: " : "Next: "
                return "\(prefix)\(next.displayName) \(timeStr)"
            } else if let current = currentPrayer {
                return "\(current.displayName)"
            } else {
                return LocalizationManager.shared.string(for: .appTitle)
            }
            
        case .currentPrayer:
            if let current = currentPrayer,
               let date = todayPrayer?.dateForPrayer(current.rawValue) {
                let timeStr = date.formatted(date: .omitted, time: .shortened)
                return "\(current.displayName) \(timeStr)"
            } else if let current = currentPrayer {
                return "\(current.displayName)"
            } else if let next = nextPrayer {
                return "\(next.displayName)"
            } else {
                return LocalizationManager.shared.string(for: .appTitle)
            }
        }
    }
}
