import Foundation

public struct FlightPrediction: Equatable {
    public let gasMass: Double
    public let launchGasVolume: Double
    public let freeLift: Double
    public let neckLift: Double
    public let ascentRate: Double
    public let burstAltitude: Double
    public let timeToBurst: TimeInterval
    public let descentDuration: TimeInterval
    public let landingSpeed: Double
    public let horizontalDrift: Double
    public let gasCost: Double

    public var totalDuration: TimeInterval { timeToBurst + descentDuration }
}

public enum FlightSolver {

    // MARK: - Geometry & forces

    public static func envelopeDiameter(gasMass: Double, gas: LiftGas, altitude: Double) -> Double {
        let air = Atmosphere.sample(at: altitude)
        let gasDensity = gas.density(pressure: air.pressure, temperature: air.temperature)
        guard gasDensity > 0 else { return .infinity }
        let volume = gasMass / gasDensity
        return pow(6 * volume / .pi, 1.0 / 3.0)
    }

    public static func netForce(gasMass: Double,
                                gas: LiftGas,
                                dryMass: Double,
                                altitude: Double) -> Double {
        let air = Atmosphere.sample(at: altitude)
        let gasDensity = gas.density(pressure: air.pressure, temperature: air.temperature)
        let volume = gasMass / gasDensity
        let displaced = air.density * volume
        return (displaced - gasMass - dryMass) * Atmosphere.g0
    }

    public static func terminalAscentRate(gasMass: Double,
                                          gas: LiftGas,
                                          dryMass: Double,
                                          dragCoefficient: Double,
                                          altitude: Double) -> Double {
        let force = netForce(gasMass: gasMass, gas: gas, dryMass: dryMass, altitude: altitude)
        guard force > 0 else { return 0 }
        let air = Atmosphere.sample(at: altitude)
        let diameter = envelopeDiameter(gasMass: gasMass, gas: gas, altitude: altitude)
        let area = .pi * pow(diameter, 2) / 4
        return sqrt(2 * force / (air.density * dragCoefficient * area))
    }

    public static func descentRate(mass: Double, parachute: ParachuteSpec, altitude: Double) -> Double {
        let air = Atmosphere.sample(at: altitude)
        guard air.density > 0 else { return 0 }
        return sqrt(2 * mass * Atmosphere.g0 / (air.density * parachute.dragCoefficient * parachute.area))
    }

    // MARK: - Burst altitude

    public static func burstAltitude(gasMass: Double, gas: LiftGas, spec: BalloonSpec) -> Double {
        var low = 0.0
        var high = 50_000.0

        guard envelopeDiameter(gasMass: gasMass, gas: gas, altitude: high) >= spec.burstDiameter else {
            return high
        }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            if envelopeDiameter(gasMass: gasMass, gas: gas, altitude: mid) < spec.burstDiameter {
                low = mid
            } else {
                high = mid
            }
        }
        return (low + high) / 2
    }

    // MARK: - Inverse problem

    public static func gasVolume(forTargetAscentRate target: Double,
                                 blueprint: MissionBlueprint) -> Double {
        let ground = Atmosphere.sample(at: blueprint.launchElevation)
        let dryMass = blueprint.totalMass
        var low = 0.1
        var high = 40.0

        func rate(forVolume volume: Double) -> Double {
            let mass = volume * blueprint.gas.density(pressure: ground.pressure,
                                                      temperature: ground.temperature)
            return terminalAscentRate(gasMass: mass,
                                      gas: blueprint.gas,
                                      dryMass: dryMass,
                                      dragCoefficient: blueprint.balloon.dragCoefficient,
                                      altitude: blueprint.launchElevation)
        }

        for _ in 0..<60 {
            let mid = (low + high) / 2
            if rate(forVolume: mid) < target { low = mid } else { high = mid }
        }
        return (low + high) / 2
    }

    // MARK: - Full prediction

    public static func predict(_ blueprint: MissionBlueprint,
                               gasPricePerCubicMeter: Double? = nil) -> FlightPrediction {
        let ground = Atmosphere.sample(at: blueprint.launchElevation)
        let gasDensity = blueprint.gas.density(pressure: ground.pressure, temperature: ground.temperature)
        let gasMass = blueprint.launchGasVolume * gasDensity
        let dryMass = blueprint.totalMass

        let displaced = ground.density * blueprint.launchGasVolume
        let freeLift = displaced - gasMass - dryMass
        let neckLift = displaced - gasMass - blueprint.balloon.mass

        let ascentRate = terminalAscentRate(gasMass: gasMass,
                                            gas: blueprint.gas,
                                            dryMass: dryMass,
                                            dragCoefficient: blueprint.balloon.dragCoefficient,
                                            altitude: blueprint.launchElevation)

        let burst = burstAltitude(gasMass: gasMass, gas: blueprint.gas, spec: blueprint.balloon)

        let step = 50.0
        var ascentTime: TimeInterval = 0
        var drift = 0.0
        var h = blueprint.launchElevation

        while h < burst {
            let v = terminalAscentRate(gasMass: gasMass,
                                       gas: blueprint.gas,
                                       dryMass: dryMass,
                                       dragCoefficient: blueprint.balloon.dragCoefficient,
                                       altitude: h)
            guard v > 0.05 else { break }
            let dt = step / v
            ascentTime += dt
            drift += Atmosphere.windSpeed(at: h) * dt
            h += step
        }

        let descentMass = blueprint.payloadMass + blueprint.balloon.mass * 0.5
        var descentTime: TimeInterval = 0
        h = burst
        while h > blueprint.launchElevation {
            let v = descentRate(mass: descentMass, parachute: blueprint.parachute, altitude: h)
            guard v > 0.05 else { break }
            let dt = step / v
            descentTime += dt
            drift += Atmosphere.windSpeed(at: h) * dt
            h -= step
        }

        let price = gasPricePerCubicMeter ?? blueprint.gas.defaultPricePerCubicMeter

        return FlightPrediction(
            gasMass: gasMass,
            launchGasVolume: blueprint.launchGasVolume,
            freeLift: freeLift,
            neckLift: neckLift,
            ascentRate: ascentRate,
            burstAltitude: burst,
            timeToBurst: ascentTime,
            descentDuration: descentTime,
            landingSpeed: descentRate(mass: descentMass,
                                      parachute: blueprint.parachute,
                                      altitude: blueprint.launchElevation),
            horizontalDrift: drift,
            gasCost: blueprint.launchGasVolume * price
        )
    }

    public static func warnings(for prediction: FlightPrediction,
                                blueprint: MissionBlueprint) -> [String] {
        var result: [String] = []
        if prediction.freeLift <= 0 {
            result.append("No free lift — balloon won't take off. Add gas or reduce payload.")
        }
        if prediction.ascentRate < 3 && prediction.freeLift > 0 {
            result.append("Ascent slower than 3 m/s: balloon spends more time in the jet stream, drift will increase.")
        }
        if prediction.ascentRate > 7 {
            result.append("Ascent faster than 7 m/s: envelope will burst below the calculated ceiling.")
        }
        if prediction.landingSpeed > 6 {
            result.append("Landing at \(String(format: "%.1f", prediction.landingSpeed)) m/s. Use a larger parachute.")
        }
        if prediction.horizontalDrift > 120_000 {
            result.append("Calculated drift exceeds 120 km. Check that your recovery team can reach that far.")
        }
        if let note = blueprint.gas.safetyNote {
            result.append(note)
        }
        return result
    }
}
