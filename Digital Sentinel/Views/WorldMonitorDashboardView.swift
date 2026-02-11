//
//  WorldMonitorDashboardView.swift
//  Digital Sentinel
//
//  World Monitor-inspired dashboard layout for iOS
//

import SwiftUI

struct WorldMonitorDashboardView: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    let isCompact: Bool

    @State private var showLeftPanel = true
    @State private var showRightPanel = true

    var body: some View {
        VStack(spacing: 0) {
            WorldMonitorHeaderView(
                statistics: dataManager.statistics,
                isCompact: isCompact,
                pizzIntStatus: dataManager.pizzIntStatus,
                pizzIntTensions: dataManager.pizzIntTensions,
                pizzIntState: dataManager.pizzIntState,
                onPizzIntTap: { dataManager.refreshPizzInt() }
            )

            if isCompact {
                WorldMonitorPhoneBody(
                    dataManager: dataManager,
                    selectedConflict: $selectedConflict
                )
            } else {
                HStack(spacing: 0) {
                    if showLeftPanel {
                        WorldMonitorFeedPanel(
                            dataManager: dataManager,
                            selectedConflict: $selectedConflict
                        )
                        .transition(.move(edge: .leading))
                    }

                    WorldMonitorMapPane(
                        dataManager: dataManager,
                        selectedConflict: $selectedConflict,
                        showLeftPanel: $showLeftPanel,
                        showRightPanel: $showRightPanel
                    )

                    if showRightPanel {
                        WorldMonitorIntelPanel(
                            dataManager: dataManager,
                            selectedConflict: selectedConflict
                        )
                        .transition(.move(edge: .trailing))
                    }
                }
            }

            WorldMonitorTickerView(items: dataManager.conflicts, isCompact: isCompact)
        }
    }
}

// MARK: - Header
struct WorldMonitorHeaderView: View {
    let statistics: GlobalStatistics
    let isCompact: Bool
    let pizzIntStatus: PizzIntStatus?
    let pizzIntTensions: [GdeltTensionPair]
    let pizzIntState: PizzIntLoadState
    let onPizzIntTap: () -> Void
    @State private var isBlinking = false
    @State private var showPizzInt = false

    var body: some View {
        Group {
            if isCompact {
                VStack(spacing: 6) {
                    headerTitleRow

                    HStack(spacing: 6) {
                        PizzIntIndicatorButton(status: pizzIntStatus, state: pizzIntState) {
                            onPizzIntTap()
                            showPizzInt = true
                        }
                        StatChip(value: "\(statistics.activeConflicts)", label: "ACTIVE")
                        StatChip(value: "\(statistics.criticalCount)", label: "CRITICAL", color: MatrixColors.critical)
                        StatChip(value: "\(statistics.escalatingCount)", label: "ESCALATING", color: MatrixColors.high)
                    }

                    headerClock
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } else {
                HStack(spacing: 12) {
                    headerTitleRow

                    Spacer()

                    HStack(spacing: 14) {
                        PizzIntIndicatorButton(status: pizzIntStatus, state: pizzIntState) {
                            onPizzIntTap()
                            showPizzInt = true
                        }
                        StatChip(value: "\(statistics.activeConflicts)", label: "ACTIVE")
                        StatChip(value: "\(statistics.criticalCount)", label: "CRITICAL", color: MatrixColors.critical)
                        StatChip(value: "\(statistics.escalatingCount)", label: "ESCALATING", color: MatrixColors.high)
                    }

                    headerClock
                }
            }
        }
        .padding(.horizontal, isCompact ? 10 : 16)
        .padding(.vertical, isCompact ? 8 : 10)
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(height: 1),
            alignment: .bottom
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isBlinking = true
            }
        }
        .sheet(isPresented: $showPizzInt) {
            PizzIntDetailView(
                status: pizzIntStatus,
                tensions: pizzIntTensions,
                state: pizzIntState,
                onRefresh: onPizzIntTap
            )
        }
    }

    private var headerTitleRow: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(MatrixColors.matrixGreen.opacity(0.4), lineWidth: 1)
                    .frame(width: isCompact ? 18 : 22, height: isCompact ? 18 : 22)

                Circle()
                    .fill(MatrixColors.matrixGreen.opacity(isBlinking ? 0.9 : 0.3))
                    .frame(width: isCompact ? 6 : 8, height: isCompact ? 6 : 8)
            }

            VStack(alignment: .leading, spacing: 2) {
                GlitchText(text: "DIGITAL SENTINEL", font: .nasalization(size: isCompact ? 10 : 12))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text("WORLD MONITOR DASHBOARD")
                    .font(.nasalization(size: isCompact ? 7 : 8))
                    .foregroundColor(MatrixColors.textDim)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private var headerClock: some View {
        SwiftUI.TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(timeString(for: context.date))
                .font(.nasalization(size: isCompact ? 8 : 9))
                .foregroundColor(MatrixColors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(MatrixColors.cardBackground.opacity(0.8))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(MatrixColors.borderGreen.opacity(0.4), lineWidth: 1)
                )
        }
    }

    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss zzz"
        return formatter.string(from: date)
    }
}

struct StatChip: View {
    let value: String
    let label: String
    var color: Color = MatrixColors.matrixGreen

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.nasalization(size: 11))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.nasalization(size: 6))
                .foregroundColor(MatrixColors.textDim)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(color.opacity(0.08))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(color.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - PizzINT Indicator
struct PizzIntIndicatorButton: View {
    let status: PizzIntStatus?
    let state: PizzIntLoadState
    let onTap: () -> Void

    private var defconText: String {
        guard let status else { return "DEFCON -" }
        return "DEFCON \(status.defconLevel)"
    }

    private var scoreText: String {
        switch state {
        case .loading:
            return "--%"
        case .failed:
            return "ERR"
        case .idle:
            return status.map { "\($0.aggregateActivity)%" } ?? "--%"
        }
    }

    private var defconColor: Color {
        guard let status else { return MatrixColors.textDim }
        switch status.defconLevel {
        case 1: return Color(red: 1.0, green: 0.0, blue: 0.25)
        case 2: return Color(red: 1.0, green: 0.27, blue: 0.0)
        case 3: return Color(red: 1.0, green: 0.67, blue: 0.0)
        case 4: return Color(red: 0.0, green: 0.67, blue: 1.0)
        default: return Color(red: 0.18, green: 0.54, blue: 0.43)
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text("🍕")
                    .font(.system(size: 12))
                Text(defconText)
                    .font(.nasalization(size: 8))
                    .foregroundColor((status?.defconLevel ?? 5) <= 3 ? .black : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(defconColor)
                    .cornerRadius(3)
                Text(scoreText)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(MatrixColors.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(MatrixColors.borderGreen.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct PizzIntDetailView: View {
    let status: PizzIntStatus?
    let tensions: [GdeltTensionPair]
    let state: PizzIntLoadState
    let onRefresh: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    statusBar

                    locationsSection

                    tensionsSection

                    footer
                }
                .padding(16)
            }
            .background(MatrixColors.darkBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") { onRefresh() }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Pentagon Pizza Index")
                .font(.nasalization(size: 14))
                .foregroundColor(MatrixColors.textPrimary)
            Spacer()
            if case .loading = state {
                ProgressView()
            }
        }
    }

    private var statusBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let status {
                Text(status.defconLabel)
                    .font(.nasalization(size: 10))
                    .foregroundColor(defconColor(for: status.defconLevel))
            } else if case .failed(let message) = state {
                Text(message)
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.high)
            } else {
                Text("Loading PizzINT data...")
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(MatrixColors.cardBackground.opacity(0.6))
        .cornerRadius(8)
    }

    private var locationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Locations")
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.textDim)

            if let status {
                ForEach(status.locations.prefix(12)) { loc in
                    HStack {
                        Text(loc.name)
                            .font(.nasalization(size: 9))
                            .foregroundColor(MatrixColors.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        let label = locationStatusLabel(loc)
                        Text(label.text)
                            .font(.nasalization(size: 8))
                            .foregroundColor(label.textColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(label.bgColor)
                            .cornerRadius(4)
                    }
                    Divider().background(MatrixColors.borderGreen.opacity(0.2))
                }
            } else {
                Text("No location data.")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
    }

    private var tensionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Geopolitical Tensions")
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.textDim)

            ForEach(tensions) { tension in
                HStack {
                    Text(tension.label)
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textPrimary)
                    Spacer()
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f", tension.score))
                            .font(.nasalization(size: 9))
                            .foregroundColor(MatrixColors.textPrimary)
                        Text(trendText(tension))
                            .font(.nasalization(size: 8))
                            .foregroundColor(trendColor(tension.trend))
                    }
                }
            }
        }
    }

    private var footer: some View {
        HStack {
            Text("Source: PizzINT")
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)
            Spacer()
            if let status {
                Text("Updated \(relativeTime(from: status.lastUpdate))")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
    }

    private func defconColor(for level: Int) -> Color {
        switch level {
        case 1: return Color(red: 1.0, green: 0.0, blue: 0.25)
        case 2: return Color(red: 1.0, green: 0.27, blue: 0.0)
        case 3: return Color(red: 1.0, green: 0.67, blue: 0.0)
        case 4: return Color(red: 0.0, green: 0.67, blue: 1.0)
        default: return Color(red: 0.18, green: 0.54, blue: 0.43)
        }
    }

    private func locationStatusLabel(_ loc: PizzIntLocation) -> (text: String, bgColor: Color, textColor: Color) {
        if loc.isClosedNow { return ("CLOSED", Color(white: 0.2), Color(white: 0.7)) }
        if loc.isSpike { return ("SPIKE \(loc.currentPopularity)%", MatrixColors.critical, .white) }
        if loc.currentPopularity >= 70 { return ("HIGH \(loc.currentPopularity)%", MatrixColors.high, .white) }
        if loc.currentPopularity >= 40 { return ("ELEVATED \(loc.currentPopularity)%", Color(red: 1.0, green: 0.67, blue: 0.0), .black) }
        if loc.currentPopularity >= 15 { return ("NOMINAL \(loc.currentPopularity)%", MatrixColors.matrixCyan, .white) }
        return ("QUIET \(loc.currentPopularity)%", MatrixColors.matrixGreen, .black)
    }

    private func trendText(_ tension: GdeltTensionPair) -> String {
        let symbol: String
        switch tension.trend {
        case "rising": symbol = "↑"
        case "falling": symbol = "↓"
        default: symbol = "→"
        }
        let change = tension.changePercent > 0 ? "+\(tension.changePercent)%" : "\(tension.changePercent)%"
        return "\(symbol) \(change)"
    }

    private func trendColor(_ trend: String) -> Color {
        switch trend {
        case "rising": return MatrixColors.high
        case "falling": return MatrixColors.matrixGreen
        default: return MatrixColors.textDim
        }
    }

    private func relativeTime(from date: Date) -> String {
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "just now" }
        if diff < 3600 { return "\(Int(diff / 60))m ago" }
        return "\(Int(diff / 3600))h ago"
    }
}

// MARK: - Phone Body
struct WorldMonitorPhoneBody: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?

    var body: some View {
        WorldMapView(dataManager: dataManager, selectedConflict: $selectedConflict, bottomInset: 300)
            .ignoresSafeArea(edges: .bottom)
            .safeAreaInset(edge: .bottom) {
                WorldMonitorFeedSheet(
                    dataManager: dataManager,
                    selectedConflict: $selectedConflict
                )
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(MatrixColors.panelBackground.opacity(0.98))
                .overlay(
                    Rectangle()
                        .fill(MatrixColors.borderGreen.opacity(0.3))
                        .frame(height: 1),
                    alignment: .top
                )
            }
    }
}

// MARK: - Map Pane
struct WorldMonitorMapPane: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @Binding var showLeftPanel: Bool
    @Binding var showRightPanel: Bool

    var body: some View {
        ZStack {
            WorldMapView(dataManager: dataManager, selectedConflict: $selectedConflict, bottomInset: 0)

            VStack {
                HStack(spacing: 10) {
                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showLeftPanel.toggle() } }) {
                        Image(systemName: showLeftPanel ? "sidebar.left" : "sidebar.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MatrixColors.matrixGreen)
                            .padding(8)
                            .background(MatrixColors.cardBackground.opacity(0.9))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MatrixColors.borderGreen.opacity(0.5), lineWidth: 1)
                            )
                    }

                    Button(action: { withAnimation(.easeInOut(duration: 0.25)) { showRightPanel.toggle() } }) {
                        Image(systemName: showRightPanel ? "sidebar.right" : "sidebar.left")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(MatrixColors.matrixCyan)
                            .padding(8)
                            .background(MatrixColors.cardBackground.opacity(0.9))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(MatrixColors.matrixCyan.opacity(0.5), lineWidth: 1)
                            )
                    }

                    Spacer()
                }
                .padding(12)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Left Panel
enum FeedMode: String, CaseIterable {
    case news = "NEWS"
    case conflicts = "CONFLICTS"
}

struct FeedModeToggle: View {
    @Binding var mode: FeedMode

    var body: some View {
        HStack(spacing: 0) {
            ForEach(FeedMode.allCases, id: \.self) { item in
                Button(action: { mode = item }) {
                    Text(item.rawValue)
                        .font(.nasalization(size: 8))
                        .foregroundColor(mode == item ? MatrixColors.matrixGreen : MatrixColors.textDim)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            mode == item ? MatrixColors.matrixGreen.opacity(0.12) : Color.clear
                        )
                }
            }
        }
        .background(MatrixColors.cardBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

struct WorldMonitorFeedPanel: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @State private var feedMode: FeedMode = .news

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("LIVE FEEDS")
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.matrixGreen)
                Spacer()
                Button(action: { dataManager.refreshNews() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MatrixColors.matrixGreen)
                        .padding(6)
                        .background(MatrixColors.cardBackground)
                        .cornerRadius(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(MatrixColors.borderGreen.opacity(0.4), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(MatrixColors.cardBackground.opacity(0.5))

            FeedModeToggle(mode: $feedMode)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            if feedMode == .news {
                LiveNewsPanelView(dataManager: dataManager)
            } else {
                SearchFilterSection(
                    searchText: $dataManager.searchText,
                    selectedFilter: $dataManager.selectedFilter
                )
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(dataManager.filteredConflicts) { conflict in
                            ConflictListItem(
                                conflict: conflict,
                                isSelected: selectedConflict?.id == conflict.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedConflict?.id == conflict.id {
                                        selectedConflict = nil
                                    } else {
                                        selectedConflict = conflict
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
            }

            Spacer()

            WorldMonitorPanelFooter()
        }
        .frame(width: 300)
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

struct LiveNewsPanelView: View {
    @ObservedObject var dataManager: ConflictDataManager
    @State private var selectedLink: BrowserLink?

    var body: some View {
        VStack(spacing: 8) {
            NewsStatusView(status: dataManager.newsStatus, lastUpdated: dataManager.lastNewsUpdate)
                .padding(.horizontal, 10)

            if dataManager.newsItems.isEmpty {
                Text("No headlines received yet.")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
                    .padding(.vertical, 16)
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(dataManager.newsItems.prefix(40)) { item in
                            NewsItemRow(item: item) { url in
                                selectedLink = BrowserLink(url: url)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(item: $selectedLink) { link in
            SafariView(url: link.url)
        }
    }
}

struct BrowserLink: Identifiable {
    let id = UUID()
    let url: URL
}

struct NewsStatusView: View {
    let status: NewsStatus
    let lastUpdated: Date?

    var body: some View {
        HStack(spacing: 8) {
            switch status {
            case .loading:
                ProgressView()
                    .scaleEffect(0.8)
                Text("Updating feeds...")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            case .failed(let message):
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(MatrixColors.high)
                Text(message)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.high)
            case .idle:
                Image(systemName: "dot.radiowaves.left.and.right")
                    .font(.system(size: 10))
                    .foregroundColor(MatrixColors.matrixGreen)
                Text("Live feeds online")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.matrixGreen)
            }

            Spacer()

            if let lastUpdated = lastUpdated {
                Text("Updated \(relativeTime(from: lastUpdated))")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(MatrixColors.cardBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NewsItemRow: View {
    let item: NewsItem
    let onOpen: (URL) -> Void

    var body: some View {
        Button {
            if let url = item.link {
                onOpen(url)
            }
        } label: {
            rowContent
        }
        .buttonStyle(.plain)
        .disabled(item.link == nil)
    }

    private var rowContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(MatrixColors.matrixGreen)
                    .frame(width: 6, height: 6)
                    .shadow(color: MatrixColors.matrixGreen.opacity(0.6), radius: 4)

                Text(item.source.uppercased())
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)

                Spacer()

                if let publishedAt = item.publishedAt {
                    Text(relativeTime(from: publishedAt))
                        .font(.nasalization(size: 7))
                        .foregroundColor(MatrixColors.textDim)
                }
            }

            Text(item.title)
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.textPrimary)
                .lineLimit(2)

            if let summary = item.summary, !summary.isEmpty {
                Text(summary)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(10)
        .background(MatrixColors.cardBackground.opacity(0.8))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }

    private func relativeTime(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct WorldMonitorPanelFooter: View {
    var body: some View {
        VStack(spacing: 6) {
            Divider()
                .background(MatrixColors.borderGreen.opacity(0.3))

            HStack {
                Text("DATA FOR DEMO PURPOSES")
                    .font(.nasalization(size: 6))
                    .foregroundColor(MatrixColors.textDim)
                Spacer()
                Text("SIG: OK")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.matrixGreen)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Right Panel
struct WorldMonitorIntelPanel: View {
    @ObservedObject var dataManager: ConflictDataManager
    let selectedConflict: MajorConflict?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("INTELLIGENCE")
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.matrixCyan)
                Spacer()
                Text("LIVE DATA")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(MatrixColors.cardBackground.opacity(0.5))

            ScrollView {
                VStack(spacing: 12) {
                    WorldBriefCard(
                        newsItems: dataManager.newsItems,
                        status: dataManager.newsStatus,
                        lastUpdated: dataManager.lastNewsUpdate
                    )
                    SignalSnapshotCard(statistics: dataManager.statistics)
                    FocusConflictCard(conflict: selectedConflict ?? dataManager.conflicts.first)
                }
                .padding(12)
            }

            WorldMonitorPanelFooter()
        }
        .frame(width: 300)
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(width: 1),
            alignment: .leading
        )
    }
}

struct WorldBriefCard: View {
    let newsItems: [NewsItem]
    let status: NewsStatus
    let lastUpdated: Date?

    private var topHeadlines: [NewsItem] {
        Array(newsItems.prefix(3))
    }

    private var sourceLine: String {
        let sourceNames = Set(newsItems.prefix(10).map { $0.source })
        let list = sourceNames.isEmpty ? NewsFeedService.sources.map { $0.name } : Array(sourceNames)
        return list.sorted().joined(separator: ", ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "dot.radiowaves.left.and.right")
                    .foregroundColor(MatrixColors.matrixGreen)
                    .font(.system(size: 12))
                Text("WORLD BRIEF")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.matrixGreen)
                Spacer()
                StatusChip(status: status)
            }

            if case .failed(let message) = status {
                Text(message)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.high)
            } else if topHeadlines.isEmpty {
                Text("Awaiting live headline data. Pulling from trusted sources.")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(topHeadlines) { item in
                        Text("• \(item.title)")
                            .font(.nasalization(size: 8))
                            .foregroundColor(MatrixColors.textSecondary)
                            .lineLimit(2)
                    }
                }
            }

            if !sourceLine.isEmpty {
                Text("Sources: \(sourceLine)")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)
                    .lineLimit(2)
            }

            if let lastUpdated = lastUpdated {
                Text("Updated \(formattedTime(lastUpdated))")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
        .padding(10)
        .matrixCard(borderColor: MatrixColors.borderGreen)
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss zzz"
        return formatter.string(from: date)
    }
}

struct StatusChip: View {
    let status: NewsStatus

    var body: some View {
        let (text, color): (String, Color) = {
            switch status {
            case .loading:
                return ("UPDATING", MatrixColors.matrixCyan)
            case .failed:
                return ("OFFLINE", MatrixColors.high)
            case .idle:
                return ("LIVE", MatrixColors.matrixGreen)
            }
        }()

        return Text(text)
            .font(.nasalization(size: 7))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.5), lineWidth: 1)
            )
    }
}

struct SignalSnapshotCard: View {
    let statistics: GlobalStatistics

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(MatrixColors.high)
                    .font(.system(size: 12))
                Text("SIGNAL SNAPSHOT")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.high)
                Spacer()
            }

            HStack(spacing: 10) {
                SnapshotItem(value: "\(statistics.criticalCount)", label: "CRITICAL", color: MatrixColors.critical)
                SnapshotItem(value: "\(statistics.escalatingCount)", label: "ESCALATING", color: MatrixColors.high)
                SnapshotItem(value: "\(String(format: "%.1f", statistics.totalDisplaced))M", label: "DISPLACED", color: MatrixColors.textPrimary)
            }
        }
        .padding(10)
        .matrixCard(borderColor: MatrixColors.high)
    }
}

struct SnapshotItem: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.nasalization(size: 11))
                .foregroundColor(color)
            Text(label)
                .font(.nasalization(size: 6))
                .foregroundColor(MatrixColors.textDim)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FocusConflictCard: View {
    let conflict: MajorConflict?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(MatrixColors.matrixCyan)
                    .font(.system(size: 12))
                Text("FOCUS TARGET")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.matrixCyan)
                Spacer()
            }

            if let conflict = conflict {
                VStack(alignment: .leading, spacing: 6) {
                    Text(conflict.name.uppercased())
                        .font(.nasalization(size: 10))
                        .foregroundColor(MatrixColors.textPrimary)

                    Text(conflict.region)
                        .font(.nasalization(size: 8))
                        .foregroundColor(MatrixColors.textDim)

                    HStack(spacing: 8) {
                        ThreatPill(label: conflict.threatLevel.rawValue, color: conflict.threatLevel.color)
                        ThreatPill(label: conflict.status.rawValue, color: MatrixColors.matrixGreenDim)
                    }
                }
            } else {
                Text("Select a conflict on the map to view details.")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
        .padding(10)
        .matrixCard(borderColor: MatrixColors.matrixCyan)
    }
}

struct ThreatPill: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label.uppercased())
            .font(.nasalization(size: 7))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color.opacity(0.12))
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(color.opacity(0.6), lineWidth: 1)
            )
    }
}

// MARK: - Ticker
struct WorldMonitorTickerView: View {
    let items: [MajorConflict]
    let isCompact: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items.prefix(isCompact ? 4 : 8)) { conflict in
                    TickerItem(conflict: conflict)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(height: 1),
            alignment: .top
        )
    }
}

struct TickerItem: View {
    let conflict: MajorConflict

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(conflict.threatLevel.color)
                .frame(width: 6, height: 6)
                .shadow(color: conflict.threatLevel.color.opacity(0.7), radius: 4)

            Text(conflict.name.uppercased())
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textPrimary)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(MatrixColors.cardBackground.opacity(0.9))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MatrixColors.borderGreen.opacity(0.4), lineWidth: 1)
        )
    }
}

// MARK: - Phone Feed Sheet
struct WorldMonitorFeedSheet: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @State private var feedMode: FeedMode = .news

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(MatrixColors.textDim.opacity(0.6))
                .frame(width: 40, height: 4)
                .padding(.top, 8)

            Text("LIVE FEEDS")
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.matrixGreen)
                .padding(.vertical, 8)

            FeedModeToggle(mode: $feedMode)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)

            if feedMode == .news {
                LiveNewsPanelView(dataManager: dataManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(dataManager.filteredConflicts.prefix(8)) { conflict in
                            ConflictListItem(
                                conflict: conflict,
                                isSelected: selectedConflict?.id == conflict.id
                            )
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    if selectedConflict?.id == conflict.id {
                                        selectedConflict = nil
                                    } else {
                                        selectedConflict = conflict
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 12)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(MatrixColors.panelBackground.opacity(0.98))
        .cornerRadius(16)
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .overlay(alignment: .bottom) {
            NativeAdSlotView()
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
    }
}
