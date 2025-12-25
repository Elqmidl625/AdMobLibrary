//
//  AdMobLibrary.swift
//  AdMobLibrary
//
//  Thư viện quảng cáo AdMob hoàn chỉnh cho SwiftUI
//  Bao gồm: Banner, Interstitial, Rewarded, App Open, Native Ads
//  Hỗ trợ GDPR Consent với Google UMP
//

import Foundation
import GoogleMobileAds
import UserMessagingPlatform

// MARK: - Re-export Google Mobile Ads types
@_exported import GoogleMobileAds
@_exported import UserMessagingPlatform

// MARK: - Public API

/// AdMobLibrary - Entry point cho thư viện
public struct AdMobLibrary {
    
    /// Phiên bản thư viện
    public static let version = "1.0.0"
    
    /// Khởi tạo thư viện với các Ad Unit IDs
    /// - Parameters:
    ///   - adUnitIDs: Các Ad Unit ID cho từng loại quảng cáo
    ///   - testDeviceIdentifiers: Danh sách device ID để test
    ///   - handleConsent: Tự động xử lý GDPR consent
    ///   - completion: Callback khi khởi tạo hoàn tất
    @MainActor
    public static func initialize(
        adUnitIDs: AdMobManager.AdUnitIDs? = nil,
        testDeviceIdentifiers: [String] = [],
        handleConsent: Bool = false,
        completion: ((Bool) -> Void)? = nil
    ) {
        if handleConsent {
            ConsentManager.shared.requestConsentAndInitializeAds(
                adUnitIDs: adUnitIDs
            ) { result in
                switch result {
                case .success:
                    completion?(ConsentManager.shared.canRequestAds)
                case .failure:
                    completion?(false)
                }
            }
        } else {
            AdMobManager.shared.initialize(
                adUnitIDs: adUnitIDs,
                testDeviceIdentifiers: testDeviceIdentifiers
            ) { _ in
                completion?(true)
            }
        }
    }
    
    /// Khởi tạo thư viện với async/await
    @MainActor
    public static func initialize(
        adUnitIDs: AdMobManager.AdUnitIDs? = nil,
        testDeviceIdentifiers: [String] = [],
        handleConsent: Bool = false
    ) async -> Bool {
        await withCheckedContinuation { continuation in
            initialize(
                adUnitIDs: adUnitIDs,
                testDeviceIdentifiers: testDeviceIdentifiers,
                handleConsent: handleConsent
            ) { success in
                continuation.resume(returning: success)
            }
        }
    }
    
    // MARK: - Quick Access to Managers
    
    /// AdMob Manager singleton
    @MainActor
    public static var manager: AdMobManager { .shared }
    
    /// Interstitial Ad Manager
    @MainActor
    public static var interstitial: InterstitialAdManager { .shared }
    
    /// Rewarded Ad Manager
    @MainActor
    public static var rewarded: RewardedAdManager { .shared }
    
    /// Rewarded Interstitial Ad Manager
    @MainActor
    public static var rewardedInterstitial: RewardedInterstitialAdManager { .shared }
    
    /// App Open Ad Manager
    @MainActor
    public static var appOpen: AppOpenAdManager { .shared }
    
    /// Native Ad Manager
    @MainActor
    public static var native: NativeAdManager { .shared }
    
    /// Consent Manager
    @MainActor
    public static var consent: ConsentManager { .shared }
    
    // MARK: - Preload All Ads
    
    /// Preload tất cả các loại quảng cáo
    @MainActor
    public static func preloadAllAds() {
        interstitial.preload()
        rewarded.preload()
        rewardedInterstitial.preload()
        appOpen.preload()
        native.preload()
    }
}

// MARK: - Usage Examples
/*
 
 === KHỞI TẠO ===
 
 // Trong App init hoặc AppDelegate:
 
 // Cách 1: Khởi tạo đơn giản với test IDs
 await AdMobLibrary.initialize()
 
 // Cách 2: Khởi tạo với custom Ad Unit IDs
 await AdMobLibrary.initialize(
     adUnitIDs: .init(
         banner: "ca-app-pub-xxxxx/banner",
         interstitial: "ca-app-pub-xxxxx/interstitial",
         rewarded: "ca-app-pub-xxxxx/rewarded",
         rewardedInterstitial: "ca-app-pub-xxxxx/rewarded-interstitial",
         appOpen: "ca-app-pub-xxxxx/app-open",
         native: "ca-app-pub-xxxxx/native"
     ),
     testDeviceIdentifiers: ["YOUR_DEVICE_ID"]
 )
 
 // Cách 3: Khởi tạo với GDPR consent
 await AdMobLibrary.initialize(handleConsent: true)
 
 
 === BANNER ADS ===
 
 // Trong SwiftUI View:
 var body: some View {
     VStack {
         // Banner adaptive (khuyến nghị)
         BannerAdView.adaptive()
         
         // Banner chuẩn
         BannerAdView.standard()
         
         // Banner với custom size
         BannerAdView(adSize: .mediumRectangle)
         
         // Banner với custom Ad Unit ID
         BannerAdView(adUnitID: "ca-app-pub-xxxxx/banner")
     }
 }
 
 
 === INTERSTITIAL ADS ===
 
 // Preload trước
 AdMobLibrary.interstitial.preload()
 
 // Hiển thị khi cần
 AdMobLibrary.interstitial.showAndReload(
     onDismiss: {
         print("Ad closed")
     }
 )
 
 // Hoặc sử dụng View Modifier
 .interstitialAd(isPresented: $showAd)
 
 
 === REWARDED ADS ===
 
 // Preload
 AdMobLibrary.rewarded.preload()
 
 // Hiển thị
 AdMobLibrary.rewarded.showAndReload(
     onReward: { reward in
         print("User earned \(reward.amount) \(reward.type)")
     }
 )
 
 // Hoặc View Modifier
 .rewardedAd(isPresented: $showRewardedAd) { reward in
     coins += reward.amount
 }
 
 
 === APP OPEN ADS ===
 
 // Setup tự động hiển thị khi app foreground
 AppOpenAdHandler.configure(
     autoShowOnForeground: true,
     minimumInterval: 60 // Tối thiểu 60 giây giữa các lần hiển thị
 )
 
 // Hoặc hiển thị thủ công
 AdMobLibrary.appOpen.showIfAvailable()
 
 
 === NATIVE ADS ===
 
 // Trong SwiftUI View
 NativeAdView()
 
 // Với custom layout
 NativeAdView { nativeAd in
     AnyView(
         CustomNativeAdView(ad: nativeAd)
     )
 }
 
 
 === GDPR CONSENT ===
 
 // Tự động xử lý consent
 ContentView()
     .requestAdConsent { canShowAds in
         if canShowAds {
             AdMobLibrary.preloadAllAds()
         }
     }
 
 // Hiển thị nút Privacy Settings
 PrivacyOptionsButton(title: "Cài đặt quyền riêng tư")
 
 // Reset consent (testing)
 ConsentManager.shared.reset()
 
 */
