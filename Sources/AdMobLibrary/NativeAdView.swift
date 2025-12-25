//
//  NativeAdView.swift
//  AdMobLibrary
//
//  SwiftUI wrapper cho Native Ads
//

import SwiftUI
import GoogleMobileAds

// MARK: - Native Ad State
@MainActor
public class NativeAdState: NSObject, ObservableObject {
    @Published public var nativeAd: NativeAd?
    @Published public var isLoading = false
    @Published public var isLoaded = false
    @Published public var error: Error?
    
    private var adLoader: AdLoader?
    private var adUnitID: String?
    
    public override init() {
        super.init()
    }
    
    /// Load Native Ad
    public func load(adUnitID: String? = nil) {
        let unitID = adUnitID ?? AdMobManager.shared.adUnitIDs.native
        self.adUnitID = unitID
        
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        guard let rootViewController = AdMobManager.shared.getRootViewController() else {
            isLoading = false
            error = NSError(domain: "AdMobLibrary", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            return
        }
        
        adLoader = AdLoader(
            adUnitID: unitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        adLoader?.load(AdMobManager.shared.createAdRequest())
    }
    
    /// Refresh ad
    public func refresh() {
        load(adUnitID: adUnitID)
    }
}

// MARK: - AdLoaderDelegate
extension NativeAdState: AdLoaderDelegate {
    nonisolated public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Native ad failed to load: \(error.localizedDescription)")
        Task { @MainActor in
            self.isLoading = false
            self.isLoaded = false
            self.error = error
        }
    }
}

// MARK: - NativeAdLoaderDelegate
extension NativeAdState: NativeAdLoaderDelegate {
    nonisolated public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("✅ Native ad loaded successfully")
        Task { @MainActor in
            self.isLoading = false
            self.isLoaded = true
            self.nativeAd = nativeAd
            self.error = nil
        }
    }
}

// MARK: - Native Ad View (SwiftUI)
public struct NativeAdView: View {
    @StateObject private var adState = NativeAdState()
    let adUnitID: String?
    let customView: ((NativeAd) -> AnyView)?
    
    public init(
        adUnitID: String? = nil,
        customView: ((NativeAd) -> AnyView)? = nil
    ) {
        self.adUnitID = adUnitID
        self.customView = customView
    }
    
    public var body: some View {
        Group {
            if let nativeAd = adState.nativeAd {
                if let customView = customView {
                    customView(nativeAd)
                } else {
                    DefaultNativeAdView(nativeAd: nativeAd)
                }
            } else if adState.isLoading {
                ProgressView()
                    .frame(height: 120)
            } else if adState.error != nil {
                EmptyView()
            } else {
                Color.clear
                    .frame(height: 120)
            }
        }
        .onAppear {
            if !adState.isLoaded && !adState.isLoading {
                adState.load(adUnitID: adUnitID)
            }
        }
    }
}

// MARK: - Default Native Ad View
struct DefaultNativeAdView: View {
    let nativeAd: NativeAd
    
    var body: some View {
        NativeAdViewRepresentable(nativeAd: nativeAd)
            .frame(minHeight: 120)
    }
}

// MARK: - Native Ad UIViewRepresentable
struct NativeAdViewRepresentable: UIViewRepresentable {
    let nativeAd: NativeAd
    
    func makeUIView(context: Context) -> NativeAdViewWrapper {
        let nativeAdView = NativeAdViewWrapper()
        return nativeAdView
    }
    
    func updateUIView(_ nativeAdView: NativeAdViewWrapper, context: Context) {
        nativeAdView.configure(with: nativeAd)
    }
}

// MARK: - Native Ad View Wrapper (UIKit)
class NativeAdViewWrapper: UIView {
    
    private let containerView = UIView()
    private let iconImageView = UIImageView()
    private let headlineLabel = UILabel()
    private let bodyLabel = UILabel()
    private let advertiserLabel = UILabel()
    private let callToActionButton = UIButton(type: .system)
    private let adBadge = UILabel()
    private var nativeAdView: NativeAdView_?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        clipsToBounds = true
        
        // Ad badge
        adBadge.text = "Ad"
        adBadge.font = .systemFont(ofSize: 10, weight: .semibold)
        adBadge.textColor = .white
        adBadge.backgroundColor = UIColor.systemYellow.withAlphaComponent(0.9)
        adBadge.textAlignment = .center
        adBadge.layer.cornerRadius = 4
        adBadge.clipsToBounds = true
        adBadge.translatesAutoresizingMaskIntoConstraints = false
        addSubview(adBadge)
        
        // Icon
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 8
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        // Headline
        headlineLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(headlineLabel)
        
        // Body
        bodyLabel.font = .systemFont(ofSize: 13)
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 2
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bodyLabel)
        
        // Advertiser
        advertiserLabel.font = .systemFont(ofSize: 11)
        advertiserLabel.textColor = .tertiaryLabel
        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(advertiserLabel)
        
        // CTA Button
        callToActionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        callToActionButton.setTitleColor(.white, for: .normal)
        callToActionButton.backgroundColor = .systemBlue
        callToActionButton.layer.cornerRadius = 8
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(callToActionButton)
        
        NSLayoutConstraint.activate([
            // Ad badge
            adBadge.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            adBadge.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            adBadge.widthAnchor.constraint(equalToConstant: 24),
            adBadge.heightAnchor.constraint(equalToConstant: 16),
            
            // Icon
            iconImageView.topAnchor.constraint(equalTo: adBadge.bottomAnchor, constant: 8),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            iconImageView.widthAnchor.constraint(equalToConstant: 48),
            iconImageView.heightAnchor.constraint(equalToConstant: 48),
            
            // Headline
            headlineLabel.topAnchor.constraint(equalTo: iconImageView.topAnchor),
            headlineLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            headlineLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // Advertiser
            advertiserLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 2),
            advertiserLabel.leadingAnchor.constraint(equalTo: headlineLabel.leadingAnchor),
            advertiserLabel.trailingAnchor.constraint(equalTo: headlineLabel.trailingAnchor),
            
            // Body
            bodyLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            bodyLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            bodyLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            
            // CTA Button
            callToActionButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 12),
            callToActionButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            callToActionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            callToActionButton.heightAnchor.constraint(equalToConstant: 36),
            callToActionButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }
    
    func configure(with nativeAd: NativeAd) {
        // Tạo GADNativeAdView
        if nativeAdView == nil {
            nativeAdView = NativeAdView_()
            nativeAdView?.translatesAutoresizingMaskIntoConstraints = false
            insertSubview(nativeAdView!, at: 0)
            
            NSLayoutConstraint.activate([
                nativeAdView!.topAnchor.constraint(equalTo: topAnchor),
                nativeAdView!.leadingAnchor.constraint(equalTo: leadingAnchor),
                nativeAdView!.trailingAnchor.constraint(equalTo: trailingAnchor),
                nativeAdView!.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
        
        // Cấu hình các views
        nativeAdView?.nativeAd = nativeAd
        
        // Icon
        if let icon = nativeAd.icon?.image {
            iconImageView.image = icon
        }
        nativeAdView?.iconView = iconImageView
        
        // Headline
        headlineLabel.text = nativeAd.headline
        nativeAdView?.headlineView = headlineLabel
        
        // Body
        bodyLabel.text = nativeAd.body
        nativeAdView?.bodyView = bodyLabel
        
        // Advertiser
        advertiserLabel.text = nativeAd.advertiser
        nativeAdView?.advertiserView = advertiserLabel
        
        // CTA
        callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
        nativeAdView?.callToActionView = callToActionButton
        callToActionButton.isUserInteractionEnabled = false
    }
}

// Type alias để tránh xung đột với SwiftUI NativeAdView
typealias NativeAdView_ = GoogleMobileAds.NativeAdView

// MARK: - Native Ad Manager (Standalone)
@MainActor
public final class NativeAdManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    public static let shared = NativeAdManager()
    
    // MARK: - Published Properties
    @Published public private(set) var nativeAd: NativeAd?
    @Published public private(set) var isLoading = false
    @Published public private(set) var isLoaded = false
    @Published public private(set) var error: Error?
    
    // MARK: - Private Properties
    private var adLoader: AdLoader?
    private var adUnitID: String?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Load Ad
    
    public func load(
        adUnitID: String? = nil,
        completion: ((Result<NativeAd, Error>) -> Void)? = nil
    ) {
        let unitID = adUnitID ?? AdMobManager.shared.adUnitIDs.native
        self.adUnitID = unitID
        
        guard !isLoading else {
            print("⚠️ Native ad is already loading")
            return
        }
        
        guard let rootViewController = AdMobManager.shared.getRootViewController() else {
            let error = NSError(domain: "AdMobLibrary", code: -2,
                              userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
            completion?(.failure(error))
            return
        }
        
        isLoading = true
        error = nil
        
        adLoader = AdLoader(
            adUnitID: unitID,
            rootViewController: rootViewController,
            adTypes: [.native],
            options: nil
        )
        adLoader?.delegate = self
        
        // Store completion handler
        objc_setAssociatedObject(self, "completion", completion, .OBJC_ASSOCIATION_RETAIN)
        
        adLoader?.load(AdMobManager.shared.createAdRequest())
    }
    
    public func load(adUnitID: String? = nil) async throws -> NativeAd {
        try await withCheckedThrowingContinuation { continuation in
            load(adUnitID: adUnitID) { result in
                switch result {
                case .success(let ad):
                    continuation.resume(returning: ad)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func preload(adUnitID: String? = nil) {
        if !isLoaded && !isLoading {
            load(adUnitID: adUnitID)
        }
    }
}

// MARK: - AdLoaderDelegate
extension NativeAdManager: AdLoaderDelegate {
    nonisolated public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("❌ Native ad failed to load: \(error.localizedDescription)")
        Task { @MainActor in
            self.isLoading = false
            self.isLoaded = false
            self.error = error
            
            if let completion = objc_getAssociatedObject(self, "completion") as? ((Result<NativeAd, Error>) -> Void) {
                completion(.failure(error))
            }
        }
    }
}

// MARK: - NativeAdLoaderDelegate
extension NativeAdManager: NativeAdLoaderDelegate {
    nonisolated public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("✅ Native ad loaded successfully")
        Task { @MainActor in
            self.isLoading = false
            self.isLoaded = true
            self.nativeAd = nativeAd
            self.error = nil
            
            if let completion = objc_getAssociatedObject(self, "completion") as? ((Result<NativeAd, Error>) -> Void) {
                completion(.success(nativeAd))
            }
        }
    }
}

