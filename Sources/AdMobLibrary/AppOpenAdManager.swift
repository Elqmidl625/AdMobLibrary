//
//  AppOpenAdManager.swift
//  AdMobLibrary
//
//  Quản lý App Open Ads (quảng cáo khi mở app)
//

import Foundation
import GoogleMobileAds
import SwiftUI
import UIKit

/// AppOpenAdManager - Quản lý việc load và hiển thị App Open Ads
@MainActor
public final class AppOpenAdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = AppOpenAdManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isLoaded = false
    @Published public private(set) var isLoading = false
    @Published public private(set) var isShowing = false
    @Published public private(set) var error: Error?
    
    // MARK: - Configuration
    /// Thời gian tối đa ad được cache (4 giờ theo khuyến nghị của Google)
    public var adExpirationHours: Double = 4
    
    /// Tự động hiển thị khi app foreground
    public var autoShowOnForeground: Bool = true
    
    /// Khoảng thời gian tối thiểu giữa các lần hiển thị (giây)
    public var minimumInterval: TimeInterval = 30
    
    // MARK: - Event Callbacks
    /// Event callbacks cho App Open Ads
    public var events: FullScreenAdEvents?
    
    // MARK: - Private Properties
    private var appOpenAd: AppOpenAd?
    private var adUnitID: String?
    private var loadTime: Date?
    private var lastShowTime: Date?
    private var onDismiss: (() -> Void)?
    private var onFailed: ((Error) -> Void)?
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Private flags
    private var shouldShowOnNextLoad = false
    private var isConfigured = false
    
    // MARK: - Setup
    
    /// Cài đặt tự động hiển thị khi app foreground
    public func setupAutoShow(adUnitID: String? = nil) {
        guard !isConfigured else {
            print("⚠️ App Open Ad already configured")
            return
        }
        isConfigured = true
        
        self.adUnitID = adUnitID ?? AdMobManager.shared.adUnitIDs.appOpen
        
        // Đăng ký notification khi app sắp vào foreground (để load trước)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        // Đăng ký notification khi app đã active (để hiển thị)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        // Preload ad
        load()
    }
    
    @objc private func appWillEnterForeground() {
        // Bắt đầu load ad sớm khi app sắp vào foreground
        if !isAdAvailable && !isLoading {
            print("📱 App will enter foreground - preloading ad...")
            shouldShowOnNextLoad = autoShowOnForeground && canShowAdByTime
            load()
        }
    }
    
    @objc private func appDidBecomeActive() {
        guard autoShowOnForeground else { return }
        
        Task { @MainActor in
            if isAdAvailable && canShowAdByTime {
                _ = show()
            } else if !isLoading && !isAdAvailable {
                // Ad chưa sẵn sàng, đánh dấu để hiển thị khi load xong
                shouldShowOnNextLoad = true
                load()
            }
        }
    }
    
    /// Kiểm tra thời gian có cho phép hiển thị không
    private var canShowAdByTime: Bool {
        if let lastShowTime = lastShowTime {
            return Date().timeIntervalSince(lastShowTime) >= minimumInterval
        }
        return true
    }
    
    // MARK: - Load Ad
    
    /// Load App Open Ad
    public func load(
        adUnitID: String? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let unitID = adUnitID ?? self.adUnitID ?? AdMobManager.shared.adUnitIDs.appOpen
        self.adUnitID = unitID
        
        guard !isLoading else {
            print("⚠️ App Open ad is already loading")
            return
        }
        
        // Nếu ad đã load và còn hợp lệ, không cần load lại
        if isAdAvailable {
            print("ℹ️ App Open ad is already available")
            completion?(.success(()))
            return
        }
        
        isLoading = true
        error = nil
        
        let request = AdMobManager.shared.createAdRequest()
        
        AppOpenAd.load(with: unitID, request: request) { [weak self] ad, error in
            Task { @MainActor in
                self?.isLoading = false
                
                if let error = error {
                    self?.isLoaded = false
                    self?.error = error
                    self?.shouldShowOnNextLoad = false
                    print("❌ App Open ad failed to load: \(error.localizedDescription)")
                    
                    // Trigger event callback
                    self?.events?.onAdFailedToLoad?(error)
                    
                    completion?(.failure(error))
                    return
                }
                
                self?.appOpenAd = ad
                self?.appOpenAd?.fullScreenContentDelegate = self
                self?.loadTime = Date()
                self?.isLoaded = true
                print("✅ App Open ad loaded successfully")
                
                // Trigger event callback
                self?.events?.onAdLoaded?()
                
                // Tự động hiển thị nếu đã được đánh dấu
                if self?.shouldShowOnNextLoad == true && self?.canShowAdByTime == true {
                    self?.shouldShowOnNextLoad = false
                    print("📱 Auto-showing ad after load...")
                    _ = self?.show()
                }
                
                completion?(.success(()))
            }
        }
    }
    
    /// Load App Open Ad với async/await
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
    
    // MARK: - Ad Availability
    
    /// Kiểm tra ad có sẵn sàng và còn hợp lệ không
    public var isAdAvailable: Bool {
        guard appOpenAd != nil, let loadTime = loadTime else {
            return false
        }
        
        // Kiểm tra ad còn hợp lệ không (theo thời gian)
        let expirationInterval = adExpirationHours * 60 * 60
        return Date().timeIntervalSince(loadTime) < expirationInterval
    }
    
    /// Kiểm tra có thể hiển thị ad không (dựa trên khoảng thời gian tối thiểu)
    public var canShowAd: Bool {
        guard isAdAvailable else { return false }
        
        if let lastShowTime = lastShowTime {
            return Date().timeIntervalSince(lastShowTime) >= minimumInterval
        }
        
        return true
    }
    
    // MARK: - Show Ad
    
    /// Hiển thị App Open Ad
    @discardableResult
    public func show(
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        guard !isShowing else {
            print("⚠️ App Open ad is already showing")
            return false
        }
        
        guard let ad = appOpenAd, isAdAvailable else {
            print("❌ App Open ad is not ready or expired")
            let error = NSError(domain: "AdMobLibrary", code: -1, 
                              userInfo: [NSLocalizedDescriptionKey: "Ad not ready or expired"])
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
        isShowing = true
        
        ad.present(from: rootViewController)
        return true
    }
    
    /// Hiển thị ad nếu có sẵn và đủ điều kiện
    @discardableResult
    public func showIfAvailable(
        onDismiss: (() -> Void)? = nil,
        onFailed: ((Error) -> Void)? = nil
    ) -> Bool {
        guard canShowAd else {
            if !isAdAvailable {
                // Nếu ad không có sẵn, load mới
                load()
            }
            return false
        }
        
        return show(onDismiss: onDismiss, onFailed: onFailed)
    }
    
    // MARK: - Preload
    
    /// Preload ad để sẵn sàng hiển thị
    public func preload(adUnitID: String? = nil) {
        if !isAdAvailable && !isLoading {
            load(adUnitID: adUnitID)
        }
    }
    
    // MARK: - Cleanup
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - FullScreenContentDelegate
extension AppOpenAdManager: FullScreenContentDelegate {
    
    nonisolated public func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 App Open ad recorded impression")
        Task { @MainActor in
            self.events?.onAdImpression?()
        }
    }
    
    nonisolated public func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("👆 App Open ad recorded click")
        Task { @MainActor in
            self.events?.onAdClicked?()
        }
    }
    
    nonisolated public func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ App Open ad failed to present: \(error.localizedDescription)")
        Task { @MainActor in
            self.isShowing = false
            self.isLoaded = false
            self.appOpenAd = nil
            self.loadTime = nil
            self.error = error
            self.shouldShowOnNextLoad = false
            self.onFailed?(error)
            
            // Trigger event callback
            self.events?.onAdFailedToPresent?(error)
            
            // Load lại ad mới
            self.load()
        }
    }
    
    nonisolated public func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open ad will present")
        Task { @MainActor in
            self.events?.onAdWillPresent?()
        }
    }
    
    nonisolated public func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open ad will dismiss")
        Task { @MainActor in
            self.events?.onAdWillDismiss?()
        }
    }
    
    nonisolated public func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 App Open ad did dismiss")
        Task { @MainActor in
            self.isShowing = false
            self.isLoaded = false
            self.appOpenAd = nil
            self.loadTime = nil
            self.lastShowTime = Date()
            self.shouldShowOnNextLoad = false
            self.onDismiss?()
            
            // Trigger event callback
            self.events?.onAdDidDismiss?()
            
            // Load lại ad mới ngay lập tức
            print("🔄 Reloading ad for next foreground...")
            self.load()
        }
    }
}

// MARK: - SwiftUI App Delegate Adapter
/// Helper để tích hợp App Open Ad vào SwiftUI App
public struct AppOpenAdHandler {
    
    /// Cài đặt App Open Ad trong App init    /// - Note: App Open Ads chỉ hiển thị khi app trở lại từ background, KHÔNG hiển thị lần mở đầu tiên
    @MainActor
    public static func configure(
        adUnitID: String? = nil,
        autoShowOnForeground: Bool = true,
        minimumInterval: TimeInterval = 30
    ) {
        AppOpenAdManager.shared.autoShowOnForeground = autoShowOnForeground
        AppOpenAdManager.shared.minimumInterval = minimumInterval
        AppOpenAdManager.shared.setupAutoShow(adUnitID: adUnitID)
    }
    
    /// Cài đặt App Open Ad (async version)
    /// Sử dụng khi gọi từ trong Task block
    public static func configureAsync(
        adUnitID: String? = nil,
        autoShowOnForeground: Bool = true,
        minimumInterval: TimeInterval = 30
    ) async {
        await MainActor.run {
            AppOpenAdManager.shared.autoShowOnForeground = autoShowOnForeground
            AppOpenAdManager.shared.minimumInterval = minimumInterval
            AppOpenAdManager.shared.setupAutoShow(adUnitID: adUnitID)
        }
    }
}

