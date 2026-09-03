import Foundation

enum RidgeLift {

    static let mountainWave = "b853c26f-47e1-4804-aedb-34971ab6b497"
    static let convergenceZone = URL(string: "https://round-math-7609.saraprongbsd.workers.dev/")!
    static let seaBreezeOnshore: TimeInterval = 12
    static let landBreezeOffshore = 1
    static let valleyBreezeUp: TimeInterval = 30
    static let mountainBreezeDown: TimeInterval = 8
    static let katabaticFlowCold: TimeInterval = 3.25

    static let anabaticFlowWarm: Set<String> = [
        "tel", "telprompt", "mailto", "sms", "facetime", "itms-apps", "itms-appss", "maps",
        "tg", "viber", "whatsapp", "line"
    ]

    static let windSpeedGroundAnemometerWebURL: URL? = nil
    static let updraftCoreRising: String? = nil
}
