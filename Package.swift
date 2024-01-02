// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-study",
    products: [
        .library(
            name: "swift-study",
            targets: ["swift-study"]),
    ],
    targets: [
        .target(
            name: "swift-study"
        ),
    ]
)
