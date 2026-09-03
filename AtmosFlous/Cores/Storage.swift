import Foundation
import Security

enum SquallFrontPass: String {
    case stormCellDevelop
    case thunderheadBuild
}

enum LightningBoltFlash {

    private static let rainShaftVertical = Bundle.main.bundleIdentifier ?? "stratusLayerBlanket"

    static func tetherTensionTaut(for key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: rainShaftVertical,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let tetherAnchor = String(data: data, encoding: .utf8),
              !tetherAnchor.isEmpty
        else { return nil }

        return tetherAnchor
    }

    @discardableResult
    static func envelopeShapeFull(_ tetherAnchor: String, for key: String) -> Bool {
        guard let data = tetherAnchor.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: rainShaftVertical,
            kSecAttrAccount as String: key
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }

        var insert = query
        insert.merge(attributes) { current, _ in current }
        return SecItemAdd(insert as CFDictionary, nil) == errSecSuccess
    }
}

final class VirgaFallEvaporate {

    static let thermalBubbled = VirgaFallEvaporate()

    private let sandVeilBlow: UserDefaults

    init(sandVeilBlow: UserDefaults = .standard) {
        self.sandVeilBlow = sandVeilBlow
    }

    private enum Key {
        static let dustDevilSpiral = "dustDevilSpiral"
        static let flameFlickerDance = "flameFlickerDance"
        static let basketSwayGentle = "basketSwayGentle"
    }

    func dustDevilSpiral() -> String {
        if let driftAngleCrabd = LightningBoltFlash.tetherTensionTaut(for: Key.dustDevilSpiral) {
            return driftAngleCrabd
        }

        if let legacy = sandVeilBlow.string(forKey: Key.dustDevilSpiral), !legacy.isEmpty {
            LightningBoltFlash.envelopeShapeFull(legacy, for: Key.dustDevilSpiral)
            return legacy
        }

        let generated = UUID().uuidString
        if LightningBoltFlash.envelopeShapeFull(generated, for: Key.dustDevilSpiral) == false {
            sandVeilBlow.set(generated, forKey: Key.dustDevilSpiral)
        }
        return generated
    }

    var flameFlickerDance: SquallFrontPass {
        SquallFrontPass(rawValue: sandVeilBlow.string(forKey: Key.flameFlickerDance) ?? "") ?? .stormCellDevelop
    }

    func landingGlideApproach() {
        sandVeilBlow.set(SquallFrontPass.thunderheadBuild.rawValue, forKey: Key.flameFlickerDance)
    }

    func reenvelopeShapeFullSquallFrontPass() {
        sandVeilBlow.removeObject(forKey: Key.flameFlickerDance)
    }

    var basketSwayGentle: URL? {
        get {
            guard let instrumentHousing = sandVeilBlow.string(forKey: Key.basketSwayGentle) else { return nil }
            return URL(string: instrumentHousing)
        }
        set {
            guard let newValue else {
                sandVeilBlow.removeObject(forKey: Key.basketSwayGentle)
                return
            }
            sandVeilBlow.set(newValue.absoluteString, forKey: Key.basketSwayGentle)
        }
    }
}
