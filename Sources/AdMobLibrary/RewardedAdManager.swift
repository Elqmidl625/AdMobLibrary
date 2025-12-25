//
//  RewardedAdManager.swift
//  AdMobLibrary
//
//  Quản lý Rewarded Ads (quảng cáo có thưởng)
//

import Foundation
import GoogleMobileAds
import SwiftUI

/// Thông tin phần thưởng
public struct AdReward {
    public let type: String
    public let amount: Int
    
    public init(type: String, amount: Int) {
        self.type = type
        self.amount = amount
    }
    
    init(from gadReward: AdReward_) {
        self.type = gadReward.type
        self.amount = gadReward.amount.intValue
    }
}

// Type alias để tránh xung đột tên
typealias AdReward_ = GoogleMobileAds.AdReward

/// RewardedAdManager - Quản lý việc load và hiển thị Rewarded Ads
@MainActor
public final class RewardedAdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = RewardedAdManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isLoaded = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private var rewardedAd: RewardedAd?
    private var adUnitID: String?
    private var onReward: ((AdReward) -> Void)?
    private var onDismiss: (() -> Void)?
    private var onFailed: ((Error) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Load Ad
    
    /// Load Rewarded Ad
    /// - Parameters:
    ///   - adUnitID: Ad Unit ID (mặc định sử dụng ID trong AdMobManager)
    ///   - completion: Callback khi load xong
    public func load(
        adUnitID: String? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let unitID = adUnitID ?? AdMobManager.shared.adUnitIDs.rewarded
        self.adUnitID = unitID
        
        guard !isLoading else {
            print("⚠️ Rewarded ad is already loading")
            return
        }
        
        isLoading = true
        error = nil
        
        let request = AdMobManager.shared.createAdRequest()
        
        RewardedAd.load(with: unitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    self?.isLoaded = false
                    self?.error = error
                    print("❌ Rewarded ad failed to load: \(error.localizedDescription)")
                    completion?(.failure(error))
                    return
                }
                
                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isLoaded = true
                print("✅ Rewarded ad loaded successfully")
                completion?(.success(()))
            }
        }
    }
    
    /// Load Rewarded Ad với async/await
    public func load(adUnitID: String? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            load(adUnitID: adUnitID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Show Ad
    
    /// Hiển thị Rewarded Ad
    /// - Parameters:
    ///   - onReward: Callback khi user nhận thưởng (xem hết video)
    ///   - onDismiss: Callback khi đóng quảng cáo
    ///   - onFailed: Callback khi hiển thị thất bại
    /// - Returns: true nếu bắt đầu hiển thị thành công
    @discardableResult
    public func show(
        onReward: @escaping (AdReward) -> Void,
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        guard let ad = rewardedAd else {
            print("❌ Rewarded ad is not ready")
            let error = NSError(domain: "AdMobLibrary", code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Ad not ready"])
            onFailed?(error)
            return false
        }
        
        guard let rootViewController = AdMobManager.shared.getRootViewController() else {
            print("❌ Cannot find root view controller")
            let error = NSError(domain: "AdMobLibrary", code: -2, 
                              userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            onFailed?(error)
            return false
        }
        
        self.onReward = onReward
        self.onDismiss = onDismiss
        self.onFailed = onFailed
        
        ad.present(from: rootViewController) { [weak self] in
            guard let ad = self?.rewardedAd else { return }
            let reward = AdReward(from: ad.adReward)
            print("🎁 User earned reward: \(reward.amount) \(reward.type)")
            self?.onReward?(reward)
        }
        
        return true
    }
    
    /// Hiển thị ad và tự động load lại
    @discardableResult
    public func showAndReload(
        onReward: @escaping (AdReward) -> Void,
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        let wrappedDismiss: () -> Void = { [weak self] in
            onDismiss?()
            // Tự động load lại ad mới
            self?.load()
        }
        return show(onReward: onReward, onDismiss: wrappedDismiss, onFailed: onFailed)
    }
    
    // MARK: - Preload
    
    /// Preload ad để sẵn sàng hiển thị
    public func preload(adUnitID: String? = nil) {
        if !isLoaded && !isLoading {
            load(adUnitID: adUnitID)
        }
    }
    
    // MARK: - Reward Info
    
    /// Lấy thông tin phần thưởng (nếu ad đã load)
    public var rewardInfo: AdReward? {
        guard let ad = rewardedAd else { return nil }
        return AdReward(from: ad.adReward)
    }
}

// MARK: - FullScreenContentDelegate
extension RewardedAdManager: FullScreenContentDelegate {
    
    nonisolated public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 Rewarded ad recorded impression")
    }
    
    nonisolated public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 Rewarded ad recorded click")
    }
    
    nonisolated public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Rewarded ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            self.isLoaded = false
            self.rewardedAd = nil
            self.error = error
            self.onFailed?(error)
        }
    }
    
    nonisolated public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded ad will present")
    }
    
    nonisolated public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded ad will dismiss")
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded ad did dismiss")
        Task { @MainActor in
            self.isLoaded = false
            self.rewardedAd = nil
            self.onDismiss?()
        }
    }
}

// MARK: - SwiftUI View Modifier
public struct RewardedAdModifier: ViewModifier {
    @Binding var isPresented: Bool
    let adUnitID: String?
    let onReward: (AdReward) -> Void
    let onDismiss: (() -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { _, newValue in
                if newValue {
                    if RewardedAdManager.shared.isLoaded {
                        RewardedAdManager.shared.show(
                            onReward: onReward,
                            onDismiss: {
                                isPresented = false
                                onDismiss?()
                            }
                        )
                    } else {
                        RewardedAdManager.shared.load(adUnitID: adUnitID) { result in
                            if case .success = result {
                                RewardedAdManager.shared.show(
                                    onReward: onReward,
                                    onDismiss: {
                                        isPresented = false
                                        onDismiss?()
                                    }
                                )
                            }
                        }
                    }
                }
            }
    }
}

public extension View {
    /// Hiển thị Rewarded Ad khi binding = true
    func rewardedAd(
        isPresented: Binding<Bool>,
        adUnitID: String? = nil,
        onReward: @escaping (AdReward) -> Void,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(RewardedAdModifier(
            isPresented: isPresented,
            adUnitID: adUnitID,
            onReward: onReward,
            onDismiss: onDismiss
        ))
    }
}

// MARK: - Rewarded Interstitial Ad Manager
@MainActor
public final class RewardedInterstitialAdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = RewardedInterstitialAdManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isLoaded = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private var rewardedInterstitialAd: RewardedInterstitialAd?
    private var adUnitID: String?
    private var onReward: ((AdReward) -> Void)?
    private var onDismiss: (() -> Void)?
    private var onFailed: ((Error) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Load Ad
    
    public func load(
        adUnitID: String? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let unitID = adUnitID ?? AdMobManager.shared.adUnitIDs.rewardedInterstitial
        self.adUnitID = unitID
        
        guard !isLoading else {
            print("⚠️ Rewarded Interstitial ad is already loading")
            return
        }
        
        isLoading = true
        error = nil
        
        let request = AdMobManager.shared.createAdRequest()
        
        RewardedInterstitialAd.load(with: unitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    self?.isLoaded = false
                    self?.error = error
                    print("❌ Rewarded Interstitial ad failed to load: \(error.localizedDescription)")
                    completion?(.failure(error))
                    return
                }
                
                self?.rewardedInterstitialAd = ad
                self?.rewardedInterstitialAd?.fullScreenContentDelegate = self
                self?.isLoaded = true
                print("✅ Rewarded Interstitial ad loaded successfully")
                completion?(.success(()))
            }
        }
    }
    
    public func load(adUnitID: String? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            load(adUnitID: adUnitID) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Show Ad
    
    @discardableResult
    public func show(
        onReward: @escaping (AdReward) -> Void,
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        guard let ad = rewardedInterstitialAd else {
            print("❌ Rewarded Interstitial ad is not ready")
            let error = NSError(domain: "AdMobLibrary", code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Ad not ready"])
            onFailed?(error)
            return false
        }
        
        guard let rootViewController = AdMobManager.shared.getRootViewController() else {
            print("❌ Cannot find root view controller")
            let error = NSError(domain: "AdMobLibrary", code: -2, 
                              userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            onFailed?(error)
            return false
        }
        
        self.onReward = onReward
        self.onDismiss = onDismiss
        self.onFailed = onFailed
        
        ad.present(from: rootViewController) { [weak self] in
            guard let ad = self?.rewardedInterstitialAd else { return }
            let reward = AdReward(from: ad.adReward)
            print("🎁 User earned reward: \(reward.amount) \(reward.type)")
            self?.onReward?(reward)
        }
        
        return true
    }
    
    @discardableResult
    public func showAndReload(
        onReward: @escaping (AdReward) -> Void,
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        let wrappedDismiss: () -> Void = { [weak self] in
            onDismiss?()
            self?.load()
        }
        return show(onReward: onReward, onDismiss: wrappedDismiss, onFailed: onFailed)
    }
    
    public func preload(adUnitID: String? = nil) {
        if !isLoaded && !isLoading {
            load(adUnitID: adUnitID)
        }
    }
}

// MARK: - FullScreenContentDelegate
extension RewardedInterstitialAdManager: FullScreenContentDelegate {
    
    nonisolated public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 Rewarded Interstitial ad recorded impression")
    }
    
    nonisolated public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 Rewarded Interstitial ad recorded click")
    }
    
    nonisolated public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Rewarded Interstitial ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            self.isLoaded = false
            self.rewardedInterstitialAd = nil
            self.error = error
            self.onFailed?(error)
        }
    }
    
    nonisolated public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded Interstitial ad will present")
    }
    
    nonisolated public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded Interstitial ad will dismiss")
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Rewarded Interstitial ad did dismiss")
        Task { @MainActor in
            self.isLoaded = false
            self.rewardedInterstitialAd = nil
            self.onDismiss?()
        }
    }
}

