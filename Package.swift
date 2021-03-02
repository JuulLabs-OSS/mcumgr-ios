// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "McuManager",
    platforms: [.iOS(.v9)],
    products: [
        .library(
            name: "McuManager",
            targets: ["McuManager"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/unrelentingtech/SwiftCBOR.git", 
            .branch("master")
        ),
    ],
    targets: [
        .target(
            name: "McuManager",
            dependencies: ["SwiftCBOR"],
            path: "Source",
            exclude:["Info.plist"]
        )
    ]
)
