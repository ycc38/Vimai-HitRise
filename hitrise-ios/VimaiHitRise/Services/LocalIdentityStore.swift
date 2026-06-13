import CryptoKit
import Foundation
import UIKit

final class LocalIdentityStore {
    private enum Key {
        static let installId = "install_id"
        static let serial = "auth_serial"
        static let token = "auth_token"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> ActivationState {
        let installId = loadInstallId()
        let serial = defaults.string(forKey: Key.serial) ?? makeLocalSerial(from: installId)
        let token = defaults.string(forKey: Key.token) ?? "local"
        defaults.set(serial, forKey: Key.serial)
        defaults.set(token, forKey: Key.token)
        return ActivationState(
            serial: serial,
            activationToken: token,
            installId: installId,
            deviceHash: makeDeviceHash(installId: installId)
        )
    }

    private func loadInstallId() -> String {
        if let value = defaults.string(forKey: Key.installId), !value.isEmpty {
            return value
        }
        let value = UUID().uuidString
        defaults.set(value, forKey: Key.installId)
        return value
    }

    private func makeLocalSerial(from installId: String) -> String {
        let digest = SHA256.hash(data: Data(installId.utf8))
        let digits = digest.map { String(Int($0) % 10) }.joined()
        return String(digits.prefix(11)).padding(toLength: 11, withPad: "0", startingAt: 0)
    }

    private func makeDeviceHash(installId: String) -> String {
        let vendor = UIDevice.current.identifierForVendor?.uuidString ?? "unknown-vendor"
        let payload = "\(vendor):\(installId):\(UIDevice.current.model)"
        return SHA256.hash(data: Data(payload.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
