//
//  ConsentManager.swift
//  AdMobLibrary
//
//  Quản lý GDPR Consent với Google User Messaging Platform (UMP)
//

import Foundation
import GoogleMobileAds
import UserMessagingPlatform
import SwiftUI

/// Trạng thái consent (đổi tên để tránh xung đột với UMP ConsentStatus)
public enum AdConsentStatus {
    case unknown
    case notRequired
    case required
    case obtained
    
    init(from umpStatus: UserMessagingPlatform.ConsentStatus) {
        switch umpStatus {
        case .unknown:
            self = .unknown
        case .notRequired:
            self = .notRequired
        case .required:
            self = .required
        case .obtained:
            self = .obtained
        @unknown default:
            self = .unknown
        }
    }
}

/// ConsentManager - Quản lý GDPR/EEA Consent
@MainActor
public final class ConsentManager: ObservableObject {
    
    // MARK: - Singleton
    public static let shared = ConsentManager()
    
    // MARK: - Published Properties
    @Published public private(set) var consentStatus: AdConsentStatus = .unknown
    @Published public private(set) var canRequestAds: Bool = false
    @Published public private(set) var isFormAvailable: Bool = false
    @Published public private(set) var error: Error?
    
    // MARK: - Configuration
    /// Cho phép hiển thị debug options (chỉ sử dụng khi dev)
    public var debugSettings: DebugSettings?
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Request Consent Info
    
    /// Yêu cầu thông tin consent và hiển thị form nếu cần
    /// - Parameters:
    ///   - tagForUnderAgeOfConsent: Đánh dấu user dưới tuổi đồng ý (COPPA)
    ///   - completion: Callback khi hoàn tất
    public func requestConsentInfoUpdate(
        tagForUnderAgeOfConsent: Bool = false,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        let parameters = RequestParameters()
        parameters.isTaggedForUnderAgeOfConsent = tagForUnderAgeOfConsent
        
        // Debug settings (chỉ sử dụng khi dev)
        if let debugSettings = debugSettings {
            parameters.debugSettings = debugSettings
        }
        
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    print("❌ Consent info update failed: \(error.localizedDescription)")
                    completion?(.failure(error))
                    return
                }
                
                self?.updateConsentStatus()
                print("✅ Consent info updated successfully")
                print("📊 Consent status: \(String(describing: self?.consentStatus))")
                print("📋 Form available: \(String(describing: self?.isFormAvailable))")
                completion?(.success(()))
            }
        }
    }
    
    /// Yêu cầu consent info với async/await
    public func requestConsentInfoUpdate(tagForUnderAgeOfConsent: Bool = false) async throws {
        try await withCheckedThrowingContinuation { continuation in
            requestConsentInfoUpdate(tagForUnderAgeOfConsent: tagForUnderAgeOfConsent) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Show Consent Form
    
    /// Hiển thị form consent nếu cần
    public func showConsentFormIfRequired(
        from viewController: UIViewController? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard isFormAvailable else {
            print("ℹ️ Consent form not available or not required")
            completion?(.success(()))
            return
        }
        
        guard let rootVC = viewController ?? AdMobManager.shared.getRootViewController() else {
            let error = NSError(domain: "AdMobLibrary", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            completion?(.failure(error))
            return
        }
        
        ConsentForm.loadAndPresentIfRequired(from: rootVC) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    print("❌ Consent form error: \(error.localizedDescription)")
                    completion?(.failure(error))
                    return
                }
                
                self?.updateConsentStatus()
                print("✅ Consent form completed")
                completion?(.success(()))
            }
        }
    }
    
    /// Hiển thị form consent với async/await
    public func showConsentFormIfRequired(from viewController: UIViewController? = nil) async throws {
        try await withCheckedThrowingContinuation { continuation in
            showConsentFormIfRequired(from: viewController) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Privacy Options Form
    
    /// Kiểm tra có thể hiển thị privacy options không
    public var canShowPrivacyOptionsForm: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }
    
    /// Hiển thị form privacy options (cho phép user thay đổi lựa chọn)
    public func showPrivacyOptionsForm(
        from viewController: UIViewController? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        guard canShowPrivacyOptionsForm else {
            print("ℹ️ Privacy options form not required")
            completion?(.success(()))
            return
        }
        
        guard let rootVC = viewController ?? AdMobManager.shared.getRootViewController() else {
            let error = NSError(domain: "AdMobLibrary", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            completion?(.failure(error))
            return
        }
        
        ConsentForm.presentPrivacyOptionsForm(from: rootVC) { [weak self] error in
            Task { @MainActor in
                if let error = error {
                    self?.error = error
                    print("❌ Privacy options form error: \(error.localizedDescription)")
                    completion?(.failure(error))
                    return
                }
                
                self?.updateConsentStatus()
                print("✅ Privacy options form completed")
                completion?(.success(()))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateConsentStatus() {
        let info = ConsentInformation.shared
        consentStatus = AdConsentStatus(from: info.consentStatus)
        canRequestAds = info.canRequestAds
        isFormAvailable = info.formStatus == .available
    }
    
    /// Reset consent (chỉ sử dụng cho testing)
    public func reset() {
        ConsentInformation.shared.reset()
        updateConsentStatus()
        print("🔄 Consent info reset")
    }
    
    // MARK: - Full Flow
    
    /// Thực hiện toàn bộ flow consent và khởi tạo ads
    /// - Parameters:
    ///   - tagForUnderAgeOfConsent: Đánh dấu user dưới tuổi đồng ý
    ///   - adUnitIDs: Các Ad Unit ID
    ///   - completion: Callback khi hoàn tất
    public func requestConsentAndInitializeAds(
        tagForUnderAgeOfConsent: Bool = false,
        adUnitIDs: AdMobManager.AdUnitIDs? = nil,
        completion: ((Result<Void, Error>) -> Void)? = nil
    ) {
        requestConsentInfoUpdate(tagForUnderAgeOfConsent: tagForUnderAgeOfConsent) { [weak self] result in
            switch result {
            case .failure(let error):
                completion?(.failure(error))
                
            case .success:
                // Hiển thị form nếu cần
                self?.showConsentFormIfRequired { result in
                    switch result {
                    case .failure(let error):
                        completion?(.failure(error))
                        
                    case .success:
                        // Khởi tạo AdMob nếu có thể request ads
                        if self?.canRequestAds == true {
                            Task { @MainActor in
                                AdMobManager.shared.initialize(adUnitIDs: adUnitIDs) { _ in
                                    completion?(.success(()))
                                }
                            }
                        } else {
                            print("⚠️ Cannot request ads - consent not obtained")
                            completion?(.success(()))
                        }
                    }
                }
            }
        }
    }
    
    /// Full flow với async/await
    public func requestConsentAndInitializeAds(
        tagForUnderAgeOfConsent: Bool = false,
        adUnitIDs: AdMobManager.AdUnitIDs? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { continuation in
            requestConsentAndInitializeAds(
                tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
                adUnitIDs: adUnitIDs
            ) { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

// MARK: - Debug Helpers
public extension ConsentManager {
    
    /// Tạo debug settings cho testing
    /// - Parameters:
    ///   - testDeviceHashedIds: Danh sách device ID
    ///   - geography: Giả lập vùng địa lý (EEA, notEEA)
    /// - Returns: DebugSettings
    static func createDebugSettings(
        testDeviceHashedIds: [String],
        geography: DebugGeography = .EEA
    ) -> DebugSettings {
        let debugSettings = DebugSettings()
        debugSettings.testDeviceIdentifiers = testDeviceHashedIds
        debugSettings.geography = geography
        return debugSettings
    }
}

// MARK: - SwiftUI View Modifier
@MainActor
public struct ConsentViewModifier: ViewModifier {
    @ObservedObject var consentManager = ConsentManager.shared
    let tagForUnderAgeOfConsent: Bool
    let adUnitIDs: AdMobManager.AdUnitIDs?
    let onComplete: ((Bool) -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .task {
                do {
                    try await consentManager.requestConsentAndInitializeAds(
                        tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
                        adUnitIDs: adUnitIDs
                    )
                    onComplete?(consentManager.canRequestAds)
                } catch {
                    print("❌ Consent flow error: \(error.localizedDescription)")
                    onComplete?(false)
                }
            }
    }
}

public extension View {
    /// Tự động xử lý consent flow khi view xuất hiện
    @MainActor
    func requestAdConsent(
        tagForUnderAgeOfConsent: Bool = false,
        adUnitIDs: AdMobManager.AdUnitIDs? = nil,
        onComplete: ((Bool) -> Void)? = nil
    ) -> some View {
        modifier(ConsentViewModifier(
            tagForUnderAgeOfConsent: tagForUnderAgeOfConsent,
            adUnitIDs: adUnitIDs,
            onComplete: onComplete
        ))
    }
}

// MARK: - Privacy Options Button
@MainActor
public struct PrivacyOptionsButton: View {
    @ObservedObject var consentManager = ConsentManager.shared
    let title: String
    
    public init(title: String = "Privacy Settings") {
        self.title = title
    }
    
    public var body: some View {
        if consentManager.canShowPrivacyOptionsForm {
            Button(title) {
                consentManager.showPrivacyOptionsForm()
            }
        }
    }
}
