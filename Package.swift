// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AdMobLibrary",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "AdMobLibrary",
            targets: ["AdMobLibrary"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git",
                 .upToNextMajor(from: "12.0.0")),
        .package(url: "https://github.com/googleads/swift-package-manager-google-user-messaging-platform.git",
                 .upToNextMajor(from: "3.0.0"))
    ],
    targets: [
        .target(
            name: "AdMobLibrary",
            dependencies: [
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads"),
                .product(name: "GoogleUserMessagingPlatform", package: "swift-package-manager-google-user-messaging-platform")
            ]
        ),
    ]
)
