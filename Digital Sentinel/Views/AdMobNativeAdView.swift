//
//  AdMobNativeAdView.swift
//  Digital Sentinel
//
//  Native ad slot with periodic refresh
//

import SwiftUI
import GoogleMobileAds

final class NativeAdViewModel: NSObject, ObservableObject, GADNativeAdLoaderDelegate {
    @Published var nativeAd: GADNativeAd?

    private var adLoader: GADAdLoader?
    private var refreshTimer: Timer?

    func load() {
        let adLoader = GADAdLoader(
            adUnitID: "ca-app-pub-3057383894764696/9773521306",
            rootViewController: UIApplication.shared.topMostViewController(),
            adTypes: [.native],
            options: nil
        )
        self.adLoader = adLoader
        adLoader.delegate = self
        adLoader.load(GADRequest())
    }

    func startAutoRefresh() {
        refreshTimer?.invalidate()
        scheduleNextRefresh()
    }

    private func scheduleNextRefresh() {
        let delay = TimeInterval(Int.random(in: 25...60))
        refreshTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.load()
            self?.scheduleNextRefresh()
        }
    }

    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        self.nativeAd = nativeAd
    }

    deinit {
        refreshTimer?.invalidate()
    }
}

struct NativeAdSlotView: View {
    @StateObject private var model = NativeAdViewModel()

    var body: some View {
        Group {
            if let ad = model.nativeAd {
                NativeAdContainer(ad: ad)
                    .frame(height: 120)
            } else {
                NativeAdPlaceholder()
                    .frame(height: 120)
            }
        }
        .onAppear {
            model.load()
            model.startAutoRefresh()
        }
    }
}

struct NativeAdContainer: UIViewRepresentable {
    let ad: GADNativeAd

    func makeUIView(context: Context) -> GADNativeAdView {
        let adView = GADNativeAdView()
        adView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        adView.layer.cornerRadius = 8
        adView.clipsToBounds = true

        let headline = UILabel()
        headline.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        headline.textColor = UIColor.white

        let body = UILabel()
        body.font = UIFont.systemFont(ofSize: 10)
        body.textColor = UIColor(white: 0.7, alpha: 1)
        body.numberOfLines = 2

        let callToAction = UIButton(type: .system)
        callToAction.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        callToAction.setTitleColor(.black, for: .normal)
        callToAction.backgroundColor = UIColor(red: 0, green: 1, blue: 0.4, alpha: 1)
        callToAction.layer.cornerRadius = 4
        callToAction.contentEdgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 6
        iconView.clipsToBounds = true

        let stack = UIStackView(arrangedSubviews: [headline, body, callToAction])
        stack.axis = .vertical
        stack.spacing = 6

        let hStack = UIStackView(arrangedSubviews: [iconView, stack])
        hStack.axis = .horizontal
        hStack.spacing = 8
        hStack.alignment = .center

        adView.addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: adView.leadingAnchor, constant: 12),
            hStack.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -12),
            hStack.topAnchor.constraint(equalTo: adView.topAnchor, constant: 10),
            hStack.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -10)
        ])

        adView.headlineView = headline
        adView.bodyView = body
        adView.callToActionView = callToAction
        adView.iconView = iconView

        adView.nativeAd = ad

        return adView
    }

    func updateUIView(_ uiView: GADNativeAdView, context: Context) {
        (uiView.headlineView as? UILabel)?.text = ad.headline
        (uiView.bodyView as? UILabel)?.text = ad.body
        (uiView.callToActionView as? UIButton)?.setTitle(ad.callToAction, for: .normal)
        (uiView.iconView as? UIImageView)?.image = ad.icon?.image
        uiView.callToActionView?.isHidden = ad.callToAction == nil
        uiView.iconView?.isHidden = ad.icon == nil
        uiView.nativeAd = ad
    }
}

struct NativeAdPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(MatrixColors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(MatrixColors.borderGreen.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                Text("SPONSORED")
                    .font(.nasalization(size: 8))
                    .foregroundColor(MatrixColors.textDim)
            )
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
