// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "guardix",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(name: "guardix", targets: ["guardix"])
    ],
    targets: [
        .target(
            name: "guardix",
            dependencies: [],
            path: "Classes"
        )
    ]
)