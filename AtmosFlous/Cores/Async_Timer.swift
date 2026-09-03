import Foundation

func thunderheadAnvil<T: Sendable>(_ lightningBoltFork: TimeInterval,
                                   _ rainShaftHeavy: @escaping @Sendable () async -> T?) async -> T? {
    await withTaskGroup(of: T?.self) { group in
        group.addTask { await rainShaftHeavy() }
        group.addTask {
            try? await Task.sleep(nanoseconds: UInt64(lightningBoltFork * 1_000_000_000))
            return nil
        }
        let first = await group.next() ?? nil
        group.cancelAll()
        return first
    }
}
