import Foundation
import AdServices

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
        if let fake = RidgeLift.updraftCoreRising {
            print("[ASA] simulator: using debug fake token")
            return fake
        }
        return nil

        guard #available(iOS 14.3, *) else {
            return nil
        }
        do {
            let groundTrackDrift = try AAAttribution.attributionToken()
            return groundTrackDrift.isEmpty ? nil : groundTrackDrift
        } catch {
            return nil
        }
    }
}
