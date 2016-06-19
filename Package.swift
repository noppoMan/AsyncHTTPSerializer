import PackageDescription

let package = Package(
    name: "AsyncHTTPSerializer",
    dependencies: [
        .Package(url: "https://github.com/open-swift/S4.git", majorVersion: 0, minor: 9),
        .Package(url: "https://github.com/Zewo/URI.git", majorVersion: 0, minor: 8)
    ]
)
