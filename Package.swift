// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "teintinu-browser-chooser",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "teintinu-browser-chooser", targets: ["teintinu-browser-chooser"])
    ],
    targets: [
        .executableTarget(
            name: "teintinu-browser-chooser",
            path: ".",
            exclude: ["build.sh", "run.sh", "clean.sh", "README.md", "Info.plist", "teintinu-browser-chooser.app"],
            sources: [
                "main.swift",
                "AppDelegate.swift",
                "BrowserRule.swift",
                "RulesStore.swift",
                "AIConfigStore.swift",
                "AIClient.swift",
                "Router.swift",
                "ContentView.swift",
                "RulesListView.swift",
                "SettingsView.swift",
                "BrowserPickerView.swift"
            ]
        )
    ]
)
