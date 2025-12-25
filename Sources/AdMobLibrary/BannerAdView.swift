//
//  BannerAdView.swift
//  AdMobLibrary
//
//  SwiftUI wrapper cho GADBannerView
//

import SwiftUI
import GoogleMobileAds

// MARK: - Banner Ad Size
public enum BannerAdSize {
    case banner           // 320x50
    case largeBanner      // 320x100
    case mediumRectangle  // 300x250
    case fullBanner       // 468x60
    case leaderboard      // 728x90
    case adaptive         // Tự động điều chỉnh theo chiều rộng
    case anchoredAdaptive(width: CGFloat) // Adaptive với chiều rộng cụ thể
    
    var gadAdSize: AdSize {
        switch self {
        case .banner:
            return AdSizeBanner
        case .largeBanner:
            return AdSizeLargeBanner
        case .mediumRectangle:
            return AdSizeMediumRectangle
        case .fullBanner:
            return AdSizeFullBanner
        case .leaderboard:
            return AdSizeLeaderboard
        case .adaptive:
            let width = UIScreen.main.bounds.width
            return currentOrientationAnchoredAdaptiveBanner(width: width)
        case .anchoredAdaptive(let width):
            return currentOrientationAnchoredAdaptiveBanner(width: width)
        }
    }
    
    var height: CGFloat {
        switch self {
        case .banner:
            return 50
        case .largeBanner:
            return 100
        case .mediumRectangle:
            return 250
        case .fullBanner:
            return 60
        case .leaderboard:
            return 90
        case .adaptive, .anchoredAdaptive:
            return gadAdSize.size.height
        }
    }
}

// MARK: - Banner Ad State
@MainActor
public class BannerAdState: ObservableObject {
    @Published public var isLoaded = false
    @Published public var error: Error?
    @Published public var adSize: CGSize = .zero
    
    public init() {}
}

// MARK: - Banner Ad View (SwiftUI)
public struct BannerAdView: View {
    let adUnitID: String?
    let adSize: BannerAdSize
    @StateObject private var adState = BannerAdState()
    
    public init(
        adUnitID: String? = nil,
        adSize: BannerAdSize = .adaptive
    ) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }
    
    public var body: some View {
        BannerAdViewRepresentable(
            adUnitID: adUnitID ?? AdMobManager.shared.adUnitIDs.banner,
            adSize: adSize,
            adState: adState
        )
        .frame(
            width: adSize == .adaptive ? nil : adSize.gadAdSize.size.width,
            height: adState.isLoaded ? adState.adSize.height : adSize.height
        )
    }
}

// MARK: - UIViewRepresentable
struct BannerAdViewRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: BannerAdSize
    @ObservedObject var adState: BannerAdState
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize.gadAdSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        
        // Lấy root view controller
        if let rootViewController = AdMobManager.shared.getRootViewController() {
            bannerView.rootViewController = rootViewController
        }
        
        // Load ad
        let request = AdMobManager.shared.createAdRequest()
        bannerView.load(request)
        
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // Cập nhật root view controller nếu cần
        if uiView.rootViewController == nil {
            uiView.rootViewController = AdMobManager.shared.getRootViewController()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(adState: adState)
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        let adState: BannerAdState
        
        init(adState: BannerAdState) {
            self.adState = adState
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            Task { @MainActor in
                adState.isLoaded = true
                adState.adSize = bannerView.adSize.size
                adState.error = nil
                print("✅ Banner ad loaded successfully")
            }
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor in
                adState.isLoaded = false
                adState.error = error
                print("❌ Banner ad failed to load: \(error.localizedDescription)")
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 Banner ad recorded impression")
        }
        
        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            print("👆 Banner ad recorded click")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: BannerView) {
            print("📱 Banner ad will present screen")
        }
        
        func bannerViewWillDismissScreen(_ bannerView: BannerView) {
            print("📱 Banner ad will dismiss screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: BannerView) {
            print("📱 Banner ad did dismiss screen")
        }
    }
}

// MARK: - Convenience Initializers
public extension BannerAdView {
    /// Tạo banner với kích thước adaptive (khuyến nghị)
    static func adaptive(adUnitID: String? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .adaptive)
    }
    
    /// Tạo banner chuẩn 320x50
    static func standard(adUnitID: String? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .banner)
    }
    
    /// Tạo banner large 320x100
    static func large(adUnitID: String? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .largeBanner)
    }
    
    /// Tạo banner medium rectangle 300x250
    static func mediumRectangle(adUnitID: String? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .mediumRectangle)
    }
}

