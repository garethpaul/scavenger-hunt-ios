// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "ScavengerHuntPolicies",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "ScavengerHuntPolicies", targets: ["ScavengerHuntPolicies"]),
    ],
    targets: [
        .target(
            name: "ScavengerHuntPolicies",
            path: "Sources/ScavengerHuntPolicies"
        ),
        .testTarget(
            name: "ScavengerHuntPoliciesTests",
            dependencies: ["ScavengerHuntPolicies"],
            path: "PolicyTests"
        ),
    ]
)
