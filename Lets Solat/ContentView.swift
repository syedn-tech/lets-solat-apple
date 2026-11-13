import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: PrayerTimeViewModel
    @ObservedObject var loc = LocalizationManager.shared
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Banner
                headerView
                
                Divider()
                
                // Prayer List
                ScrollView {
                    VStack(spacing: 12) {
                        if !viewModel.displayPrayers.isEmpty {
                            ForEach(viewModel.displayPrayers) { item in
                                if item.id == "tomorrow_imsak" {
                                    HStack {
                                        Text(loc.string(for: .tomorrowPrayerTimes))
                                            .font(.caption2.bold())
                                            .foregroundColor(.secondary)
                                        Spacer()
                                        if let tomorrowHijri = viewModel.tomorrowPrayer?.hijriDate {
                                            Text(tomorrowHijri)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding(.top, 6)
                                    .padding(.horizontal, 4)
                                }
                                prayerRow(item: item)
                            }
                        } else if viewModel.isLoading {
                            ProgressView(loc.string(for: .loading))
                                .padding(.top, 40)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 36))
                                    .foregroundColor(.orange)
                                Text(loc.string(for: .noPrayerData))
                                    .font(.headline)
                                Button(loc.string(for: .reload)) {
                                    viewModel.requestLocationAndRefresh()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding(.top, 40)
                        }
                    }
                    .padding()
                }
            }
            .frame(minWidth: 380, idealWidth: 420, minHeight: 520, idealHeight: 580)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        // Short Adhan Section with native Checkmark Toggle
                        Section(loc.string(for: .shortAdhan)) {
                            Toggle(loc.string(for: .playShortAdhan), isOn: $viewModel.isShortAdhanEnabled)
                        }
                        
                        // Menu Bar Display Option Section
                        #if os(macOS)
                        Picker(loc.string(for: .menuBarDisplay), selection: $viewModel.menuBarDisplayOption) {
                            ForEach(MenuBarDisplayOption.allCases) { opt in
                                Text(opt.shortLabel(isMalay: loc.isMalay)).tag(opt)
                            }
                        }
                        .pickerStyle(.inline)
                        #endif
                        
                        // Highlight Preference Section
                        Picker(loc.string(for: .highlightPreference), selection: $viewModel.highlightOption) {
                            ForEach(HighlightOption.allCases) { opt in
                                Text(opt.displayName(isMalay: loc.isMalay)).tag(opt)
                            }
                        }
                        .pickerStyle(.inline)
                        
                        // Language Section
                        Picker("Language / Bahasa", selection: $loc.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.inline)
                    } label: {
                        Label(loc.string(for: .settings), systemImage: "gearshape")
                    }
                }
                ToolbarItem(placement: .automatic) {
                    Button {
                        viewModel.requestLocationAndRefresh()
                    } label: {
                        Label(loc.string(for: .refreshLocation), systemImage: "arrow.clockwise")
                    }
                }
            }
            .task {
                viewModel.requestLocationAndRefresh()
            }
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.subheadline)
                            .foregroundColor(.accentColor)
                        Text(viewModel.location?.display ?? viewModel.location?.state ?? loc.string(for: .detectingLocation))
                            .font(.headline)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 6) {
                        Text(Date().formatted(date: .complete, time: .omitted))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let hijri = viewModel.todayPrayer?.hijriDate {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(hijri)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                Spacer()
                
                // Next Prayer Countdown Pill
                if let next = viewModel.nextPrayer {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(loc.string(for: .nextPrayer))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(next.displayName) (\(viewModel.countdownString))")
                            .font(.callout.bold())
                            .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(8)
                }
            }
            
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "wifi.exclamationmark")
                    Text(error)
                        .font(.caption)
                }
                .foregroundColor(.red)
                .padding(.top, 2)
            }
        }
        .padding()
        #if os(macOS)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
        #else
        .background(Color(.systemBackground).opacity(0.8))
        #endif
    }
    
    // MARK: - Prayer Row
    private func prayerRow(item: PrayerDisplayItem) -> some View {
        let isCurrent = viewModel.currentPrayer == item.prayer && !item.isTomorrow
        let isNext = viewModel.nextPrayer == item.prayer && (viewModel.isAlreadyIsha ? item.isTomorrow : !item.isTomorrow)
        let prayerDate = item.date
        let timeString = prayerDate?.formatted(date: .omitted, time: .shortened) ?? "--:--"
        
        // Highlight decisions based on user preference
        let highlightNext = (viewModel.highlightOption == .next || viewModel.highlightOption == .both) && isNext
        let highlightCurrent = (viewModel.highlightOption == .current || viewModel.highlightOption == .both) && isCurrent
        
        let shouldHighlight = highlightNext || highlightCurrent
        let highlightColor: Color = highlightNext ? .accentColor : .green
        
        return HStack(spacing: 14) {
            Image(systemName: item.prayer.systemIcon)
                .font(.system(size: 20))
                .foregroundColor(shouldHighlight ? highlightColor : .secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.prayer.displayName)
                        .font(.body.weight(shouldHighlight ? .semibold : .regular))
                    
                    if viewModel.isAlreadyIsha {
                        Text(item.isTomorrow ? "(\(loc.string(for: .tomorrow)))" : "(\(loc.string(for: .today)))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if isNext {
                    Text(loc.string(for: .inTime(viewModel.countdownString)))
                        .font(.caption2)
                        .foregroundColor(highlightNext ? .accentColor : .secondary)
                } else if isCurrent {
                    Text(loc.string(for: .nowOngoing))
                        .font(.caption2)
                        .foregroundColor(highlightCurrent ? .green : .secondary)
                }
            }
            
            Spacer()
            
            Text(timeString)
                .font(.system(.body, design: .monospaced).weight(shouldHighlight ? .bold : .medium))
                .foregroundColor(shouldHighlight ? .primary : .secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(shouldHighlight ? highlightColor.opacity(0.12) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(shouldHighlight ? highlightColor.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(PrayerTimeViewModel())
}
