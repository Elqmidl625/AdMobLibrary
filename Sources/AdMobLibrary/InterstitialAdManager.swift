//
//  InterstitialAdManager.swift
//  AdMobLibrary
//
//  Quản lý Interstitial Ads (quảng cáo toàn màn hình)
//

import Foundation
import GoogleMobileAds
import SwiftUI

/// InterstitialAdManager - Quản lý việc load và hiển thị Interstitial Ads
@MainActor
public final class InterstitialAdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = InterstitialAdManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isLoaded = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var error: Error?
    
    // MARK: - Event Callbacks
    /// Event callbacks cho Interstitial Ads
    public var events: FullScreenAdEvents?
    
    // MARK: - Private Properties
    private var interstitialAd: InterstitialAd?
    private var adUnitID: String?
    private var onDismiss: (() -> Void)?
    private var onFailed: ((Error) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Load Ad
    
    /// Load Interstitial Ad
    /// - Parameters:
    ///   - adUnitID: Ad Unit ID (mặc định sử dụng ID trong AdMobManager)
    ///   - completion: Callback khi load xong
    public func load(
        adUnitID: String? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let unitID = adUnitID ?? AdMobManager.shared.adUnitIDs.interstitial
        self.adUnitID = unitID
        
        guard !isLoading else {
            print("⚠️ Interstitial ad is already loading")
            return
        }
        
        isLoading = true
        error = nil
        
        let request = AdMobManager.shared.createAdRequest()
        
        InterstitialAd.load(with: unitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    self?.isLoaded = false
                    self?.error = error
                    print("❌ Interstitial ad failed to load: \(error.localizedDescription)")
                    
                    // Trigger event callback
                    self?.events?.onAdFailedToLoad?(error)
                    
                    completion?(.failure(error))
                    return
                }
                
                self?.interstitialAd = ad
                self?.interstitialAd?.fullScreenContentDelegate = self
                self?.isLoaded = true
                print("✅ Interstitial ad loaded successfully")
                
                // Trigger event callback
                self?.events?.onAdLoaded?()
                
                completion?(.success(()))
            }
        }
    }
    
    /// Load Interstitial Ad với async/await
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
    
    /// Hiển thị Interstitial Ad
    /// - Parameters:
    ///   - onDismiss: Callback khi đóng quảng cáo
    ///   - onFailed: Callback khi hiển thị thất bại
    /// - Returns: true nếu hiển thị thành công
    @discardableResult
    public func show(
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        guard let ad = interstitialAd else {
            print("❌ Interstitial ad is not ready")
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
        
        self.onDismiss = onDismiss
        self.onFailed = onFailed
        
        ad.present(from: rootViewController)
        return true
    }
    
    /// Hiển thị ad và tự động load lại
    @discardableResult
    public func showAndReload(
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        let wrappedDismiss: () -> Void = { [weak self] in
            onDismiss?()
            // Tự động load lại ad mới
            self?.load()
        }
        return show(onDismiss: wrappedDismiss, onFailed: onFailed)
    }
    
    // MARK: - Preload
    
    /// Preload ad để sẵn sàng hiển thị
    public func preload(adUnitID: String? = nil) {
        if !isLoaded && !isLoading {
            load(adUnitID: adUnitID)
        }
    }
}

// MARK: - FullScreenContentDelegate
extension InterstitialAdManager: FullScreenContentDelegate {
    
    nonisolated public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 Interstitial ad recorded impression")
        Task { @MainActor in
            self.events?.onAdImpression?()
        }
    }
    
    nonisolated public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 Interstitial ad recorded click")
        Task { @MainActor in
            self.events?.onAdClicked?()
        }
    }
    
    nonisolated public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Interstitial ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            self.isLoaded = false
            self.interstitialAd = nil
            self.error = error
            self.onFailed?(error)
            
            // Trigger event callback
            self.events?.onAdFailedToPresent?(error)
        }
    }
    
    nonisolated public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Interstitial ad will present")
        Task { @MainActor in
            self.events?.onAdWillPresent?()
        }
    }
    
    nonisolated public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Interstitial ad will dismiss")
        Task { @MainActor in
            self.events?.onAdWillDismiss?()
        }
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Interstitial ad did dismiss")
        Task { @MainActor in
            self.isLoaded = false
            self.interstitialAd = nil
            self.onDismiss?()
            
            // Trigger event callback
            self.events?.onAdDidDismiss?()
        }
    }
}

// MARK: - SwiftUI View Modifier
public struct InterstitialAdModifier: ViewModifier {
    @Binding var isPresented: Bool
    let adUnitID: String?
    let onDismiss: (() -> Void)?
    
    public func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: isPresented) { _, newValue in
                    if newValue {
                        if InterstitialAdManager.shared.isLoaded {
                            InterstitialAdManager.shared.show(
                                onDismiss: {
                                    isPresented = false
                                    onDismiss?()
                                }
                            )
                        } else {
                            InterstitialAdManager.shared.load(adUnitID: adUnitID) { result in
                                if case .success = result {
                                    InterstitialAdManager.shared.show(
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
        } else {
            // Fallback on earlier versions
        }
    }
}

public extension View {
    /// Hiển thị Interstitial Ad khi binding = true
    func interstitialAd(
        isPresented: Binding<Bool>,
        adUnitID: String? = nil,
        onDismiss: (() -> Void)? = nil
    ) -> some View {
        modifier(InterstitialAdModifier(
            isPresented: isPresented,
            adUnitID: adUnitID,
            onDismiss: onDismiss
        ))
    }
}
