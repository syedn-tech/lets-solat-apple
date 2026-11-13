import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @ObservedObject var loc = LocalizationManager.shared
    @Environment(\.openURL) private var openURL
    
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif
    
    @State private var isPressingTitle = false
    @State private var showNotificationSentAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 4) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .center, spacing: 6) {
                            Text(loc.string(for: .appTitle))
                                .font(.headline)
                                .foregroundColor(isPressingTitle ? .accentColor : .primary)
                                .scaleEffect(isPressingTitle ? 0.96 : 1.0)
                                .contentShape(Rectangle())
                                .onLongPressGesture(minimumDuration: 0.5, maximumDistance: 50, pressing: { isPressing in
                                    withAnimation(.easeInOut(duration: 0.15)) {
                                        isPressingTitle = isPressing
                                    }
                                }) {
                                    triggerTestNotification()
                                }
                                .contextMenu {
                                    #if os(macOS)
                                    Button {
                                        NotificationService.shared.openSystemNotificationSettings()
                                    } label: {
                                        Label(loc.string(for: .openNotificationSettings), systemImage: "gearshape")
                                    }
                                    #endif
                                }
                                .help(loc.string(for: .holdToTestNotification))
                            
                            if showNotificationSentAlert {
                                HStack(spacing: 3) {
                                    Image(systemName: "bell.badge.fill")
                                    Text(loc.string(for: .testNotificationSent))
                                        .font(.caption2.bold())
                                }
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .cornerRadius(4)
                                .transition(.opacity)
                            }
                        }
                        
                        Text(viewModel.location?.display ?? viewModel.location?.state ?? loc.string(for: .detectingLocation))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        if let hijri = viewModel.todayPrayer?.hijriDate {
                            Text(hijri)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let next = viewModel.nextPrayer {
                    HStack {
                        Text("\(loc.string(for: .nextPrayer)): \(next.displayName)")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(viewModel.countdownString)
                            .font(.system(.subheadline, design: .monospaced).bold())
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)
                    .padding(.top, 4)
                }
            }
            .padding(12)
            
            Divider()
            
            // Daily Prayer Timeline
            VStack(spacing: 6) {
                if !viewModel.displayPrayers.isEmpty {
                    ForEach(viewModel.displayPrayers) { item in
                        if item.id == "tomorrow_imsak" {
                            HStack {
                                Text(loc.string(for: .tomorrowPrayerTimes))
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                if let hijri = viewModel.tomorrowPrayer?.hijriDate {
                                    Text(hijri)
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.top, 4)
                            .padding(.horizontal, 4)
                        }
                        prayerRow(item: item)
                    }
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text(loc.string(for: .noPrayerData))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
            }
            .padding(12)
            
            Divider()
            
            // Footer Quick Actions
            HStack {
                Button {
                    viewModel.requestLocationAndRefresh()
                } label: {
                    Label(loc.string(for: .refresh), systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                // Settings Menu
                Menu {
                    // Short Adhan Section with native Checkmark Toggle
                    Section(loc.string(for: .shortAdhan)) {
                        Toggle(loc.string(for: .playShortAdhan), isOn: $viewModel.isShortAdhanEnabled)
                    }
                    
                    // Menu Bar Display Option
                    Picker(loc.string(for: .menuBarDisplay), selection: $viewModel.menuBarDisplayOption) {
                        ForEach(MenuBarDisplayOption.allCases) { opt in
                            Text(opt.displayName(isMalay: loc.isMalay)).tag(opt)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // Highlight Preference
                    Picker(loc.string(for: .highlightPreference), selection: $viewModel.highlightOption) {
                        ForEach(HighlightOption.allCases) { opt in
                            Text(opt.displayName(isMalay: loc.isMalay)).tag(opt)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // Language
                    Picker("Language / Bahasa", selection: $loc.currentLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    // System Notification Settings
                    #if os(macOS)
                    Section {
                        Button {
                            NotificationService.shared.openSystemNotificationSettings()
                        } label: {
                            Label(loc.string(for: .openNotificationSettings), systemImage: "bell.and.waves.left.and.right")
                        }
                    }
                    #endif
                    
                    // App Version Section
                    Section {
                        Button {
                            openURL(AppSettings.gitHubReleasesURL)
                        } label: {
                            Label(
                                loc.string(for: .versionInfo(version: AppSettings.appVersion, build: AppSettings.buildNumber)),
                                systemImage: "info.circle"
                            )
                        }
                    }
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Spacer()
                
                #if os(macOS)
                Button {
                    openMainWindow()
                } label: {
                    Label(loc.string(for: .openMainWindow), systemImage: "macwindow")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button(loc.string(for: .quit)) {
                    AppDelegate.allowExplicitQuit = true
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.borderless)
                #endif
            }
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            #if os(macOS)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            #else
            .background(Color(.secondarySystemBackground).opacity(0.5))
            #endif
        }
        .frame(width: 320)
        .onAppear {
            #if os(macOS)
            AppDelegate.openWindowAction = { [openWindow] in
                openWindow(id: "main")
            }
            #endif
        }
    }
    
    #if os(macOS)
    private func openMainWindow() {
        AppDelegate.showMainWindow()
    }
    #endif
    
    private func triggerTestNotification() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showNotificationSentAlert = true
        }
        Task {
            await NotificationService.shared.sendTestNotification()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation {
                showNotificationSentAlert = false
            }
        }
    }
    
    private func prayerRow(item: PrayerDisplayItem) -> some View {
        let isCurrent = viewModel.currentPrayer == item.prayer && !item.isTomorrow
        let isNext = viewModel.nextPrayer == item.prayer && (viewModel.isAlreadyIsha ? item.isTomorrow : !item.isTomorrow)
        let prayerDate = item.date
        let timeString = prayerDate?.formatted(date: .omitted, time: .shortened) ?? "--:--"
        
        let highlightNext = (viewModel.highlightOption == .next || viewModel.highlightOption == .both) && isNext
        let highlightCurrent = (viewModel.highlightOption == .current || viewModel.highlightOption == .both) && isCurrent
        let shouldHighlight = highlightNext || highlightCurrent
        let highlightColor: Color = highlightNext ? .accentColor : .green
        
        return HStack {
            Image(systemName: item.prayer.systemIcon)
                .font(.system(size: 13))
                .foregroundColor(shouldHighlight ? highlightColor : .secondary)
                .frame(width: 18)
            
            HStack(spacing: 4) {
                Text(item.prayer.displayName)
                    .font(.system(size: 13, weight: shouldHighlight ? .bold : .regular))
                
                if viewModel.isAlreadyIsha {
                    Text(item.isTomorrow ? "(\(loc.string(for: .tomorrow)))" : "(\(loc.string(for: .today)))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            if highlightNext {
                Text("•")
                    .foregroundColor(.accentColor)
            } else if highlightCurrent {
                Text("•")
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Text(timeString)
                .font(.system(size: 13, weight: shouldHighlight ? .bold : .regular, design: .monospaced))
                .foregroundColor(shouldHighlight ? .primary : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(shouldHighlight ? highlightColor.opacity(0.12) : Color.clear)
        )
    }
}
