# Let's Solat (Apple Multiplatform) 🕋

[![Platform](https://img.shields.io/badge/Platform-macOS%20%7C%20iOS%20%7C%20watchOS%20%7C%20CarPlay-blue.svg)](https://github.com/syedn-tech/lets-solat-apple)
[![Swift](https://img.shields.io/badge/Swift-5.10%20%2F%206.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Release](https://img.shields.io/github/v/release/syedn-tech/lets-solat-apple?color=green)](https://github.com/syedn-tech/lets-solat-apple/releases)
[![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)](LICENSE)

A modern, native multiplatform Islamic prayer times application designed for **macOS, iOS, iPadOS, watchOS, and CarPlay**. **Let's Solat** provides highly accurate Malaysian prayer times (*Waktu Solat*) based on official JAKIM zones and worldwide coordinates, with live menu bar countdowns, Adhan notifications, an Islamic Wallpaper Studio, and offline-first reliability.

---

## 📥 Download macOS App

The latest standalone release for macOS is available on GitHub Releases:

### 👉 **[Download Latest macOS Release](https://github.com/syedn-tech/lets-solat-apple/releases/latest)**
### 📦 **[View All Releases & Assets](https://github.com/syedn-tech/lets-solat-apple/releases)**

### Installation on macOS

1. **Download the Installer**:
   Download the latest `.dmg` file from the **[Releases](https://github.com/syedn-tech/lets-solat-apple/releases)** page.

2. **Mount & Drag to Applications**:
   Open the downloaded `.dmg` and drag **Lets Solat.app** into your **Applications** folder (`/Applications`).

   <p align="center">
     <img src="Install%20dmg.png" alt="Install Let's Solat DMG" width="600" />
   </p>

3. **Remove macOS Quarantine Attribute**:
   Because the standalone build is not notarized with an Apple Developer certificate, macOS Gatekeeper may prevent it from opening or report that the file is damaged.

   After dragging the app to the Applications folder, open **Terminal** and run:
   ```bash
   xattr -cr "/Applications/Lets Solat.app"
   ```

4. **Launch the App**:
   Open **Let's Solat** from your **Applications** folder or via Spotlight (`Cmd + Space`).

5. **Grant Initial Permissions**:
   When prompted on initial launch:
   - Allow **Location Services** so the app can automatically detect your JAKIM prayer zone.
   - Allow **Notifications** to receive punctual Adhan audio and prayer alerts.

---

## ✨ Features

- 🖥️ **macOS Menu Bar Resident**:
  - Discreet, sleek menu bar extra (`MenuBarExtra`) showing real-time countdown to the next prayer (e.g. `Asr in 42m`).
  - Interactive popover displaying today's full timetable (Imsak, Subuh, Syuruk, Zohor, Asar, Maghrib, Isyak) with active prayer highlighting and past prayer dimming.
  - Quick refresh, manual zone switcher, and settings access right from the menu bar.

- 📱 **Multiplatform Apple Ecosystem**:
  - **iOS & iPadOS**: Native SwiftUI interface with adaptive layout and modern iOS design principles.
  - **watchOS Companion**: Standalone and synced watch experience with Digital Crown navigation, Smart Stack, and WidgetKit complications.
  - **CarPlay Integration**: In-car dashboard support (`CPTemplateApplicationSceneDelegate` / `CPListTemplate`) displaying upcoming prayer countdown and daily schedule.

- 📍 **Smart Location & Geofencing**:
  - Automatic detection of official Malaysian JAKIM zones based on CoreLocation GPS coordinates (`CLLocationManager`).
  - Seamless zone switching when travelling across states and territories.
  - Full manual zone selection with state-by-state grouping.

- 🔔 **Adhan Alerts & Background Scheduling**:
  - Punctual prayer notifications powered by `UNUserNotificationCenter` with exact calendar triggers.
  - Bundled custom Adhan audio notifications.
  - Proactive background batch scheduling and refresh via `BGAppRefreshTask`.

- 🖼️ **Islamic Wallpaper Studio & Automation**:
  - Curated and procedural Islamic wallpapers with Quranic verses and Hadith quotes in both English and Bahasa Melayu.
  - Real-time preview studio with customizable typography, overlays, and themes.
  - Automatic daily or prayer-based desktop wallpaper rotation via `NSWorkspace.shared.setDesktopImageURL`.

- 🌐 **Offline First & Resilient**:
  - Local caching via App Group `UserDefaults` ensures full functionality even without an active internet connection.
  - Network state monitoring with automatic re-sync when connectivity resumes.

- 🇲🇾 **Bilingual Support**:
  - Full English and Bahasa Melayu localization.

---

## 🤖 AI Agent & Developer Reference

If you are an AI assistant (Antigravity, Cursor, Copilot, Claude) or a developer contributing to this project:
- Read **[`Agents.md`](Agents.md)** for architecture patterns, background task handling, API specifications, and coding standards.
- Check **[`PENDING_ITEMS.md`](PENDING_ITEMS.md)** for roadmap items and pending milestones.

---

## 🛠️ Project Structure

```text
Lets Solat/
├── MyApp.swift                 # App entry point with MenuBarExtra and WindowGroup
├── ContentView.swift           # Main iOS/macOS interface and views
├── MenuBarView.swift           # macOS menu bar popover view
├── PrayerTimeViewModel.swift   # Central reactive view model
├── PrayerModels.swift          # Core models (PrayerTime, Zone, Location, HadithQuote)
├── LocationService.swift       # GPS and JAKIM zone resolution
├── APIClient.swift             # URLSession client for letssolat.syedn.xyz API
├── NotificationService.swift   # UNUserNotificationCenter Adhan scheduling
├── NetworkMonitor.swift        # NWPathMonitor connectivity observer
├── LocalizationManager.swift   # Language switching (English / Bahasa Melayu)
├── AppSettings.swift           # Persistence and user preferences
├── Assets.xcassets             # App icons, menu bar icons, and audio
├── adhan.caf / adhan.aiff      # Bundled Adhan notification audio
└── Agents.md                   # Engineering architecture guide
```

---

## 🚀 Building from Source

### Prerequisites
- macOS 14.0 (Sonoma) or macOS 15.0+ (Sequoia)
- Xcode 16.0 or later
- Swift 5.10 / Swift 6.0

### Build Commands
```bash
# Clone the repository
git clone https://github.com/syedn-tech/lets-solat-apple.git
cd lets-solat-apple

# Build macOS scheme
xcodebuild -scheme MyApp -destination 'platform=macOS' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build

# Build iOS Simulator scheme
xcodebuild -scheme MyApp -destination 'generic/platform=iOS Simulator' CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

---

## 🔗 Links & Resources

- **GitHub Repository**: [https://github.com/syedn-tech/lets-solat-apple](https://github.com/syedn-tech/lets-solat-apple)
- **Latest macOS Download**: [https://github.com/syedn-tech/lets-solat-apple/releases/latest](https://github.com/syedn-tech/lets-solat-apple/releases/latest)
- **Issues & Feedback**: [https://github.com/syedn-tech/lets-solat-apple/issues](https://github.com/syedn-tech/lets-solat-apple/issues)

---

## 📄 License

This project is licensed under the MIT License.
