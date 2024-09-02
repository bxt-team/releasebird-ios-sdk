// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Releasebird",
    platforms: [.iOS(.v12)],
    products: [
        .library(
            name: "Releasebird",
            targets: ["Releasebird"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
           name: "Releasebird",
           dependencies: [],
           path: "releasebird-ios-sdk/Classes/",
           resources: [.copy("../PrivacyInfo.xcprivacy")],
           publicHeadersPath: ".",
           cSettings: [
              .headerSearchPath("Internal"),
           ]
        ),
        .testTarget(
            name: "ReleasebirdTests",
            dependencies: ["Releasebird"]),
    ]
)