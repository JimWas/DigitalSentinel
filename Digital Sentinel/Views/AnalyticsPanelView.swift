//
//  AnalyticsPanelView.swift
//  Digital Sentinel
//
//  Right analytics panel with threat indicators and network visualization
//

import SwiftUI

// MARK: - Analytics Panel View
struct AnalyticsPanelView: View {
    let conflict: MajorConflict?
    @State private var selectedTab: AnalyticsTab = .analysis
    @State private var showNetworkView = false

    enum AnalyticsTab: String, CaseIterable {
        case timeline = "Timeline"
        case analysis = "Analysis"
        case networks = "Networks"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            AnalyticsPanelHeader(selectedTab: $selectedTab)

            if let conflict = conflict {
                ScrollView {
                    VStack(spacing: 16) {
                        switch selectedTab {
                        case .timeline:
                            TimelineView(conflict: conflict)
                        case .analysis:
                            AnalysisView(conflict: conflict)
                        case .networks:
                            NetworkVisualizationView(conflict: conflict)
                        }
                    }
                    .padding(12)
                }
            } else {
                // Empty state
                EmptyAnalyticsView()
            }

            // Legends
            LegendsSection()
        }
        .frame(width: 280)
        .background(MatrixColors.panelBackground)
        .overlay(
            Rectangle()
                .fill(MatrixColors.borderGreen.opacity(0.3))
                .frame(width: 1),
            alignment: .leading
        )
    }
}

// MARK: - Analytics Panel Header
struct AnalyticsPanelHeader: View {
    @Binding var selectedTab: AnalyticsPanelView.AnalyticsTab

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundColor(MatrixColors.matrixCyan)
                    .font(.system(size: 14))

                Text("DATA & INTELLIGENCE")
                    .font(.nasalization(size: 11))
                    .foregroundColor(MatrixColors.matrixCyan)

                Spacer()

                Text("Powered by AI")
                    .font(.nasalization(size: 7))
                    .foregroundColor(MatrixColors.textDim)
            }

            // Tab selector
            HStack(spacing: 0) {
                ForEach(AnalyticsPanelView.AnalyticsTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        Text(tab.rawValue)
                            .font(.nasalization(size: 9))
                            .foregroundColor(selectedTab == tab ? MatrixColors.matrixGreen : MatrixColors.textDim)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                selectedTab == tab ? MatrixColors.matrixGreen.opacity(0.1) : Color.clear
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
        .padding(12)
        .background(MatrixColors.cardBackground.opacity(0.5))
    }
}

// MARK: - Analysis View
struct AnalysisView: View {
    let conflict: MajorConflict

    var body: some View {
        VStack(spacing: 16) {
            // Threat indicators
            ThreatIndicatorsCard(conflict: conflict)

            // Monthly incidents chart
            MonthlyIncidentsChart()

            // Analyst forecast
            AnalystForecastCard(conflict: conflict)
        }
    }
}

// MARK: - Threat Indicators Card
struct ThreatIndicatorsCard: View {
    let conflict: MajorConflict
    @State private var animateProgress = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(MatrixColors.high)
                    .font(.system(size: 12))
                Text("THREAT INCREASING")
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.high)
            }

            // Indicators grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ThreatIndicator(
                    label: "ESCALATION RISK",
                    value: conflict.escalationRisk,
                    severity: getSeverity(conflict.escalationRisk),
                    animated: animateProgress
                )

                ThreatIndicator(
                    label: "HUMANITARIAN CRISIS",
                    value: conflict.humanitarianCrisis,
                    severity: getSeverity(conflict.humanitarianCrisis),
                    animated: animateProgress
                )

                ThreatIndicator(
                    label: "GEOPOLITICAL IMPACT",
                    value: conflict.geopoliticalImpact,
                    severity: getSeverity(conflict.geopoliticalImpact),
                    animated: animateProgress
                )

                ThreatIndicator(
                    label: "STABILITY INDEX",
                    value: conflict.stabilityIndex * 10,
                    severity: getStabilitySeverity(conflict.stabilityIndex),
                    animated: animateProgress,
                    displayValue: "\(conflict.stabilityIndex)",
                    suffix: "EXTREME"
                )
            }
        }
        .padding(12)
        .matrixCard()
        .onAppear {
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animateProgress = true
            }
        }
    }

    private func getSeverity(_ value: Int) -> ThreatIndicatorSeverity {
        switch value {
        case 0..<40: return .low
        case 40..<60: return .medium
        case 60..<80: return .high
        default: return .extreme
        }
    }

    private func getStabilitySeverity(_ value: Int) -> ThreatIndicatorSeverity {
        switch value {
        case 7...10: return .low
        case 5..<7: return .medium
        case 3..<5: return .high
        default: return .extreme
        }
    }
}

// MARK: - Threat Indicator
enum ThreatIndicatorSeverity {
    case low, medium, high, extreme

    var color: Color {
        switch self {
        case .low: return MatrixColors.low
        case .medium: return MatrixColors.medium
        case .high: return MatrixColors.high
        case .extreme: return MatrixColors.critical
        }
    }

    var label: String {
        switch self {
        case .low: return "LOW"
        case .medium: return "MEDIUM"
        case .high: return "HIGH"
        case .extreme: return "EXTREME"
        }
    }
}

struct ThreatIndicator: View {
    let label: String
    let value: Int
    let severity: ThreatIndicatorSeverity
    let animated: Bool
    var displayValue: String? = nil
    var suffix: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.nasalization(size: 7))
                .foregroundColor(MatrixColors.textDim)

            Text(displayValue ?? "\(value)")
                .font(.nasalization(size: 24))
                .foregroundColor(severity.color)
                .shadow(color: severity.color.opacity(0.5), radius: 4)

            Text(suffix ?? severity.label)
                .font(.nasalization(size: 7))
                .foregroundColor(severity.color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(severity.color.opacity(0.05))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(severity.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Monthly Incidents Chart
struct MonthlyIncidentsChart: View {
    let months = ["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"]
    let values: [Double] = [35, 42, 38, 55, 62, 48, 71, 65, 58, 72, 80, 75]
    @State private var animateChart = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MONTHLY INCIDENTS (12 MONTHS)")
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)

            GeometryReader { geometry in
                let maxValue = values.max() ?? 100
                let barWidth = (geometry.size.width - CGFloat(months.count - 1) * 3) / CGFloat(months.count)

                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(months.enumerated()), id: \.offset) { index, month in
                        VStack(spacing: 2) {
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [MatrixColors.matrixGreen, MatrixColors.matrixGreenDim],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(
                                    width: barWidth,
                                    height: animateChart ? CGFloat(values[index] / maxValue) * (geometry.size.height - 15) : 0
                                )
                                .cornerRadius(2)

                            Text(month)
                                .font(.nasalization(size: 6))
                                .foregroundColor(MatrixColors.textDim)
                        }
                    }
                }
            }
            .frame(height: 80)
        }
        .padding(12)
        .matrixCard()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animateChart = true
            }
        }
    }
}

// MARK: - Analyst Forecast Card
struct AnalystForecastCard: View {
    let conflict: MajorConflict

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ANALYST FORECAST")
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)

            Text(getForecast())
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.textSecondary)
                .lineLimit(4)
        }
        .padding(12)
        .matrixCard()
    }

    private func getForecast() -> String {
        switch conflict.threatLevel {
        case .critical:
            return "Situation remains critical with high probability of further escalation. Immediate international attention required. Proxy dimensions intensifying."
        case .high:
            return "Elevated threat level with ongoing hostilities. Regional stability at risk. Humanitarian corridors under pressure."
        case .medium:
            return "Moderate risk with periodic flare-ups. Diplomatic channels active. Monitoring for escalation triggers."
        case .low:
            return "Relatively stable with isolated incidents. De-escalation efforts showing progress. Continued monitoring advised."
        }
    }
}

// MARK: - Timeline View
struct TimelineView: View {
    let conflict: MajorConflict

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT EVENTS")
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.textDim)

            ForEach(0..<5) { index in
                TimelineEventItem(
                    date: "Feb \(8 - index), 2026",
                    title: getEventTitle(index),
                    severity: getSeverity(index)
                )
            }
        }
    }

    private func getEventTitle(_ index: Int) -> String {
        let events = [
            "Artillery exchanges reported",
            "Civilian casualties confirmed",
            "Diplomatic talks paused",
            "Aid convoy attacked",
            "Ceasefire violations"
        ]
        return events[index % events.count]
    }

    private func getSeverity(_ index: Int) -> ThreatLevel {
        [.critical, .high, .medium, .high, .medium][index % 5]
    }
}

// MARK: - Timeline Event Item
struct TimelineEventItem: View {
    let date: String
    let title: String
    let severity: ThreatLevel

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Circle()
                    .fill(severity.color)
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(MatrixColors.borderGreen.opacity(0.3))
                    .frame(width: 1, height: 30)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(date)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)

                Text(title)
                    .font(.nasalization(size: 10))
                    .foregroundColor(MatrixColors.textSecondary)
            }
        }
    }
}

// MARK: - Network Visualization View
struct NetworkVisualizationView: View {
    let conflict: MajorConflict
    @State private var nodes: [NetworkDisplayNode] = []
    @State private var animateNodes = false

    struct NetworkDisplayNode: Identifiable {
        let id = UUID()
        var name: String
        var type: NetworkNode.NodeType
        var position: CGPoint
        var connections: [Int]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTOR NETWORK")
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.textDim)

            GeometryReader { geometry in
                ZStack {
                    // Connection lines
                    ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                        ForEach(node.connections, id: \.self) { targetIndex in
                            if targetIndex < nodes.count {
                                Path { path in
                                    path.move(to: node.position)
                                    path.addLine(to: nodes[targetIndex].position)
                                }
                                .stroke(MatrixColors.matrixGreen.opacity(0.3), lineWidth: 1)
                            }
                        }
                    }

                    // Nodes
                    ForEach(nodes) { node in
                        NetworkNodeView(node: node)
                            .position(node.position)
                            .opacity(animateNodes ? 1 : 0)
                            .scaleEffect(animateNodes ? 1 : 0.5)
                    }
                }
            }
            .frame(height: 200)
            .background(MatrixColors.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
            )
            .onAppear {
                generateNodes()
                withAnimation(.easeOut(duration: 0.5)) {
                    animateNodes = true
                }
            }

            // Legend
            NetworkLegend()
        }
    }

    private func generateNodes() {
        let parties = conflict.parties.prefix(4)
        let centerX: CGFloat = 120
        let centerY: CGFloat = 100
        let radius: CGFloat = 60

        nodes = parties.enumerated().map { index, party in
            let angle = (Double(index) / Double(parties.count)) * 2 * .pi - .pi / 2
            let x = centerX + radius * cos(angle)
            let y = centerY + radius * sin(angle)

            return NetworkDisplayNode(
                name: String(party.prefix(15)),
                type: index == 0 ? .stateActor : (index == 1 ? .stateActor : .nonStateActor),
                position: CGPoint(x: x, y: y),
                connections: index == 0 ? Array(1..<parties.count) : [0]
            )
        }
    }
}

// MARK: - Network Node View
struct NetworkNodeView: View {
    let node: NetworkVisualizationView.NetworkDisplayNode

    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(node.type.color)
                .frame(width: 24, height: 24)
                .shadow(color: node.type.color.opacity(0.5), radius: 4)
                .overlay(
                    Circle()
                        .stroke(node.type.color.opacity(0.8), lineWidth: 2)
                        .scaleEffect(1.3)
                )

            Text(node.name)
                .font(.nasalization(size: 6))
                .foregroundColor(MatrixColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}

// MARK: - Network Legend
struct NetworkLegend: View {
    var body: some View {
        HStack(spacing: 12) {
            LegendItem(color: NetworkNode.NodeType.stateActor.color, label: "State Actor")
            LegendItem(color: NetworkNode.NodeType.nonStateActor.color, label: "Non-State")
            LegendItem(color: NetworkNode.NodeType.aptGroup.color, label: "APT Group")
        }
    }
}

struct LegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.nasalization(size: 7))
                .foregroundColor(MatrixColors.textDim)
        }
    }
}

// MARK: - Empty Analytics View
struct EmptyAnalyticsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(MatrixColors.textDim)

            Text("Select a conflict to view analytics")
                .font(.nasalization(size: 11))
                .foregroundColor(MatrixColors.textDim)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Legends Section
struct LegendsSection: View {
    var body: some View {
        VStack(spacing: 8) {
            Divider()
                .background(MatrixColors.borderGreen.opacity(0.3))

            HStack(alignment: .top, spacing: 12) {
                ThreatLevelLegend()
                ConnectionLinesLegend()
            }
            .padding(12)
        }
        .background(MatrixColors.cardBackground.opacity(0.5))
    }
}
