//
//  WorldMapView.swift
//  Digital Sentinel
//
//  Interactive world map with conflict markers
//

import SwiftUI
import MapKit

// MARK: - World Map View
struct WorldMapView: View {
    @ObservedObject var dataManager: ConflictDataManager
    @Binding var selectedConflict: MajorConflict?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 20),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 180)
    )
    @State private var showDetailCard = false

    var body: some View {
        ZStack {
            // Map with dark styling
            Map(coordinateRegion: $mapRegion, annotationItems: dataManager.conflicts) { conflict in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: conflict.coordinate.latitude,
                    longitude: conflict.coordinate.longitude
                )) {
                    ConflictMarker(conflict: conflict, isSelected: selectedConflict?.id == conflict.id)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                if selectedConflict?.id == conflict.id {
                                    selectedConflict = nil
                                } else {
                                    selectedConflict = conflict
                                    showDetailCard = true
                                }
                            }
                        }
                }
            }
            .mapStyle(.imagery)
            .colorScheme(.dark)

            // Dark overlay for matrix effect
            MatrixColors.darkBackground.opacity(0.6)
                .allowsHitTesting(false)

            // Grid overlay
            GridOverlay(spacing: 80, lineWidth: 0.3, color: MatrixColors.matrixGreen.opacity(0.08))

            // Custom markers overlay (for more control)
            GeometryReader { geometry in
                ForEach(dataManager.conflicts) { conflict in
                    ConflictMarkerOverlay(
                        conflict: conflict,
                        isSelected: selectedConflict?.id == conflict.id,
                        mapSize: geometry.size,
                        mapRegion: mapRegion
                    )
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if selectedConflict?.id == conflict.id {
                                selectedConflict = nil
                            } else {
                                selectedConflict = conflict
                            }
                        }
                    }
                }

                // Connection lines between related conflicts
                ConnectionLinesView(conflicts: dataManager.conflicts, mapSize: geometry.size, mapRegion: mapRegion)
            }

            // Live monitoring indicator
            VStack {
                HStack {
                    Spacer()
                    LiveMonitoringIndicator(activeZones: dataManager.statistics.activeZones)
                        .padding(.trailing, 16)
                        .padding(.top, 8)
                }
                Spacer()
            }

            // Detail card when conflict selected
            if let conflict = selectedConflict {
                VStack {
                    Spacer()
                    ConflictDetailCard(conflict: conflict) {
                        withAnimation { selectedConflict = nil }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }
}

// MARK: - Conflict Marker
struct ConflictMarker: View {
    let conflict: MajorConflict
    let isSelected: Bool
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulse ring
            Circle()
                .stroke(conflict.threatLevel.color.opacity(0.3), lineWidth: 2)
                .frame(width: isSelected ? 50 : 30, height: isSelected ? 50 : 30)
                .scaleEffect(isPulsing ? 1.5 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)

            // Inner pulse ring
            Circle()
                .stroke(conflict.threatLevel.color.opacity(0.5), lineWidth: 1)
                .frame(width: isSelected ? 40 : 24, height: isSelected ? 40 : 24)
                .scaleEffect(isPulsing ? 1.3 : 1.0)
                .opacity(isPulsing ? 0 : 0.8)

            // Main dot
            Circle()
                .fill(
                    RadialGradient(
                        colors: [conflict.threatLevel.color, conflict.threatLevel.color.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: isSelected ? 12 : 8
                    )
                )
                .frame(width: isSelected ? 24 : 16, height: isSelected ? 24 : 16)
                .shadow(color: conflict.threatLevel.color.opacity(0.8), radius: 8)

            // Center bright spot
            Circle()
                .fill(Color.white)
                .frame(width: isSelected ? 8 : 5, height: isSelected ? 8 : 5)
                .opacity(0.9)
        }
        .animation(.easeInOut(duration: 0.3), value: isSelected)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false)
            ) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Conflict Marker Overlay
struct ConflictMarkerOverlay: View {
    let conflict: MajorConflict
    let isSelected: Bool
    let mapSize: CGSize
    let mapRegion: MKCoordinateRegion

    var position: CGPoint {
        let lat = conflict.coordinate.latitude
        let lon = conflict.coordinate.longitude

        let centerLat = mapRegion.center.latitude
        let centerLon = mapRegion.center.longitude
        let spanLat = mapRegion.span.latitudeDelta
        let spanLon = mapRegion.span.longitudeDelta

        let x = ((lon - centerLon + spanLon / 2) / spanLon) * mapSize.width
        let y = ((centerLat - lat + spanLat / 2) / spanLat) * mapSize.height

        return CGPoint(x: x, y: y)
    }

    var body: some View {
        ConflictMarker(conflict: conflict, isSelected: isSelected)
            .position(position)
    }
}

// MARK: - Connection Lines View
struct ConnectionLinesView: View {
    let conflicts: [MajorConflict]
    let mapSize: CGSize
    let mapRegion: MKCoordinateRegion

    // Define some connections for visualization
    private let connections: [(Int, Int, ConnectionLineType)] = [
        (0, 2, .spillover),  // Ukraine - Sudan (spillover effects)
        (1, 5, .alliance),   // Israel - Syria
        (1, 6, .proxyWar),   // Israel - Yemen
        (3, 4, .spillover),  // Myanmar - Ethiopia
        (7, 9, .cyberLink),  // Cyber - Taiwan
    ]

    func position(for conflict: MajorConflict) -> CGPoint {
        let lat = conflict.coordinate.latitude
        let lon = conflict.coordinate.longitude

        let centerLat = mapRegion.center.latitude
        let centerLon = mapRegion.center.longitude
        let spanLat = mapRegion.span.latitudeDelta
        let spanLon = mapRegion.span.longitudeDelta

        let x = ((lon - centerLon + spanLon / 2) / spanLon) * mapSize.width
        let y = ((centerLat - lat + spanLat / 2) / spanLat) * mapSize.height

        return CGPoint(x: x, y: y)
    }

    var body: some View {
        Canvas { context, size in
            for (fromIndex, toIndex, lineType) in connections {
                guard fromIndex < conflicts.count, toIndex < conflicts.count else { continue }

                let from = position(for: conflicts[fromIndex])
                let to = position(for: conflicts[toIndex])

                var path = Path()
                path.move(to: from)

                // Create curved line
                let midX = (from.x + to.x) / 2
                let midY = (from.y + to.y) / 2 - 30
                path.addQuadCurve(to: to, control: CGPoint(x: midX, y: midY))

                if lineType.dashPattern.isEmpty {
                    context.stroke(
                        path,
                        with: .color(lineType.color.opacity(0.4)),
                        lineWidth: 1
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(lineType.color.opacity(0.4)),
                        style: StrokeStyle(lineWidth: 1, dash: lineType.dashPattern)
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Live Monitoring Indicator
struct LiveMonitoringIndicator: View {
    let activeZones: Int
    @State private var isBlinking = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(MatrixColors.matrixGreen)
                .frame(width: 8, height: 8)
                .opacity(isBlinking ? 1.0 : 0.4)
                .shadow(color: MatrixColors.matrixGreen, radius: 4)

            Text("LIVE MONITORING")
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.matrixGreen)

            Text("\(activeZones) active zones")
                .font(.nasalization(size: 9))
                .foregroundColor(MatrixColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(MatrixColors.cardBackground.opacity(0.9))
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(MatrixColors.matrixGreen.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true)
            ) {
                isBlinking = true
            }
        }
    }
}

// MARK: - Conflict Detail Card
struct ConflictDetailCard: View {
    let conflict: MajorConflict
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(conflict.name)
                        .font(.nasalization(size: 16))
                        .foregroundColor(MatrixColors.textPrimary)

                    HStack(spacing: 8) {
                        ThreatBadge(level: conflict.threatLevel)
                        Text(conflict.type.rawValue)
                            .font(.nasalization(size: 9))
                            .foregroundColor(MatrixColors.textSecondary)
                        StatusIndicator(status: conflict.status)
                    }
                }

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(MatrixColors.textSecondary)
                        .padding(8)
                        .background(MatrixColors.cardBackground)
                        .cornerRadius(4)
                }
            }

            // Description
            Text(conflict.description)
                .font(.nasalization(size: 10))
                .foregroundColor(MatrixColors.textSecondary)
                .lineLimit(2)

            // Stats row
            HStack(spacing: 20) {
                StatItem(icon: "person.fill", value: formatNumber(conflict.casualties), label: "Casualties")
                StatItem(icon: "figure.walk.departure", value: "\(String(format: "%.1f", conflict.displaced))M", label: "Displaced")
            }

            Divider()
                .background(MatrixColors.borderGreen.opacity(0.3))

            // Footer
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(MatrixColors.matrixCyan)
                    .font(.system(size: 10))
                Text(conflict.region)
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.textSecondary)

                Spacer()

                Image(systemName: "calendar")
                    .foregroundColor(MatrixColors.textDim)
                    .font(.system(size: 10))
                Text("Since \(conflict.startDate)")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.textDim)

                Text(conflict.parties.first ?? "")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.critical.opacity(0.8))
                    .lineLimit(1)
            }
        }
        .padding(16)
        .background(MatrixColors.overlayBackground)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(conflict.threatLevel.color.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: conflict.threatLevel.color.opacity(0.2), radius: 10)
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

// MARK: - Stat Item
struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(MatrixColors.textDim)
                .font(.system(size: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.nasalization(size: 14))
                    .foregroundColor(MatrixColors.textPrimary)
                Text(label)
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            }
        }
    }
}
