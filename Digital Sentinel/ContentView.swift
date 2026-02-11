//
//  ContentView.swift
//  Digital Sentinel
//
//  Main view combining all components for the World Monitor layout
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataManager = ConflictDataManager()
    @State private var selectedConflict: MajorConflict?

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 700

            ZStack {
                // Matrix background
                MatrixBackground(columns: isCompact ? 20 : 40)
                    .ignoresSafeArea()

                WorldMonitorDashboardView(
                    dataManager: dataManager,
                    selectedConflict: $selectedConflict,
                    isCompact: isCompact
                )

                // Scanline overlay
                ScanlineEffect()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .preferredColorScheme(.dark)
        }
    }
}
