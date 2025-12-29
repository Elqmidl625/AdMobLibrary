//
//  AdEventCallbacks.swift
//  AdMobLibrary
//
//  Định nghĩa các Event Callbacks cho tất cả loại Ads
//  Dựa trên Google AdMob iOS SDK Delegates
//

import Foundation
import GoogleMobileAds

// MARK: - Banner Ad Events
/// Các events cho Banner Ads (GADBannerViewDelegate)
public struct BannerAdEvents {
    /// Ad đã load thành công
    public var onAdLoaded: (() -> Void)?
    
    /// Ad load thất bại
    public var onAdFailedToLoad: ((Error) -> Void)?
    
    /// Ad đã ghi nhận impression (hiển thị)
    public var onAdImpression: (() -> Void)?
    
    /// Ad đã được click
    public var onAdClicked: (() -> Void)?
    
    /// Ad sẽ present full screen (khi click vào ad)
    public var onAdWillPresentScreen: (() -> Void)?
    
    /// Ad sẽ dismiss full screen
    public var onAdWillDismissScreen: (() -> Void)?
    
    /// Ad đã dismiss full screen
    public var onAdDidDismissScreen: (() -> Void)?
    
    public init(
        onAdLoaded: (() -> Void)? = nil,
        onAdFailedToLoad: ((Error) -> Void)? = nil,
        onAdImpression: (() -> Void)? = nil,
        onAdClicked: (() -> Void)? = nil,
        onAdWillPresentScreen: (() -> Void)? = nil,
        onAdWillDismissScreen: (() -> Void)? = nil,
        onAdDidDismissScreen: (() -> Void)? = nil
    ) {
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        self.onAdImpression = onAdImpression
        self.onAdClicked = onAdClicked
        self.onAdWillPresentScreen = onAdWillPresentScreen
        self.onAdWillDismissScreen = onAdWillDismissScreen
        self.onAdDidDismissScreen = onAdDidDismissScreen
    }
}

// MARK: - Full Screen Ad Events
/// Các events cho Full Screen Ads (GADFullScreenContentDelegate)
/// Áp dụng cho: Interstitial, Rewarded, Rewarded Interstitial, App Open
public struct FullScreenAdEvents {
    /// Ad đã load thành công
    public var onAdLoaded: (() -> Void)?
    
    /// Ad load thất bại
    public var onAdFailedToLoad: ((Error) -> Void)?
    
    /// Ad đã ghi nhận impression
    public var onAdImpression: (() -> Void)?
    
    /// Ad đã được click
    public var onAdClicked: (() -> Void)?
    
    /// Ad present thất bại
    public var onAdFailedToPresent: ((Error) -> Void)?
    
    /// Ad sẽ present full screen
    public var onAdWillPresent: (() -> Void)?
    
    /// Ad sẽ dismiss
    public var onAdWillDismiss: (() -> Void)?
    
    /// Ad đã dismiss
    public var onAdDidDismiss: (() -> Void)?
    
    public init(
        onAdLoaded: (() -> Void)? = nil,
        onAdFailedToLoad: ((Error) -> Void)? = nil,
        onAdImpression: (() -> Void)? = nil,
        onAdClicked: (() -> Void)? = nil,
        onAdFailedToPresent: ((Error) -> Void)? = nil,
        onAdWillPresent: (() -> Void)? = nil,
        onAdWillDismiss: (() -> Void)? = nil,
        onAdDidDismiss: (() -> Void)? = nil
    ) {
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        self.onAdImpression = onAdImpression
        self.onAdClicked = onAdClicked
        self.onAdFailedToPresent = onAdFailedToPresent
        self.onAdWillPresent = onAdWillPresent
        self.onAdWillDismiss = onAdWillDismiss
        self.onAdDidDismiss = onAdDidDismiss
    }
}

// MARK: - Native Ad Events
/// Các events cho Native Ads (GADNativeAdDelegate)
public struct NativeAdEvents {
    /// Ad đã load thành công (trả về NativeAd object)
    public var onAdLoaded: ((NativeAd) -> Void)?
    
    /// Ad load thất bại
    public var onAdFailedToLoad: ((Error) -> Void)?
    
    /// Ad đã ghi nhận impression
    public var onAdImpression: (() -> Void)?
    
    /// Ad đã được click
    public var onAdClicked: (() -> Void)?
    
    /// Ad sẽ present screen (khi click vào ad)
    public var onAdWillPresentScreen: (() -> Void)?
    
    /// Ad sẽ dismiss screen
    public var onAdWillDismissScreen: (() -> Void)?
    
    /// Ad đã dismiss screen
    public var onAdDidDismissScreen: (() -> Void)?
    
    /// Ad sẽ rời khỏi app (mở Safari, App Store...)
    public var onAdWillLeaveApplication: (() -> Void)?
    
    public init(
        onAdLoaded: ((NativeAd) -> Void)? = nil,
        onAdFailedToLoad: ((Error) -> Void)? = nil,
        onAdImpression: (() -> Void)? = nil,
        onAdClicked: (() -> Void)? = nil,
        onAdWillPresentScreen: (() -> Void)? = nil,
        onAdWillDismissScreen: (() -> Void)? = nil,
        onAdDidDismissScreen: (() -> Void)? = nil,
        onAdWillLeaveApplication: (() -> Void)? = nil
    ) {
        self.onAdLoaded = onAdLoaded
        self.onAdFailedToLoad = onAdFailedToLoad
        self.onAdImpression = onAdImpression
        self.onAdClicked = onAdClicked
        self.onAdWillPresentScreen = onAdWillPresentScreen
        self.onAdWillDismissScreen = onAdWillDismissScreen
        self.onAdDidDismissScreen = onAdDidDismissScreen
        self.onAdWillLeaveApplication = onAdWillLeaveApplication
    }
}

// MARK: - Rewarded Ad Events (Extended)
/// Các events mở rộng cho Rewarded Ads (bao gồm reward callback)
public struct RewardedAdEvents {
    /// Base events từ FullScreenAdEvents
    public var fullScreenEvents: FullScreenAdEvents
    
    /// User đã nhận được reward (xem hết video)
    public var onUserEarnedReward: ((AdReward) -> Void)?
    
    public init(
        fullScreenEvents: FullScreenAdEvents = FullScreenAdEvents(),
        onUserEarnedReward: ((AdReward) -> Void)? = nil
    ) {
        self.fullScreenEvents = fullScreenEvents
        self.onUserEarnedReward = onUserEarnedReward
    }
    
    // Convenience initializer với tất cả parameters
    public init(
        onAdLoaded: (() -> Void)? = nil,
        onAdFailedToLoad: ((Error) -> Void)? = nil,
        onAdImpression: (() -> Void)? = nil,
        onAdClicked: (() -> Void)? = nil,
        onAdFailedToPresent: ((Error) -> Void)? = nil,
        onAdWillPresent: (() -> Void)? = nil,
        onAdWillDismiss: (() -> Void)? = nil,
        onAdDidDismiss: (() -> Void)? = nil,
        onUserEarnedReward: ((AdReward) -> Void)? = nil
    ) {
        self.fullScreenEvents = FullScreenAdEvents(
            onAdLoaded: onAdLoaded,
            onAdFailedToLoad: onAdFailedToLoad,
            onAdImpression: onAdImpression,
            onAdClicked: onAdClicked,
            onAdFailedToPresent: onAdFailedToPresent,
            onAdWillPresent: onAdWillPresent,
            onAdWillDismiss: onAdWillDismiss,
            onAdDidDismiss: onAdDidDismiss
        )
        self.onUserEarnedReward = onUserEarnedReward
    }
}

