//
//  AppIconGenerator.swift
//  Digital Sentinel
//
//  Generates a hacker-style app icon programmatically
//

import SwiftUI

// MARK: - App Icon View
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background gradient
            RadialGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.05),
                    Color(red: 0.02, green: 0.02, blue: 0.02)
                ],
                center: .center,
                startRadius: 0,
                endRadius: size * 0.7
            )

            // Circuit pattern background
            CircuitPatternView(size: size)
                .opacity(0.3)

            // Matrix rain columns (subtle)
            MatrixRainIconView(size: size)
                .opacity(0.15)

            // Outer glow ring
            Circle()
                .stroke(
                    RadialGradient(
                        colors: [
                            Color(red: 0, green: 1, blue: 0.4).opacity(0.8),
                            Color(red: 0, green: 1, blue: 0.4).opacity(0)
                        ],
                        center: .center,
                        startRadius: size * 0.3,
                        endRadius: size * 0.45
                    ),
                    lineWidth: size * 0.08
                )
                .frame(width: size * 0.75, height: size * 0.75)
                .blur(radius: size * 0.02)

            // Tech ring
            TechRingView(size: size)

            // Central globe
            GlobeIconView(size: size)

            // Scanning beam
            ScanningBeamView(size: size)

            // Corner brackets
            CornerBracketsView(size: size)

            // HUD elements
            HUDElementsView(size: size)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
    }
}

// MARK: - Circuit Pattern
struct CircuitPatternView: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let gridSize = size / 12
            let lineColor = Color(red: 0, green: 0.5, blue: 0.2)

            // Horizontal lines
            for i in 0..<13 {
                let y = CGFloat(i) * gridSize
                if Int.random(in: 0...2) == 0 {
                    var path = Path()
                    let startX = CGFloat.random(in: 0...(size * 0.3))
                    let endX = CGFloat.random(in: (size * 0.7)...size)
                    path.move(to: CGPoint(x: startX, y: y))
                    path.addLine(to: CGPoint(x: endX, y: y))
                    context.stroke(path, with: .color(lineColor), lineWidth: 1)

                    // Add nodes
                    let nodeX = CGFloat.random(in: startX...endX)
                    let nodeRect = CGRect(x: nodeX - 2, y: y - 2, width: 4, height: 4)
                    context.fill(Path(ellipseIn: nodeRect), with: .color(lineColor))
                }
            }

            // Vertical lines
            for i in 0..<13 {
                let x = CGFloat(i) * gridSize
                if Int.random(in: 0...2) == 0 {
                    var path = Path()
                    let startY = CGFloat.random(in: 0...(size * 0.3))
                    let endY = CGFloat.random(in: (size * 0.7)...size)
                    path.move(to: CGPoint(x: x, y: startY))
                    path.addLine(to: CGPoint(x: x, y: endY))
                    context.stroke(path, with: .color(lineColor), lineWidth: 1)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Matrix Rain for Icon
struct MatrixRainIconView: View {
    let size: CGFloat
    let chars = "01アイウエオカキクケコ"

    var body: some View {
        Canvas { context, canvasSize in
            let columns = 12
            let columnWidth = size / CGFloat(columns)

            for col in 0..<columns {
                let x = CGFloat(col) * columnWidth + columnWidth / 2
                let charCount = Int.random(in: 3...8)
                let startY = CGFloat.random(in: 0...(size * 0.5))

                for i in 0..<charCount {
                    let y = startY + CGFloat(i) * (size * 0.08)
                    if y < size {
                        let char = String(chars.randomElement()!)
                        let opacity = 1.0 - (Double(i) / Double(charCount))

                        context.opacity = opacity * 0.6
                        context.draw(
                            Text(char)
                                .font(.system(size: size * 0.06, weight: .bold, design: .monospaced))
                                .foregroundColor(Color(red: 0, green: 1, blue: 0.4)),
                            at: CGPoint(x: x, y: y)
                        )
                    }
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tech Ring
struct TechRingView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Outer dashed ring
            Circle()
                .stroke(
                    Color(red: 0, green: 0.8, blue: 0.3),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )
                .frame(width: size * 0.82, height: size * 0.82)
                .opacity(0.5)

            // Segmented ring
            ForEach(0..<12, id: \.self) { i in
                RingSegment(
                    startAngle: Double(i) * 30,
                    endAngle: Double(i) * 30 + 20,
                    radius: size * 0.38,
                    thickness: size * 0.015
                )
                .fill(Color(red: 0, green: 1, blue: 0.4).opacity(i % 3 == 0 ? 0.8 : 0.4))
            }

            // Tick marks
            ForEach(0..<36, id: \.self) { i in
                Rectangle()
                    .fill(Color(red: 0, green: 0.7, blue: 0.3))
                    .frame(width: 1, height: i % 3 == 0 ? size * 0.03 : size * 0.015)
                    .offset(y: -size * 0.35)
                    .rotationEffect(.degrees(Double(i) * 10))
                    .opacity(0.6)
            }
        }
    }
}

struct RingSegment: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: CGFloat
    let thickness: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle - 90),
            endAngle: .degrees(endAngle - 90),
            clockwise: false
        )

        return path.strokedPath(StrokeStyle(lineWidth: thickness, lineCap: .round))
    }
}

// MARK: - Globe Icon
struct GlobeIconView: View {
    let size: CGFloat
    let matrixGreen = Color(red: 0, green: 1, blue: 0.4)

    var body: some View {
        ZStack {
            // Globe background glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            matrixGreen.opacity(0.3),
                            matrixGreen.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.25
                    )
                )
                .frame(width: size * 0.5, height: size * 0.5)

            // Globe outline
            Circle()
                .stroke(matrixGreen, lineWidth: size * 0.012)
                .frame(width: size * 0.4, height: size * 0.4)

            // Latitude lines
            ForEach([-0.3, 0.0, 0.3], id: \.self) { offset in
                Ellipse()
                    .stroke(matrixGreen.opacity(0.6), lineWidth: size * 0.006)
                    .frame(width: size * 0.4, height: size * 0.12)
                    .offset(y: size * CGFloat(offset) * 0.4)
            }

            // Longitude lines
            Ellipse()
                .stroke(matrixGreen.opacity(0.6), lineWidth: size * 0.006)
                .frame(width: size * 0.2, height: size * 0.4)

            Ellipse()
                .stroke(matrixGreen.opacity(0.6), lineWidth: size * 0.006)
                .frame(width: size * 0.35, height: size * 0.4)

            // Vertical center line
            Rectangle()
                .fill(matrixGreen.opacity(0.5))
                .frame(width: size * 0.004, height: size * 0.4)

            // Horizontal center line
            Rectangle()
                .fill(matrixGreen.opacity(0.5))
                .frame(width: size * 0.4, height: size * 0.004)

            // Threat dots on globe
            Circle()
                .fill(Color.red)
                .frame(width: size * 0.025, height: size * 0.025)
                .offset(x: size * 0.05, y: -size * 0.08)
                .shadow(color: .red, radius: size * 0.01)

            Circle()
                .fill(Color.orange)
                .frame(width: size * 0.02, height: size * 0.02)
                .offset(x: -size * 0.1, y: size * 0.02)
                .shadow(color: .orange, radius: size * 0.008)

            Circle()
                .fill(Color.red)
                .frame(width: size * 0.018, height: size * 0.018)
                .offset(x: size * 0.08, y: size * 0.06)
                .shadow(color: .red, radius: size * 0.008)

            Circle()
                .fill(Color.yellow)
                .frame(width: size * 0.015, height: size * 0.015)
                .offset(x: -size * 0.05, y: -size * 0.1)
                .shadow(color: .yellow, radius: size * 0.006)
        }
    }
}

// MARK: - Scanning Beam
struct ScanningBeamView: View {
    let size: CGFloat

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0, green: 1, blue: 0.4).opacity(0),
                        Color(red: 0, green: 1, blue: 0.4).opacity(0.4),
                        Color(red: 0, green: 1, blue: 0.4).opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size * 0.38, height: size * 0.008)
            .offset(y: -size * 0.05)
    }
}

// MARK: - Corner Brackets
struct CornerBracketsView: View {
    let size: CGFloat
    let bracketColor = Color(red: 0, green: 0.8, blue: 0.3)

    var body: some View {
        ZStack {
            // Top-left
            BracketShape()
                .stroke(bracketColor, lineWidth: size * 0.012)
                .frame(width: size * 0.12, height: size * 0.12)
                .position(x: size * 0.12, y: size * 0.12)

            // Top-right
            BracketShape()
                .stroke(bracketColor, lineWidth: size * 0.012)
                .frame(width: size * 0.12, height: size * 0.12)
                .rotationEffect(.degrees(90))
                .position(x: size * 0.88, y: size * 0.12)

            // Bottom-left
            BracketShape()
                .stroke(bracketColor, lineWidth: size * 0.012)
                .frame(width: size * 0.12, height: size * 0.12)
                .rotationEffect(.degrees(-90))
                .position(x: size * 0.12, y: size * 0.88)

            // Bottom-right
            BracketShape()
                .stroke(bracketColor, lineWidth: size * 0.012)
                .frame(width: size * 0.12, height: size * 0.12)
                .rotationEffect(.degrees(180))
                .position(x: size * 0.88, y: size * 0.88)
        }
    }
}

struct BracketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

// MARK: - HUD Elements
struct HUDElementsView: View {
    let size: CGFloat
    let hudColor = Color(red: 0, green: 0.9, blue: 0.4)

    var body: some View {
        ZStack {
            // Top label
            Text("SENTINEL")
                .font(.system(size: size * 0.045, weight: .bold, design: .monospaced))
                .foregroundColor(hudColor)
                .position(x: size * 0.5, y: size * 0.07)
                .opacity(0.9)

            // Bottom status
            HStack(spacing: size * 0.02) {
                Circle()
                    .fill(Color.red)
                    .frame(width: size * 0.02, height: size * 0.02)
                Text("ACTIVE")
                    .font(.system(size: size * 0.035, weight: .medium, design: .monospaced))
                    .foregroundColor(hudColor.opacity(0.8))
            }
            .position(x: size * 0.5, y: size * 0.93)

            // Side indicators
            VStack(spacing: size * 0.015) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(hudColor.opacity(i < 3 ? 0.8 : 0.3))
                        .frame(width: size * 0.025, height: size * 0.008)
                }
            }
            .position(x: size * 0.06, y: size * 0.5)

            VStack(spacing: size * 0.015) {
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(hudColor.opacity(i < 2 ? 0.8 : 0.3))
                        .frame(width: size * 0.025, height: size * 0.008)
                }
            }
            .position(x: size * 0.94, y: size * 0.5)
        }
    }
}

// MARK: - Preview & Export Helper
struct AppIconPreview: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Preview")
                .font(.headline)

            // Large preview
            AppIconView(size: 512)
                .shadow(color: .black.opacity(0.5), radius: 20)

            // Size variations
            HStack(spacing: 20) {
                VStack {
                    AppIconView(size: 180)
                    Text("180pt")
                        .font(.caption)
                }
                VStack {
                    AppIconView(size: 120)
                    Text("120pt")
                        .font(.caption)
                }
                VStack {
                    AppIconView(size: 60)
                    Text("60pt")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
    }
}

#Preview {
    AppIconPreview()
}

// MARK: - Icon Export Extension
extension View {
    @MainActor
    func renderAsImage(size: CGSize) -> UIImage? {
        let renderer = ImageRenderer(content: self.frame(width: size.width, height: size.height))
        renderer.scale = 1.0
        return renderer.uiImage
    }
}

// Helper to generate and save the icon
struct IconExporter {
    @MainActor
    static func exportIcon() -> UIImage? {
        let iconView = AppIconView(size: 1024)
        return iconView.renderAsImage(size: CGSize(width: 1024, height: 1024))
    }
}
