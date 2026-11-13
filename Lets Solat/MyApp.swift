import SwiftUI
import UserNotifications

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    static var allowExplicitQuit = false
    static var openWindowAction: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        UNUserNotificationCenter.current().delegate = NotificationService.shared
        Task {
            _ = await NotificationService.shared.requestAuthorization()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if Self.allowExplicitQuit {
            return .terminateNow
        }
        // Instead of terminating the process, close windows and remove from Dock
        Self.hideToMenuBar()
        return .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        Self.showMainWindow()
        return true
    }

    static func hideToMenuBar() {
        for window in NSApplication.shared.windows {
            if !(window is NSPanel) && !(window.className.contains("StatusBar")) {
                window.orderOut(nil)
            }
        }
        // Remove app icon from the macOS Dock
        NSApp.setActivationPolicy(.accessory)
    }

    static func showMainWindow() {
        // Restore app icon to the macOS Dock
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        
        // If the window already exists, bring it to the front
        for window in NSApplication.shared.windows {
            if !(window is NSPanel) && !(window.className.contains("StatusBar")) {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }
                window.makeKeyAndOrderFront(nil)
                window.orderFrontRegardless()
                return
            }
        }
        
        // If no window exists (closed), open it
        openWindowAction?()
    }
}
#endif

@main
struct MyApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    @StateObject private var viewModel = PrayerTimeViewModel()
    
    var body: some Scene {
        // Main App Window (single unique window instance)
        Window("Let's Solat", id: "main") {
            ContentView()
                .environmentObject(viewModel)
        }
        
        #if os(macOS)
        // Menu Bar Extra Widget for macOS
        MenuBarExtra {
            MenuBarView()
                .environmentObject(viewModel)
        } label: {
            HStack(spacing: 6) {
                Image("MenuBarIcon")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text(viewModel.menuBarTitle)
                    .font(.system(.body, design: .rounded))
            }
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
