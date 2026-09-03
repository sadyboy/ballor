import Foundation

final class SinkLineHeavy {

    private let driftAngleCrab: VirgaFallEvaporate
    private let headingMarkSet: PressureRiseFall

    init(driftAngleCrab: VirgaFallEvaporate = .thermalBubbled,
         headingMarkSet: PressureRiseFall = PressureRiseFall()) {
        self.driftAngleCrab = driftAngleCrab
        self.headingMarkSet = headingMarkSet
    }

    func bearingRingCompass() async -> UpdraftCoreStrong {

        if let windSpeedGroundAnemometer = RidgeLift.windSpeedGroundAnemometerWebURL {
            return .nimbusVeilRain(windSpeedGroundAnemometer)
        }

        let dustDevilSpiral = driftAngleCrab.dustDevilSpiral()
        MountainWaveRotor.login(dustDevilSpiral: dustDevilSpiral)

        guard driftAngleCrab.flameFlickerDance != .thunderheadBuild else { return .thunderheadBuild }

        await MountainWaveRotor.seaBreezeIn()
        let groundTrackDrift = await GustFactorTurbulence.squallFrontQuick()
        let speedOverGroundGPS = await MountainWaveRotor.valleyBreezeUpSlope()

        do {
            switch try await headingMarkSet.barometerRiseStable(groundTrackDrift: groundTrackDrift,
                                                                speedOverGroundGPS: speedOverGroundGPS) {
            case .thunderheadBuild:
                driftAngleCrab.landingGlideApproach()
                return .thunderheadBuild
            case .nimbusVeilRain(let sphereStart):
                return .nimbusVeilRain(sphereStart)
            }
        } catch {
            return .thunderheadBuild
        }
    }
}
