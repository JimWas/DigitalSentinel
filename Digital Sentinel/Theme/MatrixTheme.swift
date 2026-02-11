//
//  MatrixTheme.swift
//  Digital Sentinel
//
//  Matrix/Hacker Theme Constants and Utilities
//

import SwiftUI

// MARK: - Matrix Colors
struct MatrixColors {
    // Primary matrix green shades
    static let matrixGreen = Color(red: 0.0, green: 1.0, blue: 0.4)
    static let matrixGreenDim = Color(red: 0.0, green: 0.7, blue: 0.3)
    static let matrixGreenBright = Color(red: 0.2, green: 1.0, blue: 0.5)

    // Cyan accents
    static let matrixCyan = Color(red: 0.0, green: 0.9, blue: 0.9)
    static let matrixCyanDim = Color(red: 0.0, green: 0.6, blue: 0.6)

    // Background colors
    static let darkBackground = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let cardBackground = Color(red: 0.05, green: 0.05, blue: 0.08)
    static let panelBackground = Color(red: 0.04, green: 0.04, blue: 0.07)
    static let overlayBackground = Color(red: 0.03, green: 0.03, blue: 0.06).opacity(0.95)

    // Threat level colors
    static let critical = Color(red: 1.0, green: 0.2, blue: 0.2)
    static let high = Color(red: 1.0, green: 0.5, blue: 0.0)
    static let medium = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let low = Color(red: 0.0, green: 0.8, blue: 0.4)

    // UI element colors
    static let borderGreen = Color(red: 0.0, green: 0.5, blue: 0.2)
    static let textPrimary = Color(red: 0.9, green: 0.95, blue: 0.9)
    static let textSecondary = Color(red: 0.5, green: 0.6, blue: 0.5)
    static let textDim = Color(red: 0.3, green: 0.4, blue: 0.3)

    // Glow colors
    static let glowGreen = Color(red: 0.0, green: 1.0, blue: 0.4).opacity(0.6)
    static let glowCyan = Color(red: 0.0, green: 0.9, blue: 0.9).opacity(0.5)
    static let glowRed = Color(red: 1.0, green: 0.2, blue: 0.2).opacity(0.6)
}

// MARK: - Custom Font Extension
extension Font {
    static func nasalization(size: CGFloat) -> Font {
        .custom("Nasalization", size: size)
    }

    static func nasalizationRg(size: CGFloat) -> Font {
        .custom("Nasalization-Rg", size: size)
    }

    // Fallback to system font with similar styling
    static func matrixFont(size: CGFloat) -> Font {
        .custom("Nasalization", size: size)
    }

    static func matrixFontBold(size: CGFloat) -> Font {
        .custom("Nasalization", size: size).weight(.bold)
    }

    // Preset sizes
    static var matrixTitle: Font { .nasalization(size: 24) }
    static var matrixHeadline: Font { .nasalization(size: 18) }
    static var matrixSubheadline: Font { .nasalization(size: 14) }
    static var matrixBody: Font { .nasalization(size: 12) }
    static var matrixCaption: Font { .nasalization(size: 10) }
    static var matrixMicro: Font { .nasalization(size: 8) }
}

// MARK: - Matrix Text Styles
struct MatrixTextStyle: ViewModifier {
    var size: CGFloat = 12
    var color: Color = MatrixColors.matrixGreen
    var glow: Bool = false

    func body(content: Content) -> some View {
        content
            .font(.nasalization(size: size))
            .foregroundColor(color)
            .shadow(color: glow ? color.opacity(0.8) : .clear, radius: glow ? 4 : 0)
    }
}

extension View {
    func matrixText(size: CGFloat = 12, color: Color = MatrixColors.matrixGreen, glow: Bool = false) -> some View {
        modifier(MatrixTextStyle(size: size, color: color, glow: glow))
    }
}

// MARK: - Matrix Card Style
struct MatrixCardStyle: ViewModifier {
    var borderColor: Color = MatrixColors.borderGreen
    var glowing: Bool = false

    func body(content: Content) -> some View {
        content
            .background(MatrixColors.cardBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor.opacity(0.5), lineWidth: 1)
            )
            .shadow(color: glowing ? borderColor.opacity(0.3) : .clear, radius: glowing ? 8 : 0)
    }
}

extension View {
    func matrixCard(borderColor: Color = MatrixColors.borderGreen, glowing: Bool = false) -> some View {
        modifier(MatrixCardStyle(borderColor: borderColor, glowing: glowing))
    }
}

// MARK: - Scanline Effect
struct ScanlineEffect: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for y in stride(from: 0, to: size.height, by: 3) {
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1)
                    context.fill(Path(rect), with: .color(.black.opacity(0.15)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Pulse Animation
struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false
    let intensity: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.0 + (0.2 * intensity) : 1.0)
            .opacity(isPulsing ? 1.0 : 0.7)
            .animation(
                Animation.easeInOut(duration: 1.0 + (1.0 - intensity))
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

extension View {
    func pulseAnimation(intensity: Double = 0.5) -> some View {
        modifier(PulseAnimation(intensity: intensity))
    }
}

// MARK: - Glitch Effect
struct GlitchText: View {
    let text: String
    let font: Font
    @State private var glitchOffset: CGFloat = 0
    @State private var showGlitch = false

    var body: some View {
        ZStack {
            Text(text)
                .font(font)
                .foregroundColor(MatrixColors.matrixCyan.opacity(0.5))
                .offset(x: showGlitch ? -2 : 0)

            Text(text)
                .font(font)
                .foregroundColor(MatrixColors.critical.opacity(0.5))
                .offset(x: showGlitch ? 2 : 0)

            Text(text)
                .font(font)
                .foregroundColor(MatrixColors.matrixGreen)
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                if Double.random(in: 0...1) > 0.95 {
                    showGlitch = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        showGlitch = false
                    }
                }
            }
        }
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: ConflictStatus
    @State private var isAnimating = false

    var statusColor: Color {
        switch status {
        case .active: return MatrixColors.critical
        case .escalating: return MatrixColors.high
        case .deescalating: return MatrixColors.matrixGreen
        case .monitoring: return MatrixColors.matrixCyan
        case .ceasefire: return MatrixColors.low
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
                .scaleEffect(isAnimating && (status == .active || status == .escalating) ? 1.3 : 1.0)
                .opacity(isAnimating && (status == .active || status == .escalating) ? 0.6 : 1.0)
                .animation(
                    Animation.easeInOut(duration: 0.8)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )

            Text(status.rawValue)
                .font(.nasalization(size: 9))
                .foregroundColor(statusColor)
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - Threat Badge
struct ThreatBadge: View {
    let level: ThreatLevel

    var body: some View {
        Text(level.rawValue.uppercased())
            .font(.nasalization(size: 8))
            .foregroundColor(.black)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(level.color)
            .cornerRadius(3)
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let color: Color
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.nasalization(size: 18))
                .foregroundColor(color)
                .shadow(color: isHighlighted ? color.opacity(0.5) : .clear, radius: 4)

            Text(label.uppercased())
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(MatrixColors.cardBackground.opacity(0.8))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(color.opacity(isHighlighted ? 0.6 : 0.3), lineWidth: 1)
        )
    }
}

// MARK: - Progress Bar
struct MatrixProgressBar: View {
    let value: Double
    let maxValue: Double
    let label: String
    let color: Color

    private var progress: Double {
        min(value / maxValue, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label.uppercased())
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.textSecondary)

                Spacer()

                Text("\(Int(value))")
                    .font(.nasalization(size: 11))
                    .foregroundColor(color)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(MatrixColors.cardBackground)
                        .frame(height: 4)

                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.8), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 4)
                        .shadow(color: color.opacity(0.5), radius: 2)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
    }
}
