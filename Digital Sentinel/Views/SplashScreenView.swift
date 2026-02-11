//
//  SplashScreenView.swift
//  Digital Sentinel
//
//  Animated splash screen with matrix effect
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showContent = false
    @State private var loadingProgress: CGFloat = 0
    @State private var statusText = "INITIALIZING SYSTEM..."

    let statusMessages = [
        "INITIALIZING SYSTEM...",
        "CONNECTING TO SATELLITES...",
        "LOADING THREAT DATABASE...",
        "ANALYZING GLOBAL DATA...",
        "ESTABLISHING SECURE CONNECTION...",
        "SYSTEM READY"
    ]

    var body: some View {
        ZStack {
            // Background
            MatrixColors.darkBackground
                .ignoresSafeArea()

            // Matrix rain
            MatrixRainView(density: 60, speed: 1.2)
                .opacity(0.3)
                .ignoresSafeArea()

            // Content
            VStack(spacing: 30) {
                Spacer()

                // Logo
                ZStack {
                    // Outer rotating ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [MatrixColors.matrixGreen, MatrixColors.matrixGreen.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))

                    // Middle ring
                    Circle()
                        .stroke(MatrixColors.matrixCyan.opacity(0.5), lineWidth: 1)
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(isAnimating ? -360 : 0))

                    // Inner ring
                    Circle()
                        .stroke(MatrixColors.matrixGreen.opacity(0.8), lineWidth: 1)
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 180 : 0))

                    // Globe icon
                    Image(systemName: "globe")
                        .font(.system(size: 40, weight: .thin))
                        .foregroundColor(MatrixColors.matrixGreen)
                        .shadow(color: MatrixColors.matrixGreen.opacity(0.8), radius: 10)

                    // Scanning effect
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    MatrixColors.matrixGreen.opacity(0),
                                    MatrixColors.matrixGreen.opacity(0.3),
                                    MatrixColors.matrixGreen.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 100, height: 10)
                        .offset(y: isAnimating ? 50 : -50)
                        .mask(
                            Circle()
                                .frame(width: 100, height: 100)
                        )
                }

                // Title
                VStack(spacing: 8) {
                    Text("DIGITAL SENTINEL")
                        .font(.nasalization(size: 28))
                        .foregroundColor(MatrixColors.matrixGreen)
                        .shadow(color: MatrixColors.matrixGreen.opacity(0.5), radius: 10)

                    Text("GLOBAL CONFLICT MONITOR")
                        .font(.nasalization(size: 12))
                        .foregroundColor(MatrixColors.matrixCyan)
                        .tracking(4)
                }

                Spacer()

                // Loading section
                VStack(spacing: 16) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(MatrixColors.cardBackground)
                                .frame(height: 4)

                            // Progress
                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [MatrixColors.matrixGreen.opacity(0.5), MatrixColors.matrixGreen],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * loadingProgress, height: 4)
                                .shadow(color: MatrixColors.matrixGreen, radius: 4)
                        }
                        .cornerRadius(2)
                    }
                    .frame(height: 4)
                    .padding(.horizontal, 60)

                    // Status text
                    Text(statusText)
                        .font(.nasalization(size: 10))
                        .foregroundColor(MatrixColors.textSecondary)
                        .animation(.none, value: statusText)
                }

                // Version info
                HStack(spacing: 20) {
                    Text("v1.0.0")
                        .font(.nasalization(size: 8))
                        .foregroundColor(MatrixColors.textDim)

                    Text("•")
                        .foregroundColor(MatrixColors.textDim)

                    Text("CLASSIFIED")
                        .font(.nasalization(size: 8))
                        .foregroundColor(MatrixColors.critical.opacity(0.7))
                }
                .padding(.bottom, 40)
            }

            // Scanlines
            ScanlineEffect()
                .ignoresSafeArea()
        }
        .onAppear {
            startAnimations()
        }
    }

    private func startAnimations() {
        // Rotation animation
        withAnimation(
            Animation.linear(duration: 8)
                .repeatForever(autoreverses: false)
        ) {
            isAnimating = true
        }

        // Loading progress animation
        animateLoading()
    }

    private func animateLoading() {
        let totalDuration: Double = 3.0
        let steps = statusMessages.count

        for (index, message) in statusMessages.enumerated() {
            let delay = (totalDuration / Double(steps)) * Double(index)

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    statusText = message
                    loadingProgress = CGFloat(index + 1) / CGFloat(steps)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.5) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
}

// MARK: - Boot Text View
struct BootTextView: View {
    @State private var visibleLines: [String] = []

    let bootMessages = [
        "> Initializing secure connection...",
        "> Loading threat intelligence database...",
        "> Establishing satellite uplink...",
        "> Decrypting classified data streams...",
        "> Verifying security protocols...",
        "> System operational."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(visibleLines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(MatrixColors.matrixGreen.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .onAppear {
            animateBootText()
        }
    }

    private func animateBootText() {
        for (index, message) in bootMessages.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                withAnimation(.easeIn(duration: 0.1)) {
                    visibleLines.append(message)
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
