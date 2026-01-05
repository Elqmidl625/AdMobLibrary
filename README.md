# AdMobLibrary

Thư viện quảng cáo AdMob hoàn chỉnh cho SwiftUI, hỗ trợ tất cả các loại quảng cáo và GDPR Consent.

---

## 📋 Mục lục

- [Tính năng](#-tính-năng)
- [Cài đặt](#-cài-đặt)
- [Bắt đầu nhanh](#-bắt-đầu-nhanh)
- [Các loại quảng cáo](#-các-loại-quảng-cáo)
  - [Banner Ads](#1-banner-ads)
  - [Interstitial Ads](#2-interstitial-ads)
  - [Rewarded Ads](#3-rewarded-ads)
  - [App Open Ads](#4-app-open-ads)
  - [Native Ads](#5-native-ads)
  - [Native Ads với Custom XIB](#6-native-ads-với-custom-xib)
- [Event Callbacks](#-event-callbacks)
- [GDPR Consent](#-gdpr-consent)
- [API Reference](#-api-reference)
- [Testing](#-testing)
- [Cấu trúc thư viện](#-cấu-trúc-thư-viện)

---

## ✨ Tính năng

| Tính năng | Mô tả |
|-----------|-------|
| ✅ Banner Ads | Nhiều kích thước (Adaptive, Standard, Large, Medium Rectangle...) |
| ✅ Interstitial Ads | Quảng cáo toàn màn hình |
| ✅ Rewarded Ads | Quảng cáo có thưởng |
| ✅ Rewarded Interstitial | Quảng cáo toàn màn hình có thưởng |
| ✅ App Open Ads | Quảng cáo khi mở app |
| ✅ Native Ads | Quảng cáo tự nhiên với custom layout |
| ✅ Custom XIB | Hỗ trợ load Native Ads từ XIB/Storyboard |
| ✅ Event Callbacks | Bắt tất cả các sự kiện (impression, click, dismiss...) |
| ✅ GDPR Consent | Hỗ trợ Google UMP cho EU/EEA |

---

## 📦 Cài đặt

### Swift Package Manager

**Trong Xcode:**
1. File > Add Packages...
2. Nhập URL: `https://github.com/your-repo/AdMobLibrary.git`
3. Chọn version

**Hoặc trong `Package.swift`:**

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/AdMobLibrary.git", from: "1.0.0")
]
```

### Yêu cầu

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

### Cấu hình Info.plist

```xml
<!-- AdMob App ID -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-xxxxxxxxxxxxxxxx~xxxxxxxxxx</string>

<!-- SKAdNetwork IDs (cho iOS 14+) -->
<key>SKAdNetworkItems</key>
<array>
    <dict>
        <key>SKAdNetworkIdentifier</key>
        <string>cstr6suwn9.skadnetwork</string>
    </dict>
    <!-- Thêm các SKAdNetwork ID khác -->
</array>

<!-- App Tracking Transparency (iOS 14+) -->
<key>NSUserTrackingUsageDescription</key>
<string>Chúng tôi sử dụng thông tin này để cung cấp quảng cáo phù hợp với bạn.</string>
```

---

## 🚀 Bắt đầu nhanh

```swift
import AdMobLibrary

@main
struct MyApp: App {
    init() {
        Task {
            // Khởi tạo đơn giản (sử dụng test IDs)
            await AdMobLibrary.initialize()
            
            // Setup App Open Ads (optional)
            await AppOpenAdHandler.configureAsync(autoShowOnForeground: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Khởi tạo nâng cao

```swift
// Với custom Ad Unit IDs
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

// Với GDPR consent handling
await AdMobLibrary.initialize(handleConsent: true)
```

---

## 📱 Các loại quảng cáo

### 1. Banner Ads

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            // Nội dung app
            Spacer()
            
            // Banner adaptive (khuyến nghị)
            BannerAdView.adaptive()
        }
    }
}
```

**Các kích thước khác:**

```swift
BannerAdView.standard()        // 320x50
BannerAdView.large()           // 320x100
BannerAdView.mediumRectangle() // 300x250

// Với custom Ad Unit ID
BannerAdView(adUnitID: "ca-app-pub-xxxxx/banner")
```

---

### 2. Interstitial Ads

**Cách 1: SwiftUI View Modifier**

```swift
struct GameView: View {
    @State private var showAd = false
    
    var body: some View {
        Button("Next Level") {
            showAd = true
        }
        .interstitialAd(isPresented: $showAd) {
            print("Ad dismissed")
        }
        .onAppear {
            AdMobLibrary.interstitial.preload()
        }
    }
}
```

**Cách 2: Gọi trực tiếp**

```swift
// Hiển thị và tự động load lại
AdMobLibrary.interstitial.showAndReload(
    onDismiss: { print("Ad closed") },
    onFailed: { error in print("Failed: \(error)") }
)
```

---

### 3. Rewarded Ads

**Cách 1: SwiftUI View Modifier**

```swift
struct StoreView: View {
    @State private var coins = 0
    @State private var showAd = false
    
    var body: some View {
        VStack {
            Text("Coins: \(coins)")
            
            Button("Watch Ad for Coins") {
                showAd = true
            }
        }
        .rewardedAd(isPresented: $showAd) { reward in
            coins += reward.amount
        }
        .onAppear {
            AdMobLibrary.rewarded.preload()
        }
    }
}
```

**Cách 2: Gọi trực tiếp**

```swift
AdMobLibrary.rewarded.showAndReload(
    onReward: { reward in
        print("Earned: \(reward.amount) \(reward.type)")
    },
    onDismiss: { print("Ad closed") }
)
```

---

### 4. App Open Ads

> ⚠️ **Lưu ý:** App Open Ads chỉ hiển thị khi app **trở lại từ background**, KHÔNG hiển thị lần mở đầu tiên.

```swift
@main
struct MyApp: App {
    init() {
        Task {
            await AdMobLibrary.initialize()
            await AppOpenAdHandler.configureAsync(
                adUnitID: nil,  // nil = test ID
                autoShowOnForeground: true,
                minimumInterval: 60  // giây
            )
        }
    }
}

// Hiển thị thủ công
AdMobLibrary.appOpen.showIfAvailable()
```

**Khi nào hiển thị?**

| Tình huống | Hiển thị? |
|------------|-----------|
| Mở app lần đầu | ❌ Không |
| App từ background → foreground | ✅ Có |
| Chuyển từ app khác về | ✅ Có |
| Sau khi tắt màn hình và mở lại | ✅ Có |

---

### 5. Native Ads

**Cơ bản:**

```swift
NativeAdView()
    .frame(height: 200)
```

**Với custom SwiftUI layout:**

```swift
NativeAdView(
    customView: { nativeAd in
        AnyView(
            HStack {
                if let icon = nativeAd.icon?.image {
                    Image(uiImage: icon)
                        .resizable()
                        .frame(width: 40, height: 40)
                }
                VStack(alignment: .leading) {
                    Text(nativeAd.headline ?? "")
                        .font(.headline)
                    Text(nativeAd.body ?? "")
                        .font(.caption)
                }
            }
        )
    }
)
```

**Trong danh sách/feed:**

```swift
ScrollView {
    LazyVStack {
        ForEach(0..<20, id: \.self) { index in
            Text("Item \(index)")
            
            if index % 5 == 0 && index > 0 {
                NativeAdView()
                    .frame(height: 200)
            }
        }
    }
}
```

**Với Event Callbacks:**

```swift
NativeAdView(
    events: NativeAdEvents(
        onAdLoaded: { nativeAd in
            print("✅ Ad loaded: \(nativeAd.headline ?? "")")
        },
        onAdFailedToLoad: { error in
            print("❌ Failed: \(error)")
        },
        onAdImpression: {
            print("📊 Impression recorded")
        },
        onAdClicked: {
            print("👆 Ad clicked")
        }
    )
)
.frame(height: 200)
```

---

### 6. Native Ads với Custom XIB

#### Bước 1: Tạo file XIB

1. **File > New > File > View** → Đặt tên `CustomNativeAdView.xib`
2. Đổi class root view thành **GADNativeAdView** (Module: GoogleMobileAds)
3. Kết nối các outlets:

| Outlet | Kiểu UI | Mô tả |
|--------|---------|-------|
| `headlineView` | UILabel | Tiêu đề |
| `bodyView` | UILabel | Mô tả |
| `iconView` | UIImageView | Icon |
| `callToActionView` | UIButton | Nút CTA |
| `advertiserView` | UILabel | Nhà quảng cáo |
| `mediaView` | GADMediaView | Video/Image |
| `storeView` | UILabel | Store name |
| `priceView` | UILabel | Giá |

#### Bước 2: Sử dụng

**SwiftUI:**

```swift
CustomNativeAdView(nibName: "CustomNativeAdView")
    .frame(height: 300)
```

**SwiftUI với Events:**

```swift
CustomNativeAdView(
    adUnitID: "ca-app-pub-xxxxx/native",
    nibName: "CustomNativeAdView",
    bundle: nil,
    events: NativeAdEvents(
        onAdLoaded: { nativeAd in
            print("✅ Ad loaded: \(nativeAd.headline ?? "")")
        },
        onAdFailedToLoad: { error in
            print("❌ Failed: \(error.localizedDescription)")
        },
        onAdImpression: {
            print("📊 Impression recorded")
        },
        onAdClicked: {
            print("👆 Ad clicked")
        },
        onAdWillPresentScreen: {
            print("📱 Opening full screen...")
        },
        onAdDidDismissScreen: {
            print("📱 Full screen closed")
        }
    )
)
.frame(height: 300)
```

**UIKit:**

```swift
import UIKit
import AdMobLibrary

class NativeAdViewController: UIViewController {
    @IBOutlet weak var adContainerView: UIView!
    
    private lazy var adLoader = NativeAdLoader(events: NativeAdEvents(
        onAdLoaded: { [weak self] nativeAd in
            print("✅ Ad loaded")
            self?.displayAd()
        },
        onAdFailedToLoad: { error in
            print("❌ Failed: \(error)")
        },
        onAdClicked: {
            print("👆 Clicked")
        }
    ))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        adLoader.load()
    }
    
    func displayAd() {
        adLoader.displayAd(
            nibName: "CustomNativeAdView",
            in: adContainerView
        )
    }
}
```

---

## 🎯 Event Callbacks

Bắt các sự kiện của quảng cáo để tracking, analytics, hoặc xử lý logic.

### Các loại Events

#### BannerAdEvents

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad load thành công |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ghi nhận impression |
| `onAdClicked` | User click ad |
| `onAdWillPresentScreen` | Sẽ hiển thị full screen |
| `onAdWillDismissScreen` | Sẽ đóng full screen |
| `onAdDidDismissScreen` | Đã đóng full screen |

#### FullScreenAdEvents
*(Áp dụng cho: Interstitial, Rewarded, Rewarded Interstitial, App Open)*

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad load thành công |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ghi nhận impression |
| `onAdClicked` | User click ad |
| `onAdFailedToPresent` | Present thất bại |
| `onAdWillPresent` | Sẽ hiển thị |
| `onAdWillDismiss` | Sẽ đóng |
| `onAdDidDismiss` | Đã đóng |

#### NativeAdEvents

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad load thành công (trả về NativeAd) |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ghi nhận impression |
| `onAdClicked` | User click ad |
| `onAdWillPresentScreen` | Sẽ mở full screen |
| `onAdWillDismissScreen` | Sẽ đóng full screen |
| `onAdDidDismissScreen` | Đã đóng full screen |
| `onAdWillLeaveApplication` | Sẽ rời khỏi app |

### Cách sử dụng

**Banner:**

```swift
BannerAdView(
    events: BannerAdEvents(
        onAdLoaded: { print("Loaded") },
        onAdClicked: { print("Clicked") }
    )
)
```

**Interstitial:**

```swift
InterstitialAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: { print("Ready") },
    onAdImpression: { print("Impression") },
    onAdDidDismiss: { print("Dismissed") }
)

// Load và hiển thị
AdMobLibrary.interstitial.preload()
```

**Rewarded:**

```swift
RewardedAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: { print("Ready") },
    onAdDidDismiss: { print("Dismissed") }
)

// Global reward callback
RewardedAdManager.shared.onUserEarnedReward = { reward in
    print("Earned: \(reward.amount) \(reward.type)")
}
```

**App Open:**

```swift
AppOpenAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: { print("Ready") },
    onAdWillPresent: { print("Showing") },
    onAdDidDismiss: { print("Dismissed") }
)
```

**Native:**

```swift
// Cách 1: Trực tiếp trong View
NativeAdView(
    events: NativeAdEvents(
        onAdLoaded: { nativeAd in print("Loaded: \(nativeAd.headline ?? "")") },
        onAdClicked: { print("Clicked") }
    )
)

// Cách 2: Với Custom XIB
CustomNativeAdView(
    nibName: "CustomNativeAdView",
    events: NativeAdEvents(
        onAdLoaded: { _ in print("Loaded") },
        onAdClicked: { print("Clicked") }
    )
)

// Cách 3: Singleton (dùng chung toàn app)
NativeAdManager.shared.events = NativeAdEvents(
    onAdLoaded: { nativeAd in print("Loaded") },
    onAdClicked: { print("Clicked") }
)

// Cách 4: NativeAdLoader (UIKit)
let loader = NativeAdLoader(events: NativeAdEvents(
    onAdLoaded: { nativeAd in print("Loaded") },
    onAdClicked: { print("Clicked") }
))
loader.load()
```

### Ví dụ Analytics Integration

```swift
import FirebaseAnalytics

func setupAdTracking() {
    InterstitialAdManager.shared.events = FullScreenAdEvents(
        onAdImpression: {
            Analytics.logEvent("ad_impression", parameters: ["type": "interstitial"])
        },
        onAdClicked: {
            Analytics.logEvent("ad_click", parameters: ["type": "interstitial"])
        }
    )
    
    RewardedAdManager.shared.onUserEarnedReward = { reward in
        Analytics.logEvent("ad_reward", parameters: [
            "type": reward.type,
            "amount": reward.amount
        ])
    }
}
```

---

## 🔒 GDPR Consent

```swift
// Tự động xử lý
ContentView()
    .requestAdConsent { canShowAds in
        if canShowAds {
            AdMobLibrary.preloadAllAds()
        }
    }

// Nút Privacy Settings
PrivacyOptionsButton(title: "Manage Ad Preferences")

// Xử lý thủ công
func handleConsent() async {
    try? await ConsentManager.shared.requestConsentInfoUpdate()
    try? await ConsentManager.shared.showConsentFormIfRequired()
    
    if ConsentManager.shared.canRequestAds {
        await AdMobLibrary.initialize()
    }
}
```

---

## 📚 API Reference

### Banner Ads

| API | Mô tả |
|-----|-------|
| `BannerAdView.adaptive()` | Tạo banner adaptive (khuyến nghị) |
| `BannerAdView.standard()` | Tạo banner 320x50 |
| `BannerAdView.large()` | Tạo banner 320x100 |
| `BannerAdView.mediumRectangle()` | Tạo banner 300x250 |
| `BannerAdView(adUnitID: String?, adSize: AdBannerSize, events: BannerAdEvents?)` | Tạo banner với custom ID, size và events |
| `BannerAdView(adUnitID: String?, adSize: AdBannerSize)` | Tạo banner với custom ID và size |
| `BannerAdView(adSize: AdBannerSize, events: BannerAdEvents?)` | Tạo banner với custom size và events |
| `.id(UUID())` | Force reload banner bằng cách thay đổi id |

**Ví dụ:**
```swift
BannerAdView.adaptive()
BannerAdView(adUnitID: "ca-app-pub-xxxxx/banner", adSize: .mediumRectangle)
BannerAdView(adSize: .adaptive, events: BannerAdEvents(onAdLoaded: { print("Loaded") }))
```

### Interstitial Ads

| API | Mô tả |
|-----|-------|
| `AdMobLibrary.interstitial.load(adUnitID: String?, completion: ((Result<Void, Error>) -> Void)?)` | Load ad với callback |
| `AdMobLibrary.interstitial.load(adUnitID: String?) async throws` | Load ad với async/await |
| `AdMobLibrary.interstitial.preload(adUnitID: String?)` | Preload ad |
| `AdMobLibrary.interstitial.show(onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị ad |
| `AdMobLibrary.interstitial.showAndReload(onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị và tự động load lại |
| `AdMobLibrary.interstitial.isLoaded` | Kiểm tra ad đã sẵn sàng (Bool) |
| `AdMobLibrary.interstitial.isLoading` | Kiểm tra đang load (Bool) |
| `AdMobLibrary.interstitial.error` | Lỗi nếu có (Error?) |
| `AdMobLibrary.interstitial.events` | Event callbacks (FullScreenAdEvents?) |
| `.interstitialAd(isPresented: Binding<Bool>, adUnitID: String?, onDismiss: (() -> Void)?)` | SwiftUI View Modifier |

**Ví dụ:**
```swift
AdMobLibrary.interstitial.preload()
AdMobLibrary.interstitial.load(adUnitID: "ca-app-pub-xxxxx/interstitial") { result in
    if case .success = result {
        AdMobLibrary.interstitial.show()
    }
}
```

### Rewarded Ads

| API | Mô tả |
|-----|-------|
| `AdMobLibrary.rewarded.load(adUnitID: String?, completion: ((Result<Void, Error>) -> Void)?)` | Load ad với callback |
| `AdMobLibrary.rewarded.load(adUnitID: String?) async throws` | Load ad với async/await |
| `AdMobLibrary.rewarded.preload(adUnitID: String?)` | Preload ad |
| `AdMobLibrary.rewarded.show(onReward: (AdReward) -> Void, onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị ad |
| `AdMobLibrary.rewarded.showAndReload(onReward: (AdReward) -> Void, onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị và tự động load lại |
| `AdMobLibrary.rewarded.isLoaded` | Kiểm tra ad đã sẵn sàng (Bool) |
| `AdMobLibrary.rewarded.isLoading` | Kiểm tra đang load (Bool) |
| `AdMobLibrary.rewarded.error` | Lỗi nếu có (Error?) |
| `AdMobLibrary.rewarded.rewardInfo` | Thông tin phần thưởng (AdReward?) |
| `AdMobLibrary.rewarded.events` | Event callbacks (FullScreenAdEvents?) |
| `AdMobLibrary.rewarded.onUserEarnedReward` | Global reward callback ((AdReward) -> Void)? |
| `.rewardedAd(isPresented: Binding<Bool>, adUnitID: String?, onReward: (AdReward) -> Void, onDismiss: (() -> Void)?)` | SwiftUI View Modifier |

**Ví dụ:**
```swift
AdMobLibrary.rewarded.preload()
AdMobLibrary.rewarded.showAndReload(
    onReward: { reward in print("Earned: \(reward.amount)") },
    onDismiss: { print("Closed") }
)
```

### Rewarded Interstitial Ads

| API | Mô tả |
|-----|-------|
| `AdMobLibrary.rewardedInterstitial.load(adUnitID: String?, completion: ((Result<Void, Error>) -> Void)?)` | Load ad với callback |
| `AdMobLibrary.rewardedInterstitial.load(adUnitID: String?) async throws` | Load ad với async/await |
| `AdMobLibrary.rewardedInterstitial.preload(adUnitID: String?)` | Preload ad |
| `AdMobLibrary.rewardedInterstitial.show(onReward: (AdReward) -> Void, onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị ad |
| `AdMobLibrary.rewardedInterstitial.showAndReload(onReward: (AdReward) -> Void, onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị và tự động load lại |
| `AdMobLibrary.rewardedInterstitial.isLoaded` | Kiểm tra ad đã sẵn sàng (Bool) |
| `AdMobLibrary.rewardedInterstitial.isLoading` | Kiểm tra đang load (Bool) |
| `AdMobLibrary.rewardedInterstitial.error` | Lỗi nếu có (Error?) |
| `AdMobLibrary.rewardedInterstitial.events` | Event callbacks (FullScreenAdEvents?) |
| `AdMobLibrary.rewardedInterstitial.onUserEarnedReward` | Global reward callback ((AdReward) -> Void)? |

**Ví dụ:**
```swift
AdMobLibrary.rewardedInterstitial.preload()
AdMobLibrary.rewardedInterstitial.show(
    onReward: { reward in print("Reward: \(reward.amount)") },
    onDismiss: { print("Closed") }
)
```

### App Open Ads

| API | Mô tả |
|-----|-------|
| `AppOpenAdHandler.configure(adUnitID: String?, autoShowOnForeground: Bool, minimumInterval: TimeInterval)` | Cấu hình auto-show (MainActor) |
| `AppOpenAdHandler.configureAsync(adUnitID: String?, autoShowOnForeground: Bool, minimumInterval: TimeInterval) async` | Cấu hình auto-show (async) |
| `AdMobLibrary.appOpen.load(adUnitID: String?, completion: ((Result<Void, Error>) -> Void)?)` | Load ad với callback |
| `AdMobLibrary.appOpen.load(adUnitID: String?) async throws` | Load ad với async/await |
| `AdMobLibrary.appOpen.preload(adUnitID: String?)` | Preload ad |
| `AdMobLibrary.appOpen.show(onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị ad |
| `AdMobLibrary.appOpen.showIfAvailable(onDismiss: (() -> Void)?, onFailed: ((Error) -> Void)?) -> Bool` | Hiển thị nếu có sẵn và đủ điều kiện |
| `AdMobLibrary.appOpen.isAdAvailable` | Kiểm tra ad có sẵn và còn hợp lệ (Bool) |
| `AdMobLibrary.appOpen.canShowAd` | Kiểm tra có thể hiển thị (Bool) |
| `AdMobLibrary.appOpen.isLoaded` | Kiểm tra ad đã load (Bool) |
| `AdMobLibrary.appOpen.isLoading` | Kiểm tra đang load (Bool) |
| `AdMobLibrary.appOpen.isShowing` | Kiểm tra đang hiển thị (Bool) |
| `AdMobLibrary.appOpen.error` | Lỗi nếu có (Error?) |
| `AdMobLibrary.appOpen.events` | Event callbacks (FullScreenAdEvents?) |
| `AdMobLibrary.appOpen.autoShowOnForeground` | Tự động hiển thị khi foreground (Bool) |
| `AdMobLibrary.appOpen.minimumInterval` | Khoảng thời gian tối thiểu giữa các lần hiển thị (TimeInterval) |
| `AdMobLibrary.appOpen.adExpirationHours` | Thời gian hết hạn ad (Double, mặc định 4 giờ) |

**Ví dụ:**
```swift
await AppOpenAdHandler.configureAsync(
    adUnitID: "ca-app-pub-xxxxx/app-open",
    autoShowOnForeground: true,
    minimumInterval: 60
)
AdMobLibrary.appOpen.showIfAvailable()
```

### Native Ads

| API | Mô tả |
|-----|-------|
| `AdMobLibrary.native.load(adUnitID: String?, completion: ((Result<NativeAd, Error>) -> Void)?)` | Load ad với callback (trả về NativeAd) |
| `AdMobLibrary.native.load(adUnitID: String?) async throws -> NativeAd` | Load ad với async/await (trả về NativeAd) |
| `AdMobLibrary.native.preload(adUnitID: String?)` | Preload ad |
| `AdMobLibrary.native.isLoaded` | Kiểm tra ad đã sẵn sàng (Bool) |
| `AdMobLibrary.native.isLoading` | Kiểm tra đang load (Bool) |
| `AdMobLibrary.native.nativeAd` | Lấy NativeAd đã load (NativeAd?) |
| `AdMobLibrary.native.error` | Lỗi nếu có (Error?) |
| `AdMobLibrary.native.events` | Event callbacks (NativeAdEvents?) |
| `NativeAdView(adUnitID: String?, customView: ((NativeAd) -> AnyView)?, events: NativeAdEvents?)` | SwiftUI View với layout mặc định hoặc custom |
| `NativeAdView(adUnitID: String?, events: NativeAdEvents?)` | SwiftUI View với layout mặc định |
| `NativeAdView.refresh()` | Reload ad trong NativeAdView |
| `CustomNativeAdView(adUnitID: String?, nibName: String, bundle: Bundle?, events: NativeAdEvents?)` | SwiftUI View với custom XIB |
| `CustomNativeAdView.refresh()` | Reload ad trong CustomNativeAdView |
| `NativeAdLoader(events: NativeAdEvents?)` | Tạo loader cho UIKit/custom XIB |
| `NativeAdLoader.load(adUnitID: String?, rootViewController: UIViewController?, completion: ((Result<NativeAd, Error>) -> Void)?)` | Load ad với callback |
| `NativeAdLoader.load(adUnitID: String?, rootViewController: UIViewController?) async throws -> NativeAd` | Load ad với async/await |
| `NativeAdLoader.displayAd(nibName: String, bundle: Bundle?, in containerView: UIView) -> GADNativeAdView?` | Hiển thị ad vào container từ XIB |
| `NativeAdLoader.refresh(rootViewController: UIViewController?)` | Reload ad |
| `NativeAdLoader.isLoaded` | Kiểm tra ad đã load (Bool) |
| `NativeAdLoader.isLoading` | Kiểm tra đang load (Bool) |
| `NativeAdLoader.nativeAd` | Lấy NativeAd đã load (NativeAd?) |
| `NativeAdLoader.error` | Lỗi nếu có (Error?) |
| `NativeAdState.load(adUnitID: String?)` | Load ad trong NativeAdView (internal) |

**Ví dụ:**
```swift
// SwiftUI - Layout mặc định
NativeAdView(adUnitID: "ca-app-pub-xxxxx/native")

// SwiftUI - Custom layout
NativeAdView(customView: { nativeAd in
    AnyView(VStack {
        Text(nativeAd.headline ?? "")
    })
})

// SwiftUI - Custom XIB
CustomNativeAdView(nibName: "CustomNativeAdView")

// Singleton manager
AdMobLibrary.native.load(adUnitID: "ca-app-pub-xxxxx/native") { result in
    if case .success(let nativeAd) = result {
        print("Loaded: \(nativeAd.headline ?? "")")
    }
}

// UIKit
let loader = NativeAdLoader()
loader.load(adUnitID: "ca-app-pub-xxxxx/native") { result in
    if case .success = result {
        loader.displayAd(nibName: "CustomNativeAdView", in: containerView)
    }
}
```

### GDPR Consent

| API | Mô tả |
|-----|-------|
| `ConsentManager.shared.requestConsentInfoUpdate(tagForUnderAgeOfConsent: Bool, completion: ((Result<Void, Error>) -> Void)?)` | Yêu cầu thông tin consent với callback |
| `ConsentManager.shared.requestConsentInfoUpdate(tagForUnderAgeOfConsent: Bool) async throws` | Yêu cầu thông tin consent với async/await |
| `ConsentManager.shared.showConsentFormIfRequired(from viewController: UIViewController?, completion: ((Result<Void, Error>) -> Void)?)` | Hiển thị form nếu cần với callback |
| `ConsentManager.shared.showConsentFormIfRequired(from viewController: UIViewController?) async throws` | Hiển thị form nếu cần với async/await |
| `ConsentManager.shared.showPrivacyOptionsForm(from viewController: UIViewController?, completion: ((Result<Void, Error>) -> Void)?)` | Hiển thị privacy options form với callback |
| `ConsentManager.shared.showPrivacyOptionsForm(from viewController: UIViewController?) async throws` | Hiển thị privacy options form với async/await |
| `ConsentManager.shared.canRequestAds` | Kiểm tra có thể request ads (Bool) |
| `ConsentManager.shared.canShowPrivacyOptionsForm` | Kiểm tra có thể hiển thị privacy options (Bool) |
| `ConsentManager.shared.reset()` | Reset consent (dùng cho testing) |
| `ConsentManager.shared.requestConsentAndInitializeAds(adUnitIDs: AdMobManager.AdUnitIDs?, completion: ((Result<Void, Error>) -> Void)?)` | Request consent và khởi tạo ads với callback |
| `ConsentManager.shared.requestConsentAndInitializeAds(adUnitIDs: AdMobManager.AdUnitIDs?) async throws` | Request consent và khởi tạo ads với async/await |
| `.requestAdConsent(onComplete: @escaping (Bool) -> Void)` | SwiftUI View Modifier để tự động xử lý consent |
| `PrivacyOptionsButton(title: String)` | SwiftUI View hiển thị nút privacy settings |

**Ví dụ:**
```swift
// Tự động xử lý
ContentView()
    .requestAdConsent { canShowAds in
        if canShowAds {
            AdMobLibrary.preloadAllAds()
        }
    }

// Thủ công
try await ConsentManager.shared.requestConsentInfoUpdate()
try await ConsentManager.shared.showConsentFormIfRequired()
if ConsentManager.shared.canRequestAds {
    await AdMobLibrary.initialize()
}

// Privacy button
PrivacyOptionsButton(title: "Manage Ad Preferences")
```

### Reload Ads

| Loại | Cách Reload |
|------|-------------|
| Banner | `.id(UUID())` trên view |
| Interstitial | `AdMobLibrary.interstitial.load()` |
| Rewarded | `AdMobLibrary.rewarded.load()` |
| Rewarded Interstitial | `AdMobLibrary.rewardedInterstitial.load()` |
| App Open | `AdMobLibrary.appOpen.load()` |
| Native | `AdMobLibrary.native.load()` hoặc `.refresh()` |
| Tất cả | `AdMobLibrary.preloadAllAds()` |

---

## 🧪 Testing

### Test Device

```swift
await AdMobLibrary.initialize(
    testDeviceIdentifiers: ["YOUR_DEVICE_HASHED_ID"]
)
```

Lấy device ID từ log:
```
<Google> To get test ads on this device, set: 
GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = ["YOUR_ID"]
```

### Test Ad Unit IDs (Mặc định)

| Loại | Ad Unit ID |
|------|------------|
| Banner | `ca-app-pub-3940256099942544/2934735716` |
| Interstitial | `ca-app-pub-3940256099942544/4411468910` |
| Rewarded | `ca-app-pub-3940256099942544/1712485313` |
| Rewarded Interstitial | `ca-app-pub-3940256099942544/6978759866` |
| App Open | `ca-app-pub-3940256099942544/5575463023` |
| Native | `ca-app-pub-3940256099942544/3986624511` |

---

## 📁 Cấu trúc thư viện

```
AdMobLibrary/
├── AdMobLibrary.swift          # Entry point
├── AdMobManager.swift          # SDK Manager
├── AdEventCallbacks.swift      # Event definitions
├── BannerAdView.swift          # Banner Ads
├── InterstitialAdManager.swift # Interstitial Ads
├── RewardedAdManager.swift     # Rewarded Ads
├── AppOpenAdManager.swift      # App Open Ads
├── NativeAdView.swift          # Native Ads
└── ConsentManager.swift        # GDPR Consent
```

---

## 📄 License

MIT License
