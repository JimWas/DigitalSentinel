//
//  MatrixRainEffect.swift
//  Digital Sentinel
//
//  Animated Matrix-style falling code rain effect
//

import SwiftUI

// MARK: - Matrix Rain Character
struct MatrixCharacter: Identifiable {
    let id = UUID()
    var character: String
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var opacity: Double
    var fontSize: CGFloat

    static let characters = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF@#$%&*<>[]{}|/\\~`"

    static func random(in size: CGSize) -> MatrixCharacter {
        let chars = Array(characters)
        return MatrixCharacter(
            character: String(chars.randomElement()!),
            x: CGFloat.random(in: 0...size.width),
            y: CGFloat.random(in: -size.height...0),
            speed: CGFloat.random(in: 2...8),
            opacity: Double.random(in: 0.1...0.5),
            fontSize: CGFloat.random(in: 10...16)
        )
    }

    mutating func update(in size: CGSize) {
        y += speed

        // Randomly change character
        if Double.random(in: 0...1) > 0.9 {
            let chars = Array(Self.characters)
            character = String(chars.randomElement()!)
        }

        // Reset when off screen
        if y > size.height {
            y = -20
            x = CGFloat.random(in: 0...size.width)
            speed = CGFloat.random(in: 2...8)
            opacity = Double.random(in: 0.1...0.5)
        }
    }
}

// MARK: - Matrix Rain View
struct MatrixRainView: View {
    @State private var characters: [MatrixCharacter] = []
    @State private var timer: Timer?
    let density: Int
    let speed: Double

    init(density: Int = 50, speed: Double = 1.0) {
        self.density = density
        self.speed = speed
    }

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for char in characters {
                    let point = CGPoint(x: char.x, y: char.y)
                    context.opacity = char.opacity
                    context.draw(
                        Text(char.character)
                            .font(.system(size: char.fontSize, weight: .medium, design: .monospaced))
                            .foregroundColor(MatrixColors.matrixGreen),
                        at: point
                    )
                }
            }
            .onAppear {
                initializeCharacters(size: geometry.size)
                startAnimation(size: geometry.size)
            }
            .onDisappear {
                timer?.invalidate()
            }
            .onChange(of: geometry.size) { _, newSize in
                initializeCharacters(size: newSize)
            }
        }
        .allowsHitTesting(false)
    }

    private func initializeCharacters(size: CGSize) {
        characters = (0..<density).map { _ in
            MatrixCharacter.random(in: size)
        }
    }

    private func startAnimation(size: CGSize) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05 / speed, repeats: true) { _ in
            for i in characters.indices {
                characters[i].update(in: size)
            }
        }
    }
}

// MARK: - Matrix Rain Column
struct MatrixRainColumn: View {
    let columnIndex: Int
    let totalColumns: Int

    @State private var characters: [String] = []
    @State private var offset: CGFloat = 0
    @State private var isAnimating = false

    private let matrixChars = "アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン0123456789ABCDEF"

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                ForEach(0..<30, id: \.self) { index in
                    Text(characters.indices.contains(index) ? characters[index] : " ")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(
                            MatrixColors.matrixGreen
                                .opacity(Double(30 - index) / 30.0 * 0.6)
                        )
                }
            }
            .offset(y: offset)
            .onAppear {
                generateCharacters()
                startAnimation(height: geometry.size.height)
            }
        }
    }

    private func generateCharacters() {
        characters = (0..<30).map { _ in
            String(Array(matrixChars).randomElement()!)
        }
    }

    private func startAnimation(height: CGFloat) {
        let delay = Double.random(in: 0...2)
        let duration = Double.random(in: 3...6)

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(
                Animation.linear(duration: duration)
                    .repeatForever(autoreverses: false)
            ) {
                offset = height + 400
            }
        }

        // Regenerate characters periodically
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            if Int.random(in: 0...10) > 7 {
                let randomIndex = Int.random(in: 0..<characters.count)
                characters[randomIndex] = String(Array(matrixChars).randomElement()!)
            }
        }
    }
}

// MARK: - Simplified Matrix Background
struct MatrixBackground: View {
    let columns: Int

    init(columns: Int = 30) {
        self.columns = columns
    }

    var body: some View {
        GeometryReader { geometry in
            let columnWidth = geometry.size.width / CGFloat(columns)

            ZStack {
                MatrixColors.darkBackground

                HStack(spacing: 0) {
                    ForEach(0..<columns, id: \.self) { index in
                        MatrixRainColumn(columnIndex: index, totalColumns: columns)
                            .frame(width: columnWidth)
                    }
                }
                .opacity(0.15)

                // Gradient overlay for depth
                LinearGradient(
                    colors: [
                        MatrixColors.darkBackground,
                        MatrixColors.darkBackground.opacity(0.7),
                        MatrixColors.darkBackground.opacity(0.5),
                        MatrixColors.darkBackground.opacity(0.7),
                        MatrixColors.darkBackground
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Static Matrix Texture
struct MatrixTexture: View {
    var body: some View {
        Canvas { context, size in
            let chars = "01"
            for _ in 0..<200 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let char = String(chars.randomElement()!)

                context.opacity = Double.random(in: 0.02...0.08)
                context.draw(
                    Text(char)
                        .font(.system(size: CGFloat.random(in: 8...12), design: .monospaced))
                        .foregroundColor(MatrixColors.matrixGreen),
                    at: CGPoint(x: x, y: y)
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Grid Overlay
struct GridOverlay: View {
    let spacing: CGFloat
    let lineWidth: CGFloat
    let color: Color

    init(spacing: CGFloat = 50, lineWidth: CGFloat = 0.5, color: Color = MatrixColors.borderGreen.opacity(0.1)) {
        self.spacing = spacing
        self.lineWidth = lineWidth
        self.color = color
    }

    var body: some View {
        Canvas { context, size in
            // Vertical lines
            for x in stride(from: 0, to: size.width, by: spacing) {
                let path = Path { p in
                    p.move(to: CGPoint(x: x, y: 0))
                    p.addLine(to: CGPoint(x: x, y: size.height))
                }
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }

            // Horizontal lines
            for y in stride(from: 0, to: size.height, by: spacing) {
                let path = Path { p in
                    p.move(to: CGPoint(x: 0, y: y))
                    p.addLine(to: CGPoint(x: size.width, y: y))
                }
                context.stroke(path, with: .color(color), lineWidth: lineWidth)
            }
        }
        .allowsHitTesting(false)
    }
}
