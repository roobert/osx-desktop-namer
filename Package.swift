// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DesktopNamer",
    platforms: [.macOS(.v13)],
    targets: [
        .target(
            name: "CGSBridge",
            dependencies: [],
            linkerSettings: [
                .linkedFramework("CoreGraphics")
            ]
        ),
        .executableTarget(
            name: "DesktopNamer",
            dependencies: ["CGSBridge"]
        )
    ]
)
