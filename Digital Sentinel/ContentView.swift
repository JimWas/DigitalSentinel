//
//  ContentView.swift
//  Digital Sentinel
//
//  Main view combining all components for the Global Conflict Monitor
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = ConflictDataManager()
    @State private var selectedConflict: MajorConflict?
    @State private var showAnalytics = true
    @State private var showSidebar = true

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 700

            ZStack {
                // Matrix background
                MatrixBackground(columns: isCompact ? 20 : 40)
                    .ignoresSafeArea()

                if isCompact {
                    // iPhone layout - vertical stack with bottom sheet
                    iPhoneLayout(geometry: geometry)
                } else {
                    // iPad layout - horizontal panels
                    iPadLayout(geometry: geometry)
                }

                // Scanline overlay
                ScanlineEffect()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: - iPhone Layout
    @ViewBuilder
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        ZStack {
            // Map takes full screen
            WorldMapView(dataManager: dataManager, selectedConflict: $selectedConflict)
                .ignoresSafeArea()

            // Top stats bar
            VStack {
                CompactStatsBar(statistics: dataManager.statistics)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Spacer()
            }

            // Bottom sheet with conflict list
            VStack(spacing: 0) {
                Spacer()

                CompactConflictSheet(
                    dataManager: dataManager,
                    selectedConflict: $selectedConflict
                )
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: - iPad Layout
    @ViewBuilder
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            // Left sidebar
            if showSidebar {
                ConflictSidebarView(
                    dataManager: dataManager,
                    selectedConflict: $selectedConflict,
                    showAnalytics: $showAnalytics
                )
                .transition(.move(edge: .leading))
            }

            // Center map
            ZStack {
                WorldMapView(dataManager: dataManager, selectedConflict: $selectedConflict)

                // Toggle buttons
                VStack {
                    HStack {
                        // Sidebar toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showSidebar.toggle()
                            }
                        }) {
                            Image(systemName: showSidebar ? "sidebar.left" : "sidebar.right")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MatrixColors.matrixGreen)
                                .padding(10)
                                .background(MatrixColors.cardBackground.opacity(0.9))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(MatrixColors.borderGreen.opacity(0.5), lineWidth: 1)
                                )
                        }

                        Spacer()

                        // Analytics toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showAnalytics.toggle()
                            }
                        }) {
                            Image(systemName: showAnalytics ? "chart.bar.fill" : "chart.bar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(MatrixColors.matrixCyan)
                                .padding(10)
                                .background(MatrixColors.cardBackground.opacity(0.9))
                                .cornerRadius(6)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(MatrixColors.matrixCyan.opacity(0.5), lineWidth: 1)
                                )
                        }
                    }
                    .padding(12)

                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)

            // Right analytics panel
            if showAnalytics {
                AnalyticsPanelView(conflict: selectedConflict)
                    .transition(.move(edge: .trailing))
            }
        }
    }
}

// MARK: - Compact Stats Bar (iPhone)
struct CompactStatsBar: View {
    let statistics: GlobalStatistics
    @State private var isBlinking = false

    var body: some View {
        HStack(spacing: 6) {
            // Live indicator
            HStack(spacing: 4) {
                Circle()
                    .fill(MatrixColors.matrixGreen)
                    .frame(width: 6, height: 6)
                    .opacity(isBlinking ? 1.0 : 0.4)

                Text("LIVE")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.matrixGreen)
            }

            Spacer()

            // Stats
            HStack(spacing: 12) {
                CompactStat(value: "\(statistics.activeConflicts)", label: "Active", color: MatrixColors.textPrimary)
                CompactStat(value: "\(statistics.criticalCount)", label: "Critical", color: MatrixColors.critical)
                CompactStat(value: "\(statistics.escalatingCount)", label: "Escalating", color: MatrixColors.high)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MatrixColors.overlayBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isBlinking = true
            }
        }
    }
}

struct CompactStat: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.nasalization(size: 12))
                .foregroundColor(color)
            Text(label)
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)
        }
    }
}

// MARK: - Compact Conflict Sheet (iPhone)
struct CompactConflictSheet: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @State private var sheetHeight: SheetHeight = .partial
    @GestureState private var dragOffset: CGFloat = 0

    enum SheetHeight {
        case collapsed, partial, expanded

        var height: CGFloat {
            switch self {
            case .collapsed: return 80
            case .partial: return 320
            case .expanded: return UIScreen.main.bounds.height * 0.75
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Handle area
            SheetHandle(
                title: selectedConflict != nil ? "CONFLICT DETAILS" : "CONFLICTS",
                showBackButton: selectedConflict != nil,
                onBack: {
                    withAnimation(.spring(response: 0.3)) {
                        selectedConflict = nil
                    }
                }
            )
            .gesture(
                DragGesture()
                    .updating($dragOffset) { value, state, _ in
                        state = value.translation.height
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        if value.translation.height < -threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                sheetHeight = sheetHeight == .collapsed ? .partial : .expanded
                            }
                        } else if value.translation.height > threshold {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                sheetHeight = sheetHeight == .expanded ? .partial : .collapsed
                            }
                        }
                    }
            )

            // Content
            if sheetHeight != .collapsed {
                if let conflict = selectedConflict {
                    // Show expanded detail view
                    ConflictExpandedDetailView(conflict: conflict)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .trailing).combined(with: .opacity)
                        ))
                } else {
                    // Show conflict list
                    VStack(spacing: 8) {
                        // Search bar
                        CompactSearchBar(searchText: $dataManager.searchText)

                        // Conflict list
                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(dataManager.filteredConflicts) { conflict in
                                    CompactConflictItem(
                                        conflict: conflict,
                                        isSelected: false
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedConflict = conflict
                                            sheetHeight = .expanded
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .frame(height: max(sheetHeight.height - dragOffset, 80))
        .frame(maxWidth: .infinity)
        .background(
            MatrixColors.overlayBackground
                .cornerRadius(20, corners: [.topLeft, .topRight])
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(MatrixColors.borderGreen.opacity(0.4), lineWidth: 1)
                .cornerRadius(20, corners: [.topLeft, .topRight])
        )
    }
}

// MARK: - Sheet Handle
struct SheetHandle: View {
    let title: String
    var showBackButton: Bool = false
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(MatrixColors.textDim)
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            // Title row
            HStack {
                if showBackButton {
                    Button(action: { onBack?() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 12, weight: .semibold))
                            Text("BACK")
                                .font(.nasalization(size: 9))
                        }
                        .foregroundColor(MatrixColors.matrixCyan)
                    }
                }

                Spacer()

                Text(title)
                    .font(.nasalization(size: 11))
                    .foregroundColor(MatrixColors.matrixGreen)

                Spacer()

                if showBackButton {
                    // Placeholder for symmetry
                    Color.clear.frame(width: 50, height: 20)
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 10)
    }
}

// MARK: - Conflict Expanded Detail View
struct ConflictExpandedDetailView: View {
    let conflict: MajorConflict
    @State private var animateIn = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with threat badge
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(conflict.name)
                            .font(.nasalization(size: 18))
                            .foregroundColor(MatrixColors.textPrimary)

                        HStack(spacing: 8) {
                            ThreatBadge(level: conflict.threatLevel)
                            StatusIndicator(status: conflict.status)
                        }
                    }

                    Spacer()

                    // Threat pulse indicator
                    ThreatPulseIndicator(level: conflict.threatLevel)
                }

                // Type and region
                HStack(spacing: 16) {
                    DetailTag(icon: conflict.type.icon, text: conflict.type.rawValue)
                    DetailTag(icon: "mappin.circle.fill", text: conflict.region)
                }

                // Description
                Text(conflict.description)
                    .font(.nasalization(size: 11))
                    .foregroundColor(MatrixColors.textSecondary)
                    .lineSpacing(4)

                // Stats grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    StatCard(
                        title: "CASUALTIES",
                        value: formatNumber(conflict.casualties),
                        icon: "person.fill",
                        color: MatrixColors.critical
                    )

                    StatCard(
                        title: "DISPLACED",
                        value: "\(String(format: "%.1f", conflict.displaced))M",
                        icon: "figure.walk.departure",
                        color: MatrixColors.high
                    )

                    StatCard(
                        title: "ESCALATION RISK",
                        value: "\(conflict.escalationRisk)%",
                        icon: "arrow.up.right",
                        color: riskColor(conflict.escalationRisk)
                    )

                    StatCard(
                        title: "STABILITY INDEX",
                        value: "\(conflict.stabilityIndex)/10",
                        icon: "waveform.path.ecg",
                        color: stabilityColor(conflict.stabilityIndex)
                    )
                }

                // Threat indicators
                VStack(alignment: .leading, spacing: 10) {
                    Text("THREAT ANALYSIS")
                        .font(.nasalization(size: 10))
                        .foregroundColor(MatrixColors.textDim)

                    ThreatBar(label: "Escalation Risk", value: conflict.escalationRisk)
                    ThreatBar(label: "Humanitarian Crisis", value: conflict.humanitarianCrisis)
                    ThreatBar(label: "Geopolitical Impact", value: conflict.geopoliticalImpact)
                }
                .padding(12)
                .background(MatrixColors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
                )

                // Parties involved
                VStack(alignment: .leading, spacing: 8) {
                    Text("PARTIES INVOLVED")
                        .font(.nasalization(size: 10))
                        .foregroundColor(MatrixColors.textDim)

                    ForEach(conflict.parties, id: \.self) { party in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(MatrixColors.matrixGreen)
                                .frame(width: 6, height: 6)
                            Text(party)
                                .font(.nasalization(size: 10))
                                .foregroundColor(MatrixColors.textSecondary)
                        }
                    }
                }
                .padding(12)
                .background(MatrixColors.cardBackground)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
                )

                // Timeline info
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(MatrixColors.textDim)
                        .font(.system(size: 12))
                    Text("Conflict started: \(conflict.startDate)")
                        .font(.nasalization(size: 10))
                        .foregroundColor(MatrixColors.textDim)
                }
                .padding(.top, 8)
            }
            .padding(.bottom, 30)
        }
        .opacity(animateIn ? 1 : 0)
        .offset(y: animateIn ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                animateIn = true
            }
        }
    }

    private func formatNumber(_ num: Int) -> String {
        if num >= 1000000 {
            return String(format: "%.1fM", Double(num) / 1000000)
        } else if num >= 1000 {
            return String(format: "%.0fK", Double(num) / 1000)
        }
        return "\(num)"
    }

    private func riskColor(_ value: Int) -> Color {
        if value >= 80 { return MatrixColors.critical }
        if value >= 60 { return MatrixColors.high }
        if value >= 40 { return MatrixColors.medium }
        return MatrixColors.low
    }

    private func stabilityColor(_ value: Int) -> Color {
        if value <= 2 { return MatrixColors.critical }
        if value <= 4 { return MatrixColors.high }
        if value <= 6 { return MatrixColors.medium }
        return MatrixColors.low
    }
}

// MARK: - Supporting Views
struct DetailTag: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(MatrixColors.matrixCyan)
            Text(text)
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(MatrixColors.cardBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MatrixColors.matrixCyan.opacity(0.3), lineWidth: 1)
        )
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.nasalization(size: 20))
                .foregroundColor(color)

            Text(title)
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)
        }
        .padding(12)
        .background(MatrixColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ThreatBar: View {
    let label: String
    let value: Int
    @State private var animatedValue: CGFloat = 0

    var barColor: Color {
        if value >= 80 { return MatrixColors.critical }
        if value >= 60 { return MatrixColors.high }
        if value >= 40 { return MatrixColors.medium }
        return MatrixColors.low
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
                Spacer()
                Text("\(value)%")
                    .font(.nasalization(size: 10))
                    .foregroundColor(barColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(MatrixColors.darkBackground)
                        .frame(height: 6)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [barColor.opacity(0.6), barColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * animatedValue, height: 6)
                        .shadow(color: barColor.opacity(0.5), radius: 3)
                }
                .cornerRadius(3)
            }
            .frame(height: 6)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animatedValue = CGFloat(value) / 100
            }
        }
    }
}

struct ThreatPulseIndicator: View {
    let level: ThreatLevel
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(level.color.opacity(0.3), lineWidth: 2)
                .frame(width: 50, height: 50)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)

            Circle()
                .fill(level.color)
                .frame(width: 30, height: 30)
                .shadow(color: level.color.opacity(0.6), radius: 8)

            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 10, height: 10)
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.2)
                    .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

struct CompactSearchBar: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(MatrixColors.textDim)
                .font(.system(size: 12))

            TextField("Search conflicts...", text: $searchText)
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.textPrimary)
                .tint(MatrixColors.matrixGreen)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(MatrixColors.textDim)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(MatrixColors.cardBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CompactConflictItem: View {
    let conflict: MajorConflict
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Threat indicator
            ZStack {
                Circle()
                    .fill(conflict.threatLevel.color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Circle()
                    .fill(conflict.threatLevel.color)
                    .frame(width: 12, height: 12)
                    .shadow(color: conflict.threatLevel.color.opacity(0.6), radius: 4)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(conflict.name)
                    .font(.nasalization(size: 12))
                    .foregroundColor(MatrixColors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text(conflict.region)
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textDim)

                    if conflict.status == .escalating {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                            Text("Escalating")
                                .font(.nasalization(size: 8))
                        }
                        .foregroundColor(MatrixColors.high)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(MatrixColors.matrixGreen)
        }
        .padding(12)
        .background(MatrixColors.cardBackground.opacity(0.6))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MatrixColors.borderGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Corner Radius Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
