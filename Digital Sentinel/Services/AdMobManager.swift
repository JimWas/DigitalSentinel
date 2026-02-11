//
//  AdMobManager.swift
//  Digital Sentinel
//
//  AdMob configuration and interstitial scheduling
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class AdMobManager: NSObject, ObservableObject {
    static let shared = AdMobManager()

    private var interstitial: GADInterstitialAd?
    private var interstitialTimer: Timer?
    private var isPresenting = false

    private override init() {}

    func configure(testAdsEnabled: Bool) {
        if testAdsEnabled {
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
        }

        GADMobileAds.sharedInstance().start { _ in }
        scheduleInterstitial()
    }

    func scheduleInterstitial() {
        interstitialTimer?.invalidate()
        let delay = TimeInterval(Int.random(in: 120...300))
        interstitialTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.loadAndShowInterstitial()
                self?.scheduleInterstitial()
            }
        }
    }

    func loadAndShowInterstitial() async {
        guard UIApplication.shared.applicationState == .active else { return }

        do {
            let request = GADRequest()
            interstitial = try await GADInterstitialAd.load(
                withAdUnitID: "ca-app-pub-3057383894764696/6512933146",
                request: request
            )
            interstitial?.fullScreenContentDelegate = self
            presentInterstitialIfPossible()
        } catch {
            // Silent fail; will retry on next schedule
        }
    }

    private func presentInterstitialIfPossible() {
        guard !isPresenting else { return }
        guard let interstitial else { return }
        guard let root = UIApplication.shared.topMostViewController() else { return }

        isPresenting = true
        interstitial.present(fromRootViewController: root)
    }
}

extension AdMobManager: GADFullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        isPresenting = false
        interstitial = nil
    }

    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        isPresenting = false
        interstitial = nil
    }
}

private extension UIApplication {
    func topMostViewController() -> UIViewController? {
        guard let root = connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first?.rootViewController else {
            return nil
        }
        return root.topMostViewController()
    }
}

private extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}
