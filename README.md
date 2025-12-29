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
struct FeedView: View {
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(items) { item in
                    ItemView(item: item)
                    
                    // Hiển thị native ad sau mỗi 5 items
                    if item.index % 5 == 0 {
                        NativeAdView()
                            .frame(height: 200)
                    }
                }
            }
        }
    }
}

// Với custom SwiftUI layout
NativeAdView { nativeAd in
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

**SwiftUI:**

```swift
import AdMobLibrary

struct ContentView: View {
    var body: some View {
        // Sử dụng custom XIB
        CustomNativeAdView(
            adUnitID: "ca-app-pub-xxxxx/native",
            nibName: "CustomNativeAdView"  // Tên file XIB (không có .xib)
        )
        .frame(height: 300)
    }
}

// Nếu XIB nằm trong framework/module khác
CustomNativeAdView(
    adUnitID: "ca-app-pub-xxxxx/native",
    nibName: "CustomNativeAdView",
    bundle: Bundle(for: MyFrameworkClass.self)
)
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
├── AdMobLibrary.swift      # Entry point & exports
├── AdMobManager.swift      # Singleton quản lý SDK
├── BannerAdView.swift      # Banner Ads cho SwiftUI
├── InterstitialAdManager.swift  # Interstitial Ads
├── RewardedAdManager.swift      # Rewarded & Rewarded Interstitial Ads
├── AppOpenAdManager.swift       # App Open Ads
├── NativeAdView.swift           # Native Ads cho SwiftUI
└── ConsentManager.swift         # GDPR Consent (UMP)
```

## License

MIT License
