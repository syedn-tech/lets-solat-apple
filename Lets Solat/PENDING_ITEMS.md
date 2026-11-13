# Let's Solat — Apple Ecosystem Roadmap & Item Tracker

This document tracks all completed, in-progress, and pending work items for the **Let's Solat** Apple multiplatform suite (iOS, iPadOS, macOS, watchOS, CarPlay).

---

## 🚀 Status Legend
- 🟢 **Completed**
- 🟡 **In Progress**
- ⚪ **Pending / Planned**

---

## 1. Phase 1: Foundation & macOS Menu Bar (Completed)

| Task | Status | Notes |
| :--- | :---: | :--- |
| **Doc Polish & Terminology Conversion** | 🟢 | Replaced Android references with iOS/macOS/Apple architecture in `README.md` and `Agents.md`. |
| **Project Tracking Setup** | 🟢 | Created `PENDING_ITEMS.md`. |
| **Core Models (`PrayerTime`, `Location`, `Zone`, etc.)** | 🟢 | Ported models to Swift `Codable` (`PrayerModels.swift`). |
| **Networking & API Client** | 🟢 | Native `URLSession` client with Bearer auth for `letssolat.syedn.xyz` (`APIClient.swift`). |
| **Network Reconnection Polling** | 🟢 | Native `NWPathMonitor` (`NetworkMonitor.swift`) auto-refreshing GPS location & prayer times upon internet restoration. |
| **App Sandbox & Entitlements** | 🟢 | Created `LetsSolat.entitlements` configuring network client and personal location access, plus privacy descriptions. |
| **CoreLocation & Zone Detection** | 🟢 | `CLLocationManager` wrapper to resolve GPS coordinates & current prayer zone (`LocationService.swift`). |
| **Device & App Localization** | 🟢 | `LocalizationManager.swift` with English default, auto device-language detection (Malay/English), and in-app language picker. |
| **Date & Hijri Dual Display** | 🟢 | Displays localized Gregorian date alongside Hijri calendar date in main view & menu bar. |
| **UserNotifications & Adhan Sound** | 🟢 | `UNUserNotificationCenter` exact calendar triggers with custom bundled Adhan audio (`adhan.aiff`), time-sensitive level, and foreground banner delegate. |
| **Local Cache & Storage** | 🟢 | `UserDefaults` / App Group caching for offline readiness (`PrayerTimeStorage.swift`). |
| **macOS Menu Bar Widget (`MenuBarExtra`)** | 🟢 | Resident menu bar extra with custom template icon (`MenuBarIcon`), live countdown, and popover timetable (`MenuBarView.swift`). Added 3 display options: Next Prayer with countdown, Next Prayer time, and Current Prayer. |
| **Prayer Highlighting Preference** | 🟢 | User setting to highlight Next prayer, Current prayer, or Both. |
| **App Icon Integration** | 🟢 | Added macOS and iOS app icon sets (`AppIcon macOS`, `AppIcon iOS`). |
| **macOS & iOS Main View** | 🟢 | Universal SwiftUI application view with prayer timetable, countdown, and manual refresh (`ContentView.swift`). |

---

## 2. Phase 2: iOS & iPadOS App Experience

| Task | Status | Notes |
| :--- | :---: | :--- |
| **iOS / iPadOS Responsive Layout** | ⚪ | Adaptive SwiftUI layout with pill navigation or sidebar on iPad. |
| **Full Prayer Timetable Screen** | ⚪ | Hijri date display, daily and monthly view toggle. |
| **Geofencing & Region Monitoring** | ⚪ | `CLCircularRegion` exit monitoring to trigger background zone updates. |
| **Background Refresh (`BGAppRefreshTask`)** | ⚪ | Periodically fetch prayer times and re-seed notifications. |
| **App Intents & Shortcuts Integration** | ⚪ | Auto-Silent / Focus mode integration via iOS Focus Filters and Shortcuts. |

---

## 3. Phase 3: Islamic Wallpaper Studio & Automation

| Task | Status | Notes |
| :--- | :---: | :--- |
| **Quote Repository & API** | ⚪ | Fetch Quran & Hadith daily/random quotes with bilingual EN/MS support. |
| **Wallpaper Canvas Compositor (CoreGraphics)** | ⚪ | Compose background imagery, gradient overlays, typography, and translations. |
| **macOS Desktop Wallpaper Automation** | ⚪ | Programmatically set macOS desktop via `NSWorkspace.shared.setDesktopImageURL`. |
| **iOS Wallpaper Studio UI & Export** | ⚪ | Live preview screen with save to Photos & Shortcuts automation guide. |

---

## 4. Phase 4: WidgetKit & Complications

| Task | Status | Notes |
| :--- | :---: | :--- |
| **iOS / iPadOS Lock Screen Widgets** | ⚪ | Circular & Rectangular next prayer countdown. |
| **iOS / macOS Home Screen / Notification Center Widgets** | ⚪ | Small, Medium, Large daily timetable widgets with TimelineProvider. |
| **watchOS Smart Stack & Complications** | ⚪ | `accessoryCircular`, `accessoryRectangular`, and `accessoryCorner`. |

---

## 5. Phase 5: Apple Watch App (`watchOS`)

| Task | Status | Notes |
| :--- | :---: | :--- |
| **watchOS SwiftUI App Target** | ⚪ | Digital Crown timeline, current prayer indicator, next prayer countdown. |
| **WatchConnectivity Synchronization** | ⚪ | `WCSession` sync for offline prayer times between iPhone and Apple Watch. |

---

## 6. Phase 6: CarPlay Integration

| Task | Status | Notes |
| :--- | :---: | :--- |
| **CarPlay Scene Delegate & Setup** | ⚪ | `CPTemplateApplicationSceneDelegate` entitlement and scene lifecycle. |
| **CarPlay List Template UI** | ⚪ | `CPListTemplate` displaying prayer countdown, daily timetable, and audio prompts. |
