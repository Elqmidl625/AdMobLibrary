# AdMobLibrary

Thư viện quảng cáo AdMob hoàn chỉnh cho SwiftUI, hỗ trợ tất cả các loại quảng cáo và GDPR Consent.

## Tính năng

- ✅ **Banner Ads** - Nhiều kích thước (Adaptive, Standard, Large, Medium Rectangle...)
- ✅ **Interstitial Ads** - Quảng cáo toàn màn hình
- ✅ **Rewarded Ads** - Quảng cáo có thưởng
- ✅ **Rewarded Interstitial Ads** - Quảng cáo toàn màn hình có thưởng
- ✅ **App Open Ads** - Quảng cáo khi mở app
- ✅ **Native Ads** - Quảng cáo tự nhiên với custom layout
- ✅ **Native Ads với Custom XIB** - Hỗ trợ load từ XIB/Storyboard
- ✅ **Event Callbacks** - Bắt tất cả các sự kiện (impression, click, dismiss...)
- ✅ **GDPR Consent** - Hỗ trợ Google UMP cho EU/EEA

## Cài đặt

### Swift Package Manager

Thêm vào `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/AdMobLibrary.git", from: "1.0.0")
]
```

Hoặc trong Xcode:
1. File > Add Packages...
2. Nhập URL repository
3. Chọn version

### Yêu cầu

- iOS 15.0+
- Xcode 15.0+
- Swift 5.9+

## Cấu hình Info.plist

Thêm các key sau vào `Info.plist`:

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

## Sử dụng

### Khởi tạo

```swift
import AdMobLibrary

@main
struct MyApp: App {
    init() {
        Task {
            // Cách 1: Khởi tạo đơn giản (sử dụng test IDs)
            await AdMobLibrary.initialize()
            
            // Cách 2: Với custom Ad Unit IDs
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
            
            // Cách 3: Với GDPR consent handling
            await AdMobLibrary.initialize(handleConsent: true)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### Banner Ads

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            // Nội dung app
            
            Spacer()
            
            // Banner adaptive (khuyến nghị)
            BannerAdView.adaptive()
            
            // Hoặc các kích thước khác
            // BannerAdView.standard()      // 320x50
            // BannerAdView.large()         // 320x100
            // BannerAdView.mediumRectangle() // 300x250
            
            // Với custom Ad Unit ID
            // BannerAdView(adUnitID: "ca-app-pub-xxxxx/banner")
        }
    }
}
```

### Interstitial Ads

```swift
struct GameView: View {
    @State private var showInterstitial = false
    
    var body: some View {
        VStack {
            Button("Next Level") {
                showInterstitial = true
            }
        }
        .interstitialAd(isPresented: $showInterstitial) {
            print("Ad dismissed, continue to next level")
        }
        .onAppear {
            // Preload ad
            AdMobLibrary.interstitial.preload()
        }
    }
}

// Hoặc sử dụng trực tiếp
func showAd() {
    AdMobLibrary.interstitial.showAndReload(
        onDismiss: {
            print("Ad closed")
        },
        onFailed: { error in
            print("Failed: \(error)")
        }
    )
}
```

### Rewarded Ads

```swift
struct StoreView: View {
    @State private var coins = 0
    @State private var showRewardedAd = false
    
    var body: some View {
        VStack {
            Text("Coins: \(coins)")
            
            Button("Watch Ad for 100 Coins") {
                showRewardedAd = true
            }
            .disabled(!AdMobLibrary.rewarded.isLoaded)
        }
        .rewardedAd(isPresented: $showRewardedAd) { reward in
            coins += reward.amount
            print("Earned \(reward.amount) \(reward.type)")
        }
        .onAppear {
            AdMobLibrary.rewarded.preload(
                adUnitID: "ca-app-pub-xxxxx/rewarded"  
            )
        }
    }
}

// Hoặc sử dụng trực tiếp
func watchAd() {
    AdMobLibrary.rewarded.showAndReload(
        onReward: { reward in
            print("Reward: \(reward.amount) \(reward.type)")
        },
        onDismiss: {
            print("Ad closed")
        }
    )
}
```

### App Open Ads

> ⚠️ **Lưu ý quan trọng:** App Open Ads chỉ hiển thị khi app **trở lại từ background**, KHÔNG hiển thị lần mở đầu tiên.

```swift
@main
struct MyApp: App {
    init() {
        Task {
            // 1. Khởi tạo SDK trước
            await AdMobLibrary.initialize()
            
            // 2. Setup App Open Ads (dùng configureAsync trong Task)
            await AppOpenAdHandler.configureAsync(
                adUnitID: "ca-app-pub-xxxxx/app-open",  // Hoặc nil để dùng test ID
                autoShowOnForeground: true,
                minimumInterval: 60 // Tối thiểu 60 giây giữa các lần hiển thị
            )
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// Hiển thị thủ công
func showAppOpenAd() {
    AdMobLibrary.appOpen.showIfAvailable()
}
```

#### Khi nào App Open Ads hiển thị?

| Tình huống | Hiển thị? |
|------------|-----------|
| Mở app lần đầu | ❌ Không |
| App từ background → foreground | ✅ Có |
| Chuyển từ app khác về | ✅ Có |
| Sau khi tắt màn hình và mở lại | ✅ Có |

#### Cách test App Open Ads

1. Chạy app
2. Nhấn nút Home (hoặc vuốt lên) để đưa app vào background
3. Mở lại app → App Open Ad sẽ hiển thị

### Native Ads

```swift
// Cách 1: Layout mặc định (đơn giản nhất)
NativeAdView()
    .frame(height: 200)

// Cách 2: Với Event Callbacks
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

// Cách 3: Với custom SwiftUI layout + Events
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
    },
    events: NativeAdEvents(
        onAdLoaded: { _ in print("Loaded") },
        onAdClicked: { print("Clicked") }
    )
)

// Cách 4: Trong danh sách/feed
struct FeedView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<20, id: \.self) { index in
                    Text("Item \(index)")
                    
                    // Hiển thị native ad sau mỗi 5 items
                    if index % 5 == 0 && index > 0 {
                        NativeAdView(
                            events: NativeAdEvents(
                                onAdImpression: {
                                    print("Ad at index \(index) shown")
                                }
                            )
                        )
                        .frame(height: 200)
                    }
                }
            }
        }
    }
}
```

### Native Ads với Custom XIB/Storyboard

#### Bước 1: Tạo file XIB

1. Trong Xcode: **File > New > File > View**
2. Đặt tên (ví dụ: `CustomNativeAdView.xib`)
3. Trong XIB, đổi class của root view thành **GADNativeAdView** (từ GoogleMobileAds)
4. Thêm các UI elements và kết nối với outlets:

| Outlet | Kiểu UI | Mô tả |
|--------|---------|-------|
| `headlineView` | UILabel | Tiêu đề ad |
| `bodyView` | UILabel | Mô tả |
| `iconView` | UIImageView | Icon app |
| `callToActionView` | UIButton/UILabel | Nút CTA |
| `advertiserView` | UILabel | Tên nhà quảng cáo |
| `mediaView` | GADMediaView | Video/Image |
| `storeView` | UILabel | Store name |
| `priceView` | UILabel | Giá |

#### Bước 2: Sử dụng trong code

**SwiftUI - Cơ bản:**

```swift
import AdMobLibrary

struct ContentView: View {
    var body: some View {
        // Sử dụng custom XIB (đơn giản nhất)
        CustomNativeAdView(
            nibName: "CustomNativeAdView"  // Tên file XIB (không có .xib)
        )
        .frame(height: 300)
    }
}
```

**SwiftUI - Với Ad Unit ID và Events:**

```swift
struct ContentView: View {
    var body: some View {
        CustomNativeAdView(
            adUnitID: "ca-app-pub-xxxxx/native",  // Optional, mặc định dùng test ID
            nibName: "CustomNativeAdView",
            bundle: nil,  // nil = Bundle.main
            events: NativeAdEvents(
                onAdLoaded: { nativeAd in
                    print("✅ Ad loaded: \(nativeAd.headline ?? "")")
                    print("   Body: \(nativeAd.body ?? "")")
                    print("   CTA: \(nativeAd.callToAction ?? "")")
                },
                onAdFailedToLoad: { error in
                    print("❌ Failed to load: \(error.localizedDescription)")
                },
                onAdImpression: {
                    print("📊 Impression recorded")
                    // Analytics tracking
                },
                onAdClicked: {
                    print("👆 Ad clicked")
                    // Analytics tracking
                },
                onAdWillPresentScreen: {
                    print("📱 Opening full screen...")
                },
                onAdDidDismissScreen: {
                    print("📱 Full screen closed")
                },
                onAdWillLeaveApplication: {
                    print("🚪 User leaving app")
                }
            )
        )
        .frame(height: 300)
    }
}
```

**UIKit - Với NativeAdLoader:**

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

#### Ví dụ cấu trúc XIB

```
CustomNativeAdView.xib
└── GADNativeAdView (Custom Class: GADNativeAdView, Module: GoogleMobileAds)
    ├── UIImageView (iconView outlet)
    ├── UILabel (headlineView outlet)
    ├── UILabel (bodyView outlet)
    ├── UILabel (advertiserView outlet)
    ├── GADMediaView (mediaView outlet)
    └── UIButton (callToActionView outlet)
```

> **Lưu ý:** Thư viện sẽ tự động bind dữ liệu từ native ad vào các outlets đã kết nối trong XIB.

### Event Callbacks (Bắt các sự kiện của Ads)

Thư viện hỗ trợ đầy đủ các event callbacks để bắt các hành động/sự kiện của quảng cáo.

#### Các loại Events

**Banner Ad Events (`BannerAdEvents`)**

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad đã được load thành công |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ad đã ghi nhận impression |
| `onAdClicked` | Ad đã được click |
| `onAdWillPresentScreen` | Ad sẽ present full screen |
| `onAdWillDismissScreen` | Ad sẽ dismiss full screen |
| `onAdDidDismissScreen` | Ad đã dismiss full screen |

**Full Screen Ad Events (`FullScreenAdEvents`)**
Áp dụng cho: Interstitial, Rewarded, Rewarded Interstitial, App Open

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad đã được load thành công |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ad đã ghi nhận impression |
| `onAdClicked` | Ad đã được click |
| `onAdFailedToPresent` | Ad present thất bại |
| `onAdWillPresent` | Ad sẽ present |
| `onAdWillDismiss` | Ad sẽ dismiss |
| `onAdDidDismiss` | Ad đã dismiss |

**Native Ad Events (`NativeAdEvents`)**

| Event | Mô tả |
|-------|-------|
| `onAdLoaded` | Ad đã được load (trả về NativeAd) |
| `onAdFailedToLoad` | Ad load thất bại |
| `onAdImpression` | Ad đã ghi nhận impression |
| `onAdClicked` | Ad đã được click |
| `onAdWillPresentScreen` | Ad sẽ present screen |
| `onAdWillDismissScreen` | Ad sẽ dismiss screen |
| `onAdDidDismissScreen` | Ad đã dismiss screen |
| `onAdWillLeaveApplication` | Ad sẽ rời khỏi app |

#### Cách sử dụng Event Callbacks

**Banner Ads**

```swift
// Truyền events vào View
BannerAdView(
    adUnitID: "your-ad-unit-id",
    adSize: .adaptive,
    events: BannerAdEvents(
        onAdLoaded: {
            print("Banner loaded!")
        },
        onAdFailedToLoad: { error in
            print("Banner failed: \(error)")
        },
        onAdImpression: {
            print("Banner impression recorded")
        },
        onAdClicked: {
            print("Banner clicked!")
        },
        onAdWillPresentScreen: {
            print("Banner will present full screen")
        },
        onAdDidDismissScreen: {
            print("Banner full screen dismissed")
        }
    )
)
```

**Interstitial Ads**

```swift
// Setup events
InterstitialAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: {
        print("Interstitial ready!")
    },
    onAdImpression: {
        print("Interstitial impression")
    },
    onAdClicked: {
        print("Interstitial clicked")
    },
    onAdWillPresent: {
        print("Interstitial will show")
        // Pause game, music, etc.
    },
    onAdDidDismiss: {
        print("Interstitial closed")
        // Resume game, music, etc.
    }
)

// Load và hiển thị
AdMobLibrary.interstitial.preload()
```

**Rewarded Ads**

```swift
// Setup events
RewardedAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: {
        print("Rewarded ad ready!")
    },
    onAdImpression: {
        print("Rewarded ad impression")
    },
    onAdClicked: {
        print("Rewarded ad clicked")
    },
    onAdDidDismiss: {
        print("Rewarded ad closed")
    }
)

// Global callback khi user nhận reward
RewardedAdManager.shared.onUserEarnedReward = { reward in
    print("User earned \(reward.amount) \(reward.type)")
}

// Hoặc callback trong show()
AdMobLibrary.rewarded.show(
    onReward: { reward in
        coins += reward.amount
    }
)
```

**App Open Ads**

```swift
// Setup events
AppOpenAdManager.shared.events = FullScreenAdEvents(
    onAdLoaded: {
        print("App Open Ad ready")
    },
    onAdImpression: {
        print("App Open Ad shown")
    },
    onAdWillPresent: {
        print("App Open Ad presenting")
        // Pause background music
    },
    onAdDidDismiss: {
        print("App Open Ad closed")
        // Resume app functionality
    }
)

// Configure
await AppOpenAdHandler.configureAsync(autoShowOnForeground: true)
```

**Native Ads**

```swift
// Cách 1: NativeAdView với events (SwiftUI - Đơn giản nhất)
NativeAdView(
    events: NativeAdEvents(
        onAdLoaded: { nativeAd in
            print("✅ Ad loaded: \(nativeAd.headline ?? "")")
        },
        onAdFailedToLoad: { error in
            print("❌ Failed: \(error)")
        },
        onAdImpression: {
            print("📊 Impression")
        },
        onAdClicked: {
            print("👆 Clicked")
        }
    )
)

// Cách 2: NativeAdView với custom layout + events
NativeAdView(
    customView: { nativeAd in
        AnyView(
            VStack {
                Text(nativeAd.headline ?? "")
                Text(nativeAd.body ?? "")
            }
        )
    },
    events: NativeAdEvents(
        onAdLoaded: { _ in print("Loaded") },
        onAdClicked: { print("Clicked") }
    )
)

// Cách 3: CustomNativeAdView với XIB + events
CustomNativeAdView(
    nibName: "CustomNativeAdView",
    events: NativeAdEvents(
        onAdLoaded: { nativeAd in
            print("Custom native ad loaded!")
        },
        onAdImpression: {
            print("Impression recorded")
        },
        onAdClicked: {
            print("Ad clicked")
        }
    )
)

// Cách 4: NativeAdManager.shared (singleton - dùng chung toàn app)
NativeAdManager.shared.events = NativeAdEvents(
    onAdLoaded: { nativeAd in
        print("Native ad loaded!")
    },
    onAdClicked: {
        print("User clicked native ad")
    }
)

// Cách 5: NativeAdLoader (UIKit hoặc cần control chi tiết)
let loader = NativeAdLoader(events: NativeAdEvents(
    onAdLoaded: { nativeAd in
        print("Ad loaded")
    },
    onAdClicked: {
        print("Ad clicked")
    }
))
loader.load()
```

#### Ví dụ Analytics Integration

```swift
import FirebaseAnalytics // hoặc bất kỳ analytics SDK nào

func setupAdTracking() {
    // Interstitial tracking
    InterstitialAdManager.shared.events = FullScreenAdEvents(
        onAdImpression: {
            Analytics.logEvent("ad_impression", parameters: [
                "ad_type": "interstitial"
            ])
        },
        onAdClicked: {
            Analytics.logEvent("ad_click", parameters: [
                "ad_type": "interstitial"
            ])
        }
    )
    
    // Rewarded tracking
    RewardedAdManager.shared.events = FullScreenAdEvents(
        onAdImpression: {
            Analytics.logEvent("ad_impression", parameters: [
                "ad_type": "rewarded"
            ])
        }
    )
    RewardedAdManager.shared.onUserEarnedReward = { reward in
        Analytics.logEvent("ad_reward_earned", parameters: [
            "reward_type": reward.type,
            "reward_amount": reward.amount
        ])
    }
}
```

### GDPR Consent

```swift
// Tự động xử lý consent khi view xuất hiện
struct ContentView: View {
    var body: some View {
        MainView()
            .requestAdConsent { canShowAds in
                if canShowAds {
                    AdMobLibrary.preloadAllAds()
                }
            }
    }
}

// Hiển thị nút Privacy Settings
struct SettingsView: View {
    var body: some View {
        Form {
            Section("Privacy") {
                PrivacyOptionsButton(title: "Manage Ad Preferences")
            }
        }
    }
}

// Xử lý thủ công
func handleConsent() async {
    do {
        try await ConsentManager.shared.requestConsentInfoUpdate()
        try await ConsentManager.shared.showConsentFormIfRequired()
        
        if ConsentManager.shared.canRequestAds {
            await AdMobLibrary.initialize()
        }
    } catch {
        print("Consent error: \(error)")
    }
}
```

## Tóm tắt API

### Các hàm chính cho từng loại Ads

#### Banner Ads

| Hàm | Mô tả |
|-----|-------|
| `BannerAdView.adaptive()` | Tạo banner adaptive (khuyến nghị) |
| `BannerAdView.standard()` | Tạo banner 320x50 |
| `BannerAdView.large()` | Tạo banner 320x100 |
| `BannerAdView.mediumRectangle()` | Tạo banner 300x250 |
| `BannerAdView(adUnitID:adSize:)` | Tạo banner với custom ID và size |
| Reload: `.id(UUID())` | Force reload bằng cách thay đổi id của view |

#### Interstitial Ads

| Hàm | Mô tả |
|-----|-------|
| `AdMobLibrary.interstitial.preload()` | Preload ad |
| `AdMobLibrary.interstitial.load(adUnitID:completion:)` | Load ad với callback |
| `AdMobLibrary.interstitial.show(onDismiss:onFailed:)` | Hiển thị ad |
| `AdMobLibrary.interstitial.showAndReload(...)` | Hiển thị và tự động load lại |
| `AdMobLibrary.interstitial.isLoaded` | Kiểm tra ad đã sẵn sàng |
| `.interstitialAd(isPresented:onDismiss:)` | SwiftUI View Modifier |

#### Rewarded Ads

| Hàm | Mô tả |
|-----|-------|
| `AdMobLibrary.rewarded.preload(adUnitID:)` | Preload ad |
| `AdMobLibrary.rewarded.load(adUnitID:completion:)` | Load ad với callback |
| `AdMobLibrary.rewarded.show(onReward:onDismiss:onFailed:)` | Hiển thị ad |
| `AdMobLibrary.rewarded.showAndReload(...)` | Hiển thị và tự động load lại |
| `AdMobLibrary.rewarded.isLoaded` | Kiểm tra ad đã sẵn sàng |
| `AdMobLibrary.rewarded.rewardInfo` | Lấy thông tin phần thưởng |
| `.rewardedAd(isPresented:onReward:onDismiss:)` | SwiftUI View Modifier |

#### Rewarded Interstitial Ads

| Hàm | Mô tả |
|-----|-------|
| `AdMobLibrary.rewardedInterstitial.preload()` | Preload ad |
| `AdMobLibrary.rewardedInterstitial.load(...)` | Load ad |
| `AdMobLibrary.rewardedInterstitial.show(...)` | Hiển thị ad |
| `AdMobLibrary.rewardedInterstitial.showAndReload(...)` | Hiển thị và tự động load lại |
| `AdMobLibrary.rewardedInterstitial.isLoaded` | Kiểm tra ad đã sẵn sàng |

#### App Open Ads

| Hàm | Mô tả |
|-----|-------|
| `AppOpenAdHandler.configureAsync(...)` | Cấu hình auto-show (trong Task) |
| `AppOpenAdHandler.configure(...)` | Cấu hình auto-show (MainActor) |
| `AdMobLibrary.appOpen.load(adUnitID:completion:)` | Load ad |
| `AdMobLibrary.appOpen.show(onDismiss:onFailed:)` | Hiển thị ad |
| `AdMobLibrary.appOpen.showIfAvailable()` | Hiển thị nếu có sẵn |
| `AdMobLibrary.appOpen.preload()` | Preload ad |
| `AdMobLibrary.appOpen.isAdAvailable` | Kiểm tra ad có sẵn |
| `AdMobLibrary.appOpen.canShowAd` | Kiểm tra có thể hiển thị |

#### Native Ads

| Hàm | Mô tả |
|-----|-------|
| `NativeAdView(events:)` | View với layout mặc định + events |
| `NativeAdView(customView:events:)` | View với custom SwiftUI layout + events |
| `CustomNativeAdView(nibName:bundle:events:)` | View với custom XIB + events |
| `AdMobLibrary.native.load(adUnitID:completion:)` | Load ad (singleton) |
| `AdMobLibrary.native.preload()` | Preload ad |
| `NativeAdLoader(events:).load(...)` | Load ad (instance) với events |
| `NativeAdLoader().displayAd(nibName:in:)` | Hiển thị vào container |
| `NativeAdLoader().refresh()` | Reload ad |

#### GDPR Consent

| Hàm | Mô tả |
|-----|-------|
| `ConsentManager.shared.requestConsentInfoUpdate()` | Yêu cầu thông tin consent |
| `ConsentManager.shared.showConsentFormIfRequired()` | Hiển thị form nếu cần |
| `ConsentManager.shared.showPrivacyOptionsForm()` | Hiển thị privacy options |
| `ConsentManager.shared.canRequestAds` | Kiểm tra có thể request ads |
| `ConsentManager.shared.reset()` | Reset consent (testing) |
| `.requestAdConsent(onComplete:)` | SwiftUI View Modifier |
| `PrivacyOptionsButton(title:)` | Nút privacy settings |

### Reload Ads

| Loại Ad | Cách Reload |
|---------|-------------|
| Banner | Thay đổi `.id(UUID())` của view |
| Interstitial | `AdMobLibrary.interstitial.load()` |
| Rewarded | `AdMobLibrary.rewarded.load()` |
| Rewarded Interstitial | `AdMobLibrary.rewardedInterstitial.load()` |
| App Open | `AdMobLibrary.appOpen.load()` |
| Native | `AdMobLibrary.native.load()` hoặc `loader.refresh()` |
| Tất cả | `AdMobLibrary.preloadAllAds()` |

## Test Ads

Thư viện mặc định sử dụng Test Ad Unit IDs của Google. Để test trên thiết bị thật, thêm device ID:

```swift
await AdMobLibrary.initialize(
    testDeviceIdentifiers: ["YOUR_DEVICE_HASHED_ID"]
)
```

Để lấy device ID, xem log khi chạy app:
```
<Google> To get test ads on this device, set: GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ "YOUR_DEVICE_HASHED_ID" ]
```

## Test Ad Unit IDs (Mặc định)

| Loại | Ad Unit ID |
|------|------------|
| Banner | ca-app-pub-3940256099942544/2934735716 |
| Interstitial | ca-app-pub-3940256099942544/4411468910 |
| Rewarded | ca-app-pub-3940256099942544/1712485313 |
| Rewarded Interstitial | ca-app-pub-3940256099942544/6978759866 |
| App Open | ca-app-pub-3940256099942544/5575463023 |
| Native | ca-app-pub-3940256099942544/3986624511 |

## Cấu trúc thư viện

```
AdMobLibrary/
├── AdMobLibrary.swift          # Entry point & exports
├── AdMobManager.swift          # Singleton quản lý SDK
├── AdEventCallbacks.swift      # Định nghĩa các event callbacks
├── BannerAdView.swift          # Banner Ads cho SwiftUI
├── InterstitialAdManager.swift # Interstitial Ads
├── RewardedAdManager.swift     # Rewarded & Rewarded Interstitial Ads
├── AppOpenAdManager.swift      # App Open Ads
├── NativeAdView.swift          # Native Ads cho SwiftUI
└── ConsentManager.swift        # GDPR Consent (UMP)
```

## License

MIT License
