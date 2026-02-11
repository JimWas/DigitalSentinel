//
//  Digital_SentinelApp.swift
//  Digital Sentinel
//
//  Global Conflict Monitor - A Palantir-style intelligence dashboard
//

import SwiftUI

@main
struct Digital_SentinelApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                AdMobManager.shared.configure(testAdsEnabled: true)
                // Show splash for 3.5 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}
