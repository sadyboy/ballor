import Foundation
import Combine

/// Телеметрия — «сплющенное» состояние для HUD. Отдельный тип, чтобы
/// UI не перерисовывался на каждое микроизменение физики.
public struct Telemetry: Equatable {
    public let altitude: Int
    public let verticalSpeed: Double
    public let temperature: Double
    public let pressure: Double
    public let strain: Double
    public let ballast: Double
    public let layerName: String
    public let phase: FlightPhase
    public let elapsed: TimeInterval

    init(_ state: FlightState) {
        let air = Atmosphere.sample(at: state.altitude)
        altitude = Int(state.altitude.rounded())
        verticalSpeed = (state.verticalSpeed * 10).rounded() / 10
        temperature = (air.temperatureCelsius * 10).rounded() / 10
        pressure = (air.pressure * 10).rounded() / 10
        strain = (state.envelopeStrain * 1000).rounded() / 1000
        ballast = (state.ballastRemaining * 100).rounded() / 100
        layerName = air.layer.name
        phase = state.phase
        elapsed = state.elapsed.rounded()
    }
}

/// Чистый детерминированный движок. Не знает ни про SpriteKit, ни про UIKit.
/// Такт задаёт сцена, состояние раздаётся через Combine — поэтому один и тот же
/// движок можно прогнать в юнит-тесте на 10 000 шагов без единого кадра.
public final class MissionEngine {

    // MARK: Публикуемое состояние

    @Published public private(set) var state: FlightState
    public let events = PassthroughSubject<MissionEvent, Never>()

    public let blueprint: MissionBlueprint

    /// Поток для HUD: дедуплицированный и прореженный до 10 Гц.
    public lazy var telemetry: AnyPublisher<Telemetry, Never> = $state
        .map(Telemetry.init)
        .removeDuplicates()
        .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
        .eraseToAnyPublisher()

    /// Поток для оформления: высота → визуальный «настрой» сцены.
    public lazy var skyProgress: AnyPublisher<Double, Never> = $state
        .map { min(1, max(0, $0.altitude / 35_000)) }
        .map { ($0 * 200).rounded() / 200 }   // квантуем: перекрашиваться чаще нет смысла
        .removeDuplicates()
        .eraseToAnyPublisher()

    /// Поток для гаптики.
    public lazy var turbulence: AnyPublisher<Double, Never> = $state
        .map { Atmosphere.turbulence(at: $0.altitude) }
        .map { ($0 * 20).rounded() / 20 }
        .removeDuplicates()
        .eraseToAnyPublisher()

    // MARK: Внутреннее

    private var lastLayerIndex: Int
    private var lastStrainWarning: Double = 0
    private var pendingSampleAltitudes: [Double]
    private var timeScale: Double

    public init(blueprint: MissionBlueprint, timeScale: Double = 60) {
        self.blueprint = blueprint
        self.state = .initial(for: blueprint)
        self.lastLayerIndex = Atmosphere.sample(at: blueprint.launchElevation).layerIndex
        self.timeScale = timeScale
        // Научные точки: игрок должен успеть нажать «замер» в узком окне высоты.
        self.pendingSampleAltitudes = [2_000, 5_500, 9_000, 11_000, 16_000, 22_000, 28_000]
    }

    // MARK: Управление

    public func launch() {
        guard state.phase == .preflight else { return }
        state.phase = .ascent
        events.send(.launched)
    }

    /// Сброс балласта: мгновенный прирост подъёмной силы ценой невозвратного ресурса.
    @discardableResult
    public func dropBallast(_ kilograms: Double) -> Bool {
        guard state.phase == .ascent, state.ballastRemaining > 0 else { return false }
        let amount = min(kilograms, state.ballastRemaining)
        state.ballastRemaining -= amount
        events.send(.ballastDropped(kilograms: amount, altitude: state.altitude))
        return true
    }

    /// Стравливание газа: снижает нагрузку на оболочку и отодвигает разрыв,
    /// но урезает потолок. Главный тактический выбор игры.
    @discardableResult
    public func vent(for duration: TimeInterval) -> Bool {
        guard state.phase == .ascent else { return false }
        let rate = 0.0035 * state.gasMass   // кг/с
        let amount = min(rate * duration, state.gasMass * 0.5)
        state.gasMass -= amount
        events.send(.gasVented(kilograms: amount, altitude: state.altitude))
        return true
    }

    /// Замер: засчитывается только внутри окна ±250 м от целевой высоты.
    @discardableResult
    public func captureSample() -> Bool {
        guard let index = pendingSampleAltitudes.firstIndex(where: { abs($0 - state.altitude) < 250 })
        else { return false }
        pendingSampleAltitudes.remove(at: index)
        state.samplesCaptured += 1
        let air = Atmosphere.sample(at: state.altitude)
        events.send(.sampleCaptured(altitude: state.altitude,
                                    temperature: air.temperatureCelsius,
                                    pressure: air.pressure))
        return true
    }

    // MARK: Интегрирование

    /// Один шаг. `dt` — реальное время кадра; внутри умножается на timeScale,
    /// чтобы полёт длиной 2,5 часа укладывался в игровую сессию.
    public func tick(dt: TimeInterval) {
        guard state.phase == .ascent || state.phase == .descent else { return }
        let step = dt * timeScale
        state.elapsed += step

        switch state.phase {
        case .ascent:  integrateAscent(step)
        case .descent: integrateDescent(step)
        default: break
        }

        state.horizontalDrift += Atmosphere.windSpeed(at: state.altitude) * step
        state.peakAltitude = max(state.peakAltitude, state.altitude)
        detectLayerChange()
    }

    private func integrateAscent(_ dt: TimeInterval) {
        let dryMass = blueprint.balloon.mass + blueprint.payloadMass + state.ballastRemaining

        let target = FlightSolver.terminalAscentRate(gasMass: state.gasMass,
                                                     gas: blueprint.gas,
                                                     dryMass: dryMass,
                                                     dragCoefficient: blueprint.balloon.dragCoefficient,
                                                     altitude: state.altitude)

        // Экспоненциальная релаксация к установившейся скорости —
        // даёт естественную «инерцию» после сброса балласта.
        let tau = 8.0
        state.verticalSpeed += (target - state.verticalSpeed) * (1 - exp(-dt / tau))
        state.altitude = max(blueprint.launchElevation, state.altitude + state.verticalSpeed * dt)

        let diameter = FlightSolver.envelopeDiameter(gasMass: state.gasMass,
                                                     gas: blueprint.gas,
                                                     altitude: state.altitude)
        state.envelopeDiameter = diameter
        state.envelopeStrain = diameter / blueprint.balloon.burstDiameter

        if state.envelopeStrain >= 0.9, state.envelopeStrain - lastStrainWarning >= 0.02 {
            lastStrainWarning = state.envelopeStrain
            events.send(.strainWarning(level: state.envelopeStrain))
        }

        if state.envelopeStrain >= 1 {
            state.phase = .burst
            state.verticalSpeed = 0
            events.send(.burst(altitude: state.altitude, elapsed: state.elapsed))
            state.phase = .descent
        }

        if target <= 0.05, state.altitude > blueprint.launchElevation + 100 {
            // Шар «завис»: нейтральная плавучесть. Тоже валидный исход миссии.
            state.verticalSpeed = 0
        }
    }

    private func integrateDescent(_ dt: TimeInterval) {
        let mass = blueprint.payloadMass + blueprint.balloon.mass * 0.5
        let target = -FlightSolver.descentRate(mass: mass,
                                               parachute: blueprint.parachute,
                                               altitude: state.altitude)
        let tau = 4.0
        state.verticalSpeed += (target - state.verticalSpeed) * (1 - exp(-dt / tau))
        state.altitude += state.verticalSpeed * dt

        if state.altitude <= blueprint.launchElevation {
            state.altitude = blueprint.launchElevation
            state.verticalSpeed = 0
            state.phase = .landed
            events.send(.landed(drift: state.horizontalDrift, elapsed: state.elapsed))
        }
    }

    private func detectLayerChange() {
        let index = Atmosphere.sample(at: state.altitude).layerIndex
        guard index != lastLayerIndex else { return }
        lastLayerIndex = index
        events.send(.enteredLayer(index: index, name: Atmosphere.layers[index].name))
    }
}
