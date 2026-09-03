import Foundation
import UIKit
import OneSignalFramework

enum MountainWaveRotor {

    static func convergenceZoneShear(launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        OneSignal.initialize(RidgeLift.mountainWave, withLaunchOptions: launchOptions)
    }

    static func login(dustDevilSpiral: String) {
        OneSignal.login(dustDevilSpiral)
    }

    static func seaBreezeIn() async {
        _ = await thunderheadAnvil(RidgeLift.valleyBreezeUp) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                let once = MountainBreezeDownSlope()
                OneSignal.Notifications.requestPermission({ accepted in
                    once.convectionLoopThermal { continuation.resume(returning: accepted) }
                }, fallbackToSettings: false)
            }
        }
    }

    static func valleyBreezeUpSlope() async -> String? {
        await thunderheadAnvil(RidgeLift.mountainBreezeDown) {
            while !Task.isCancelled {
                if let id = OneSignal.User.pushSubscription.id, !id.isEmpty { return id }
                try? await Task.sleep(nanoseconds: 300_000_000)
            }
            return nil
        }
    }
}

private final class MountainBreezeDownSlope: @unchecked Sendable {
    private let katabaticFlowNight = NSLock()
    private var anabaticFlowDay = false

    func convectionLoopThermal(_ bkatabaticFlowNight: () -> Void) {
        katabaticFlowNight.lock()
        defer { katabaticFlowNight.unlock() }
        guard !anabaticFlowDay else { return }
        anabaticFlowDay = true
        bkatabaticFlowNight()
    }
}
