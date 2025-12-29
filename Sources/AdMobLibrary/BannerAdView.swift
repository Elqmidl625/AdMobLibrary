//
//  BannerAdView.swift
//  AdMobLibrary
//
//  SwiftUI wrapper cho GADBannerView
//

import SwiftUI
import GoogleMobileAds

// MARK: - Banner Ad Size (đổi tên để tránh xung đột với SDK)
public enum AdBannerSize {
    case banner           // 320x50
    case largeBanner      // 320x100
    case mediumRectangle  // 300x250
    case fullBanner       // 468x60
    case leaderboard      // 728x90
    case adaptive         // Tự động điều chỉnh theo chiều rộng
    case anchoredAdaptive(width: CGFloat) // Adaptive với chiều rộng cụ thể
    
    var gadAdSize: GoogleMobileAds.AdSize {
        switch self {
        case .banner:
            return GoogleMobileAds.AdSizeBanner
        case .largeBanner:
            return GoogleMobileAds.AdSizeLargeBanner
        case .mediumRectangle:
            return GoogleMobileAds.AdSizeMediumRectangle
        case .fullBanner:
            return GoogleMobileAds.AdSizeFullBanner
        case .leaderboard:
            return GoogleMobileAds.AdSizeLeaderboard
        case .adaptive:
            let width = UIScreen.main.bounds.width
            return GoogleMobileAds.currentOrientationAnchoredAdaptiveBanner(width: width)
        case .anchoredAdaptive(let width):
            return GoogleMobileAds.currentOrientationAnchoredAdaptiveBanner(width: width)
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
    
    /// Kiểm tra có phải kích thước adaptive không
    var isAdaptive: Bool {
        switch self {
        case .adaptive, .anchoredAdaptive:
            return true
        default:
            return false
        }
    }
}

// MARK: - Banner Ad State
@MainActor
public class BannerAdState: ObservableObject {
    @Published public var isLoaded = false
    @Published public var error: Error?
    @Published public var adSize: CGSize = .zero
    
    /// Event callbacks
    public var events: BannerAdEvents?
    
    public init(events: BannerAdEvents? = nil) {
        self.events = events
    }
}

// MARK: - Banner Ad View (SwiftUI)
public struct BannerAdView: View {
    let adUnitID: String?
    let adSize: AdBannerSize
    let events: BannerAdEvents?
    @StateObject private var adState = BannerAdState()
    
    public init(
        adUnitID: String? = nil,
        adSize: AdBannerSize = .adaptive,
        events: BannerAdEvents? = nil
    ) {
        self.adUnitID = adUnitID
        self.adSize = adSize
        self.events = events
    }
    
    public var body: some View {
        BannerAdViewRepresentable(
            adUnitID: adUnitID ?? AdMobManager.shared.adUnitIDs.banner,
            adSize: adSize,
            adState: adState,
            events: events
        )
        .frame(
            width: adSize.isAdaptive ? nil : adSize.gadAdSize.size.width,
            height: adState.isLoaded ? adState.adSize.height : adSize.height
        )
    }
}

// MARK: - UIViewRepresentable
struct BannerAdViewRepresentable: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdBannerSize
    @ObservedObject var adState: BannerAdState
    let events: BannerAdEvents?
    
    func makeUIView(context: Context) -> GoogleMobileAds.BannerView {
        let bannerView = GoogleMobileAds.BannerView(adSize: adSize.gadAdSize)
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
    
    func updateUIView(_ uiView: GoogleMobileAds.BannerView, context: Context) {
        // Cập nhật root view controller nếu cần
        if uiView.rootViewController == nil {
            uiView.rootViewController = AdMobManager.shared.getRootViewController()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(adState: adState, events: events)
    }
    
    class Coordinator: NSObject, GoogleMobileAds.BannerViewDelegate {
        let adState: BannerAdState
        let events: BannerAdEvents?
        
        init(adState: BannerAdState, events: BannerAdEvents?) {
            self.adState = adState
            self.events = events
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            Task { @MainActor in
                adState.isLoaded = true
                adState.adSize = bannerView.adSize.size
                adState.error = nil
                print("✅ Banner ad loaded successfully")
                
                // Trigger event callback
                events?.onAdLoaded?()
                adState.events?.onAdLoaded?()
            }
        }
        
        func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor in
                adState.isLoaded = false
                adState.error = error
                print("❌ Banner ad failed to load: \(error.localizedDescription)")
                
                // Trigger event callback
                events?.onAdFailedToLoad?(error)
                adState.events?.onAdFailedToLoad?(error)
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            print("📊 Banner ad recorded impression")
            Task { @MainActor in
                events?.onAdImpression?()
                adState.events?.onAdImpression?()
            }
        }
        
        func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
            print("👆 Banner ad recorded click")
            Task { @MainActor in
                events?.onAdClicked?()
                adState.events?.onAdClicked?()
            }
        }
        
        func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("📱 Banner ad will present screen")
            Task { @MainActor in
                events?.onAdWillPresentScreen?()
                adState.events?.onAdWillPresentScreen?()
            }
        }
        
        func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("📱 Banner ad will dismiss screen")
            Task { @MainActor in
                events?.onAdWillDismissScreen?()
                adState.events?.onAdWillDismissScreen?()
            }
        }
        
        func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("📱 Banner ad did dismiss screen")
            Task { @MainActor in
                events?.onAdDidDismissScreen?()
                adState.events?.onAdDidDismissScreen?()
            }
        }
    }
}

// MARK: - Convenience Initializers
public extension BannerAdView {
    /// Tạo banner với kích thước adaptive (khuyến nghị)
    static func adaptive(adUnitID: String? = nil, events: BannerAdEvents? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .adaptive, events: events)
    }
    
    /// Tạo banner chuẩn 320x50
    static func standard(adUnitID: String? = nil, events: BannerAdEvents? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .banner, events: events)
    }
    
    /// Tạo banner large 320x100
    static func large(adUnitID: String? = nil, events: BannerAdEvents? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .largeBanner, events: events)
    }
    
    /// Tạo banner medium rectangle 300x250
    static func mediumRectangle(adUnitID: String? = nil, events: BannerAdEvents? = nil) -> BannerAdView {
        BannerAdView(adUnitID: adUnitID, adSize: .mediumRectangle, events: events)
    }
}

// Type alias for backwards compatibility
public typealias BannerAdSize = AdBannerSize
