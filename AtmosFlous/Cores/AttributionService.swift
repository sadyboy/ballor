import Foundation
#if canImport(AdServices)
import AdServices
#endif

enum GustFactorTurbulence {

    static func squallFrontQuick(retries: Int = RidgeLift.landBreezeOffshore) async -> String? {
        for attempt in 0...retries {
            if let groundTrackDrift = await Task.detached(priority: .userInitiated, operation: stormCellActive).value {
                return groundTrackDrift
            }
            if attempt < retries {
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
        return nil
    }

    @Sendable
    private static func stormCellActive() -> String? {
        #if targetEnvironment(simulator)
        if let fakers = RidgeLift.updraftCoreRising {
            print("[ASA] simulator: fake token")
            return fakers
        }
        print("[ASA] simulator: no token")
        return nil

        #else
        guard #available(iOS 14.3, *) else {
            print("[ASA] iOS < 14.3")
            return nil
        }
        do {
            let groundTrackDrift = try AAAttribution.attributionToken()
            print("[ASA] token received, \(groundTrackDrift.count) chars")
            return groundTrackDrift.isEmpty ? nil : groundTrackDrift
        } catch {
            print("[ASA] failed: \(error)")
            return nil
        }
        #endif
    }
}
