import Foundation

// MARK: - Gas

public enum LiftGas: String, CaseIterable, Codable, Identifiable {
    case helium
    case hydrogen

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .helium:   return "Helium"
        case .hydrogen: return "Hydrogen"
        }
    }

    public var specificGasConstant: Double {
        switch self {
        case .helium:   return 2077.1
        case .hydrogen: return 4124.2
        }
    }

    public var defaultPricePerCubicMeter: Double {
        switch self {
        case .helium:   return 420
        case .hydrogen: return 95
        }
    }

    public var safetyNote: String? {
        self == .hydrogen
            ? "Flammable. Launch in open areas only, away from all ignition sources."
            : nil
    }

    public func density(pressure: Double, temperature: Double) -> Double {
        pressure / (specificGasConstant * temperature)
    }
}

// MARK: - Balloon

public struct BalloonSpec: Codable, Hashable, Identifiable {
    public let model: String
    public let mass: Double
    public let burstDiameter: Double
    public let dragCoefficient: Double

    public var id: String { model }

    public init(model: String, mass: Double, burstDiameter: Double, dragCoefficient: Double = 0.25) {
        self.model = model
        self.mass = mass
        self.burstDiameter = burstDiameter
        self.dragCoefficient = dragCoefficient
    }

    /// Totex/Kaymont reference values. Verify against your batch datasheet before a real launch.
    public static let catalog: [BalloonSpec] = [
        BalloonSpec(model: "TX-200",  mass: 0.20, burstDiameter: 3.00),
        BalloonSpec(model: "TX-350",  mass: 0.35, burstDiameter: 4.72),
        BalloonSpec(model: "TX-600",  mass: 0.60, burstDiameter: 6.02),
        BalloonSpec(model: "TX-800",  mass: 0.80, burstDiameter: 7.00),
        BalloonSpec(model: "TX-1000", mass: 1.00, burstDiameter: 7.86),
        BalloonSpec(model: "TX-1200", mass: 1.20, burstDiameter: 8.63),
        BalloonSpec(model: "TX-1600", mass: 1.60, burstDiameter: 10.54),
        BalloonSpec(model: "TX-3000", mass: 3.00, burstDiameter: 13.00)
    ]
}

public struct ParachuteSpec: Codable, Hashable {
    public let diameter: Double
    public let dragCoefficient: Double

    public init(diameter: Double, dragCoefficient: Double = 1.5) {
        self.diameter = diameter
        self.dragCoefficient = dragCoefficient
    }

    public var area: Double { .pi * pow(diameter, 2) / 4 }

    public static let standard = ParachuteSpec(diameter: 1.2)
}

// MARK: - Mission Blueprint

public struct MissionBlueprint: Codable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var balloon: BalloonSpec
    public var gas: LiftGas
    public var payloadMass: Double
    public var ballastMass: Double
    public var launchGasVolume: Double
    public var parachute: ParachuteSpec
    public var launchElevation: Double
    public var createdAt: Date

    public var totalMass: Double { balloon.mass + payloadMass + ballastMass }

    public init(id: UUID = UUID(),
                name: String = "Unnamed Mission",
                balloon: BalloonSpec = BalloonSpec.catalog[4],
                gas: LiftGas = .helium,
                payloadMass: Double = 1.2,
                ballastMass: Double = 0.4,
                launchGasVolume: Double = 4.2,
                parachute: ParachuteSpec = .standard,
                launchElevation: Double = 179,
                createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.balloon = balloon
        self.gas = gas
        self.payloadMass = payloadMass
        self.ballastMass = ballastMass
        self.launchGasVolume = launchGasVolume
        self.parachute = parachute
        self.launchElevation = launchElevation
        self.createdAt = createdAt
    }
}

// MARK: - Flight State

public enum FlightPhase: String, Codable {
    case preflight, ascent, burst, descent, landed, lost
}

public struct FlightState: Equatable {
    public var elapsed: TimeInterval
    public var altitude: Double
    public var verticalSpeed: Double
    public var horizontalDrift: Double
    public var gasMass: Double
    public var ballastRemaining: Double
    public var envelopeDiameter: Double
    public var envelopeStrain: Double
    public var phase: FlightPhase
    public var peakAltitude: Double
    public var samplesCaptured: Int

    public static func initial(for blueprint: MissionBlueprint) -> FlightState {
        let ground = Atmosphere.sample(at: blueprint.launchElevation)
        let gasDensity = blueprint.gas.density(pressure: ground.pressure, temperature: ground.temperature)
        let gasMass = blueprint.launchGasVolume * gasDensity
        let diameter = pow(6 * blueprint.launchGasVolume / .pi, 1.0 / 3.0)

        return FlightState(elapsed: 0,
                           altitude: blueprint.launchElevation,
                           verticalSpeed: 0,
                           horizontalDrift: 0,
                           gasMass: gasMass,
                           ballastRemaining: blueprint.ballastMass,
                           envelopeDiameter: diameter,
                           envelopeStrain: diameter / blueprint.balloon.burstDiameter,
                           phase: .preflight,
                           peakAltitude: blueprint.launchElevation,
                           samplesCaptured: 0)
    }
}

// MARK: - Events

public enum MissionEvent: Equatable {
    case launched
    case enteredLayer(index: Int, name: String)
    case ballastDropped(kilograms: Double, altitude: Double)
    case gasVented(kilograms: Double, altitude: Double)
    case burst(altitude: Double, elapsed: TimeInterval)
    case sampleCaptured(altitude: Double, temperature: Double, pressure: Double)
    case landed(drift: Double, elapsed: TimeInterval)
    case strainWarning(level: Double)
}
