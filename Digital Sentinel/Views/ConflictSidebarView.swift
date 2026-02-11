//
//  ConflictSidebarView.swift
//  Digital Sentinel
//
//  Left sidebar with conflict list, search, and filters
//

import SwiftUI

// MARK: - Conflict Sidebar View
struct ConflictSidebarView: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @Binding var showAnalytics: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            SidebarHeader(statistics: dataManager.statistics)

            // Search and filters
            SearchFilterSection(
                searchText: $dataManager.searchText,
                selectedFilter: $dataManager.selectedFilter
            )

            // Conflict list
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
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Spacer()

            // Footer
            SidebarFooter(showAnalytics: $showAnalytics)
        }
        .frame(width: 280)
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(width: 1),
            alignment: .trailing
        )
    }
}

// MARK: - Sidebar Header
struct SidebarHeader: View {
    let statistics: GlobalStatistics
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 12) {
            // Title row
            HStack(spacing: 8) {
                // Animated logo
                ZStack {
                    Circle()
                        .stroke(MatrixColors.matrixGreen.opacity(0.3), lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))

                    Circle()
                        .stroke(MatrixColors.matrixCyan.opacity(0.5), lineWidth: 1)
                        .frame(width: 24, height: 24)
                        .rotationEffect(.degrees(isAnimating ? -360 : 0))

                    Image(systemName: "globe")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MatrixColors.matrixGreen)
                }
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 10)
                            .repeatForever(autoreverses: false)
                    ) {
                        isAnimating = true
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("GLOBAL CONFLICT MONITOR")
                        .font(.nasalization(size: 12))
                        .foregroundColor(MatrixColors.matrixGreen)

                    Text("Real-time Threat Intelligence")
                        .font(.nasalization(size: 8))
                        .foregroundColor(MatrixColors.textDim)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 16)

            // Stats row
            HStack(spacing: 8) {
                MiniStatBox(value: "\(statistics.activeConflicts)", label: "ACTIVE", color: MatrixColors.textPrimary)
                MiniStatBox(value: "\(statistics.criticalCount)", label: "CRITICAL", color: MatrixColors.critical, highlighted: true)
                MiniStatBox(value: "\(statistics.escalatingCount)", label: "ESCALATING", color: MatrixColors.high, highlighted: true)
                MiniStatBox(value: "\(String(format: "%.1f", statistics.totalDisplaced))M", label: "DISPLACED", color: MatrixColors.textPrimary)
            }
            .padding(.horizontal, 12)
        }
        .padding(.bottom, 12)
        .background(MatrixColors.cardBackground.opacity(0.5))
    }
}

// MARK: - Mini Stat Box
struct MiniStatBox: View {
    let value: String
    let label: String
    let color: Color
    var highlighted: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.nasalization(size: 14))
                .foregroundColor(color)

            Text(label)
                .font(.nasalization(size: 6))
                .foregroundColor(MatrixColors.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(highlighted ? color.opacity(0.1) : MatrixColors.cardBackground)
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(highlighted ? color.opacity(0.5) : MatrixColors.borderGreen.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Search Filter Section
struct SearchFilterSection: View {
    @Binding var searchText: String
    @Binding var selectedFilter: ThreatLevel?

    var body: some View {
        VStack(spacing: 8) {
            // Search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(MatrixColors.textDim)
                    .font(.system(size: 12))

                TextField("Search conflicts, regions...", text: $searchText)
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
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(MatrixColors.cardBackground)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
            )

            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    FilterChip(label: "All", isSelected: selectedFilter == nil) {
                        selectedFilter = nil
                    }

                    ForEach(ThreatLevel.allCases, id: \.self) { level in
                        FilterChip(
                            label: level.rawValue,
                            isSelected: selectedFilter == level,
                            color: level.color
                        ) {
                            selectedFilter = selectedFilter == level ? nil : level
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = MatrixColors.matrixGreen
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.nasalization(size: 9))
                .foregroundColor(isSelected ? .black : color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(isSelected ? color : color.opacity(0.1))
                .cornerRadius(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(color.opacity(0.5), lineWidth: 1)
                )
        }
    }
}

// MARK: - Conflict List Item
struct ConflictListItem: View {
    let conflict: MajorConflict
    let isSelected: Bool
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Title row
            HStack(spacing: 8) {
                // Threat indicator
                Circle()
                    .fill(conflict.threatLevel.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: conflict.threatLevel.color.opacity(0.5), radius: 3)

                Text(conflict.name)
                    .font(.nasalization(size: 11))
                    .foregroundColor(MatrixColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                if isSelected {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MatrixColors.matrixGreen)
                }
            }

            // Subtitle
            HStack(spacing: 6) {
                Text(conflict.type.rawValue)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)

                Text("•")
                    .foregroundColor(MatrixColors.textDim)

                Text(conflict.region)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            }

            // Stats row
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 8))
                        .foregroundColor(MatrixColors.textDim)
                    Text(formatNumber(conflict.casualties))
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textSecondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: "figure.walk.departure")
                        .font(.system(size: 8))
                        .foregroundColor(MatrixColors.textDim)
                    Text("\(String(format: "%.1f", conflict.displaced))M")
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textSecondary)
                }

                Spacer()

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
        .padding(10)
        .background(
            isSelected ? conflict.threatLevel.color.opacity(0.1) :
            (isHovered ? MatrixColors.cardBackground : Color.clear)
        )
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    isSelected ? conflict.threatLevel.color.opacity(0.5) :
                    (isHovered ? MatrixColors.borderGreen.opacity(0.3) : Color.clear),
                    lineWidth: 1
                )
        )
        .onHover { hovering in
            isHovered = hovering
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
}

// MARK: - Sidebar Footer
struct SidebarFooter: View {
    @Binding var showAnalytics: Bool

    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(MatrixColors.borderGreen.opacity(0.3))

            HStack {
                Text("DATA FOR DEMONSTRATION PURPOSES ONLY")
                    .font(.nasalization(size: 6))
                    .foregroundColor(MatrixColors.textDim)

                Spacer()

                Button(action: { showAnalytics.toggle() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 10))
                        Text("Analytics")
                            .font(.nasalization(size: 9))
                    }
                    .foregroundColor(showAnalytics ? MatrixColors.matrixGreen : MatrixColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(showAnalytics ? MatrixColors.matrixGreen.opacity(0.1) : Color.clear)
                    .cornerRadius(4)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(MatrixColors.cardBackground.opacity(0.5))
    }
}

// MARK: - Threat Level Legend
struct ThreatLevelLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("THREAT LEVEL")
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)

            ForEach(ThreatLevel.allCases, id: \.self) { level in
                HStack(spacing: 8) {
                    Circle()
                        .fill(level.color)
                        .frame(width: 8, height: 8)
                    Text(level.rawValue)
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(MatrixColors.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Connection Lines Legend
struct ConnectionLinesLegend: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CONNECTION LINES")
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)

            ForEach(ConnectionLineType.allCases, id: \.self) { type in
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(type.color)
                        .frame(width: 16, height: 2)
                    Text(type.rawValue)
                        .font(.nasalization(size: 9))
                        .foregroundColor(MatrixColors.textSecondary)
                }
            }
        }
        .padding(12)
        .background(MatrixColors.cardBackground)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
        )
    }
}
