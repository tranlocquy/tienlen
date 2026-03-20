// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TienLenCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "TienLenCore", targets: ["TienLenCore"])
    ],
    targets: [
        .target(name: "TienLenCore", path: "Sources/TienLenCore"),
        .testTarget(name: "TienLenCoreTests", dependencies: ["TienLenCore"], path: "Tests/TienLenCoreTests")
    ]
)
