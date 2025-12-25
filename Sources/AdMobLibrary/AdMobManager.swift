//
//  AdMobManager.swift
//  AdMobLibrary
//
//  Singleton quản lý việc khởi tạo và cấu hình Google Mobile Ads SDK
//

import Foundation
import GoogleMobileAds
import SwiftUI

/// AdMobManager - Singleton quản lý việc khởi tạo SDK và các cấu hình chung
@MainActor
public final class AdMobManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = AdMobManager()
    
    // MARK: - Published Properties
    @Published public private(set) var isInitialized = false
    @Published public private(set) var initializationError: Error?
    
    // MARK: - Configuration
    public var isTestMode: Bool = false
    public var testDeviceIdentifiers: [String] = []
    
    // MARK: - Ad Unit IDs (Test IDs by default)
    public struct AdUnitIDs {
        public var banner: String
        public var interstitial: String
        public var rewarded: String
        public var rewardedInterstitial: String
        public var appOpen: String
        public var native: String
        
        public init(
            banner: String = "ca-app-pub-3940256099942544/2934735716",
            interstitial: String = "ca-app-pub-3940256099942544/4411468910",
            rewarded: String = "ca-app-pub-3940256099942544/1712485313",
            rewardedInterstitial: String = "ca-app-pub-3940256099942544/6978759866",
            appOpen: String = "ca-app-pub-3940256099942544/5575463023",
            native: String = "ca-app-pub-3940256099942544/3986624511"
        ) {
            self.banner = banner
            self.interstitial = interstitial
            self.rewarded = rewarded
            self.rewardedInterstitial = rewardedInterstitial
            self.appOpen = appOpen
            self.native = native
        }
        
        /// Test Ad Unit IDs từ Google
        public static let test = AdUnitIDs()
    }
    
    public var adUnitIDs = AdUnitIDs.test
    
    // MARK: - Initialization
    private init() {}
    
    /// Khởi tạo Google Mobile Ads SDK
    /// - Parameters:
    ///   - adUnitIDs: Các Ad Unit ID cho từng loại quảng cáo
    ///   - testDeviceIdentifiers: Danh sách device ID để test
    ///   - completion: Callback khi khởi tạo hoàn tất
    public func initialize(
        adUnitIDs: AdUnitIDs? = nil,
        testDeviceIdentifiers: [String] = [],
        completion: ((Error?) -> Void)? = nil
    ) {
        if let adUnitIDs = adUnitIDs {
            self.adUnitIDs = adUnitIDs
        }
        
        self.testDeviceIdentifiers = testDeviceIdentifiers
        
        // Cấu hình test devices
        if !testDeviceIdentifiers.isEmpty {
            MobileAds.shared.requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers
        }
        
        // Khởi tạo SDK
        MobileAds.shared.start { [weak self] status in
            Task { @MainActor in
                self?.isInitialized = true
                self?.initializationError = nil
                
                print("📱 AdMob SDK initialized successfully")
                print("📊 Adapter statuses:")
                status.adapterStatusesByClassName.forEach { (adapter, status) in
                    print("   - \(adapter): \(status.state.rawValue)")
                }
                
                completion?(nil)
            }
        }
    }
    
    /// Khởi tạo SDK với async/await
    public func initialize(
        adUnitIDs: AdUnitIDs? = nil,
        testDeviceIdentifiers: [String] = []
    ) async {
        await withCheckedContinuation { continuation in
            initialize(adUnitIDs: adUnitIDs, testDeviceIdentifiers: testDeviceIdentifiers) { _ in
                continuation.resume()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Lấy root view controller hiện tại
    public func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        // Tìm top-most presented controller
        var topController = rootViewController
        while let presentedController = topController.presentedViewController {
            topController = presentedController
        }
        
        return topController
    }
    
    /// Tạo GADRequest với các cấu hình mặc định
    public func createAdRequest() -> Request {
        let request = Request()
        return request
    }
}

// MARK: - SwiftUI Environment Key
public struct AdMobManagerKey: EnvironmentKey {
    public static let defaultValue: AdMobManager = .shared
}

public extension EnvironmentValues {
    var adMobManager: AdMobManager {
        get { self[AdMobManagerKey.self] }
        set { self[AdMobManagerKey.self] = newValue }
    }
}

