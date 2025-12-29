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
    
    public init() {}
}

// MARK: - Banner Ad View (SwiftUI)
public struct BannerAdView: View {
    let adUnitID: String?
    let adSize: AdBannerSize
    @StateObject private var adState = BannerAdState()
    
    public init(
        adUnitID: String? = nil,
        adSize: AdBannerSize = .adaptive
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
        Coordinator(adState: adState)
    }
    
    class Coordinator: NSObject, GoogleMobileAds.BannerViewDelegate {
        let adState: BannerAdState
        
        init(adState: BannerAdState) {
            self.adState = adState
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GoogleMobileAds.BannerView) {
            Task { @MainActor in
                adState.isLoaded = true
                adState.adSize = bannerView.adSize.size
                adState.error = nil
                print("✅ Banner ad loaded successfully")
            }
        }
        
        func bannerView(_ bannerView: GoogleMobileAds.BannerView, didFailToReceiveAdWithError error: Error) {
            Task { @MainActor in
                adState.isLoaded = false
                adState.error = error
                print("❌ Banner ad failed to load: \(error.localizedDescription)")
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GoogleMobileAds.BannerView) {
            print("📊 Banner ad recorded impression")
        }
        
        func bannerViewDidRecordClick(_ bannerView: GoogleMobileAds.BannerView) {
            print("👆 Banner ad recorded click")
        }
        
        func bannerViewWillPresentScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("📱 Banner ad will present screen")
        }
        
        func bannerViewWillDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
            print("📱 Banner ad will dismiss screen")
        }
        
        func bannerViewDidDismissScreen(_ bannerView: GoogleMobileAds.BannerView) {
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

// Type alias for backwards compatibility
public typealias BannerAdSize = AdBannerSize
