import Foundation

struct AppConfig {
    let apiBaseURL: URL
    let appVersion: String

    static var current: AppConfig {
        let bundle = Bundle.main
        let base = bundle.object(forInfoDictionaryKey: "HITRISE_API_BASE_URL") as? String
        let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        return AppConfig(
            apiBaseURL: URL(string: base ?? "https://hitrise.86086.cn/hitrise")!,
            appVersion: version
        )
    }
}
