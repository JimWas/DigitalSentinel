//
//  IconExportView.swift
//  Digital Sentinel
//
//  Utility view to preview and export the app icon
//

import SwiftUI

struct IconExportView: View {
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            MatrixColors.darkBackground
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(MatrixColors.matrixGreen)
                            .padding(12)
                            .background(MatrixColors.cardBackground)
                            .cornerRadius(8)
                    }
                    Spacer()
                    Text("APP ICON")
                        .font(.nasalization(size: 16))
                        .foregroundColor(MatrixColors.matrixGreen)
                    Spacer()
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.horizontal)

                Spacer()

                // Large icon preview
                AppIconView(size: 300)
                    .shadow(color: MatrixColors.matrixGreen.opacity(0.3), radius: 20)

                Text("1024 x 1024 px")
                    .font(.nasalization(size: 12))
                    .foregroundColor(MatrixColors.textSecondary)

                Spacer()

                // Size previews
                HStack(spacing: 24) {
                    IconSizePreview(size: 120, label: "App Store")
                    IconSizePreview(size: 60, label: "iPhone")
                    IconSizePreview(size: 40, label: "Settings")
                }

                Spacer()

                // Export button
                Button(action: exportIcon) {
                    HStack(spacing: 10) {
                        Image(systemName: "square.and.arrow.down")
                        Text("SAVE TO PHOTOS")
                            .font(.nasalization(size: 12))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 14)
                    .background(MatrixColors.matrixGreen)
                    .cornerRadius(8)
                }

                Text("Save the icon, then add it to\nAssets.xcassets/AppIcon")
                    .font(.nasalization(size: 9))
                    .foregroundColor(MatrixColors.textDim)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 20)
            }
            .padding()
        }
        .alert("Icon Export", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveMessage)
        }
    }

    @MainActor
    private func exportIcon() {
        let iconView = AppIconView(size: 1024)
        let renderer = ImageRenderer(content: iconView)
        renderer.scale = 1.0

        if let image = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            saveMessage = "Icon saved to Photos! Add it to your Xcode project's AppIcon asset."
            showingSaveAlert = true
        } else {
            saveMessage = "Failed to generate icon."
            showingSaveAlert = true
        }
    }
}

struct IconSizePreview: View {
    let size: CGFloat
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            AppIconView(size: size)
                .shadow(color: .black.opacity(0.3), radius: 4)

            Text(label)
                .font(.nasalization(size: 8))
                .foregroundColor(MatrixColors.textDim)
        }
    }
}

// MARK: - Icon Preview Button for Main UI
struct IconPreviewButton: View {
    @State private var showingIconExport = false

    var body: some View {
        Button(action: { showingIconExport = true }) {
            HStack(spacing: 6) {
                Image(systemName: "app.badge")
                    .font(.system(size: 12))
                Text("Icon")
                    .font(.nasalization(size: 10))
            }
            .foregroundColor(MatrixColors.matrixCyan)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(MatrixColors.cardBackground)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(MatrixColors.matrixCyan.opacity(0.3), lineWidth: 1)
            )
        }
        .fullScreenCover(isPresented: $showingIconExport) {
            IconExportView()
        }
    }
}

#Preview {
    IconExportView()
}
