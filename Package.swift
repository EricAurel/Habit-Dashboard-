// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HabitDashboard",
    defaultLocalization: "de",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "HabitDashboard", targets: ["HabitDashboard"]),
        .library(name: "HabitCore", targets: ["HabitCore"]),
    ],
    targets: [
        // Plattformunabhängige Logik: Datenmodell, Streaks, Speicherung, Übungen.
        .target(name: "HabitCore"),
        // macOS-App: Desktop-Panel, Menüleiste, Aktivitätsmonitor, Übungs-Popup.
        .executableTarget(
            name: "HabitDashboard",
            dependencies: ["HabitCore"]
        ),
        .testTarget(
            name: "HabitCoreTests",
            dependencies: ["HabitCore"]
        ),
    ]
)
