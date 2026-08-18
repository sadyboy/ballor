import SpriteKit
import Combine

/// Сцена подъёма. Важное отличие от жанра: здесь ничего не анимируется «на глаз».
/// Оболочка раздувается ровно на столько, на сколько её раздувает расчётный
/// объём газа, небо темнеет по модели атмосферы, звёзды проступают там,
/// где падает рассеяние. Анимация — следствие физики, а не отдельный слой поверх.
public final class AscentScene: SKScene {

    // MARK: Узлы

    private let skyNode = SKSpriteNode()
    private let starfield = SKNode()
    private let hazeNode = SKNode()
    private let cloudDeck = SKNode()
    // Character sprite replaces the painted envelope; texture switches with strain
    private let balloonSprite = SKSpriteNode()
    private var currentCharTexture = ""
    private let payload = SKShapeNode(rectOf: CGSize(width: 26, height: 18), cornerRadius: 2)
    private let tether = SKShapeNode()
    private let sampleMarker = SKShapeNode(circleOfRadius: 26)

    // MARK: Состояние отрисовки

    private let engine: MissionEngine
    private var cancellables = Set<AnyCancellable>()
    private var lastUpdate: TimeInterval = 0
    private var lastSkyBucket: Int = -1
    private var referenceDiameter: Double = 1
    private var lastAltitude: Double = 0

    /// Высота шара на экране — фиксирована. Движется мир, а не камера:
    /// так дешевле и так честнее читается идея «шар стоит, атмосфера уходит вниз».
    private var anchorY: CGFloat { size.height * 0.42 }

    public init(engine: MissionEngine, size: CGSize) {
        self.engine = engine
        super.init(size: size)
        scaleMode = .resizeFill
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) не используется") }

    // MARK: Жизненный цикл

    public override func didMove(to view: SKView) {
        backgroundColor = Palette.sky(at: 0).bottom
        referenceDiameter = engine.state.envelopeDiameter
        lastAltitude = engine.state.altitude

        buildSky()
        buildAtmosphereLayers()
        buildBalloon()
        bind()
    }

    private func buildSky() {
        // Game art background (sits behind sky gradient)
        let gameBg = SKSpriteNode(imageNamed: "gameBal")
        gameBg.anchorPoint = .zero
        gameBg.position = .zero
        gameBg.size = size
        gameBg.zPosition = -110
        addChild(gameBg)

        skyNode.anchorPoint = .zero
        skyNode.position = .zero
        skyNode.size = size
        skyNode.zPosition = -100
        skyNode.alpha = 0.72  // semi-transparent so gameBal art shows through
        addChild(skyNode)
        updateSkyTexture(for: engine.state.altitude, force: true)

        starfield.zPosition = -90
        starfield.alpha = 0
        addChild(starfield)

        // Звёзды раскладываем один раз, детерминированно от seed —
        // чтобы у одной и той же миссии небо было одним и тем же.
        var generator = SeededGenerator(seed: 0xA9_06_1E)
        for _ in 0..<160 {
            let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 0.6...1.6, using: &generator))
            star.fillColor = .white
            star.strokeColor = .clear
            star.alpha = CGFloat.random(in: 0.35...1, using: &generator)
            star.position = CGPoint(x: CGFloat.random(in: 0...size.width, using: &generator),
                                    y: CGFloat.random(in: 0...size.height * 1.4, using: &generator))
            starfield.addChild(star)
        }
    }

    private func buildAtmosphereLayers() {
        hazeNode.zPosition = -80
        addChild(hazeNode)
        cloudDeck.zPosition = -60
        addChild(cloudDeck)

        // Three depth layers (far / mid / near) with matching parallax factors.
        let parallaxByLayer: [Double] = [0.15, 0.42, 0.75]
        var generator = SeededGenerator(seed: 0x33_7F_02)
        for index in 0..<18 {
            let cloud = SKSpriteNode(imageNamed: "cloudes")
            let scale = CGFloat.random(in: 0.35...1.15, using: &generator)
            cloud.setScale(scale)
            cloud.alpha = CGFloat.random(in: 0.55...0.92, using: &generator)
            cloud.position = CGPoint(
                x: CGFloat.random(in: -80...size.width + 80, using: &generator),
                y: CGFloat.random(in: -size.height * 0.8...size.height * 1.8, using: &generator)
            )
            cloud.userData = ["parallax": parallaxByLayer[index % 3]]
            cloudDeck.addChild(cloud)
        }
    }

    private func buildBalloon() {
        // Character sprite — texture switches at runtime based on envelope strain
        balloonSprite.texture = SKTexture(imageNamed: "char_3")
        balloonSprite.zPosition = 10
        balloonSprite.position = CGPoint(x: size.width / 2, y: anchorY)
        addChild(balloonSprite)

        payload.fillColor = Palette.brass
        payload.strokeColor = Palette.inkDeep
        payload.lineWidth = 1
        payload.zPosition = 11
        addChild(payload)

        tether.strokeColor = Palette.inkDeep.withAlphaComponent(0.7)
        tether.lineWidth = 1
        tether.zPosition = 9
        addChild(tether)

        sampleMarker.strokeColor = Palette.verdigris
        sampleMarker.lineWidth = 2
        sampleMarker.fillColor = .clear
        sampleMarker.zPosition = 5
        sampleMarker.alpha = 0
        addChild(sampleMarker)

        updateEnvelopeGeometry(diameter: engine.state.envelopeDiameter, strain: engine.state.envelopeStrain)
    }

    private func bind() {
        engine.$state
            .throttle(for: .milliseconds(80), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] state in
                guard let self else { return }
                self.updateEnvelopeGeometry(diameter: state.envelopeDiameter, strain: state.envelopeStrain)
                self.updateSkyTexture(for: state.altitude, force: false)
                self.starfield.alpha = Palette.starOpacity(at: state.altitude)
            }
            .store(in: &cancellables)

        engine.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in self?.react(to: event) }
            .store(in: &cancellables)
    }

    // MARK: Кадр

    public override func update(_ currentTime: TimeInterval) {
        defer { lastUpdate = currentTime }
        guard lastUpdate > 0 else { return }

        let dt = min(currentTime - lastUpdate, 1.0 / 20.0)   // защита от рывка после сворачивания
        engine.tick(dt: dt)

        let delta = engine.state.altitude - lastAltitude
        lastAltitude = engine.state.altitude
        scrollWorld(byAltitude: delta)
        applyTurbulence()
    }

    /// Мир едет вниз. Уменьшенный metresPerPoint даёт выраженное ощущение подъёма.
    private func scrollWorld(byAltitude delta: Double) {
        guard delta != 0 else { return }
        // 0.45 m/pt  →  at 5 m/s ascent the world scrolls ~11 pt/s — clearly visible
        let metresPerPoint = 0.45

        for node in cloudDeck.children {
            let parallax = node.userData?["parallax"] as? Double ?? 0.42
            node.position.y -= CGFloat(delta * parallax / metresPerPoint)
            if node.position.y < -size.height * 0.8 {
                node.position.y = size.height * 1.8
                node.position.x = CGFloat.random(in: -80...size.width + 80)
            }
        }

        // Stars drift slowly — feels like the deep-sky is infinitely far
        for star in starfield.children {
            star.position.y -= CGFloat(delta * 0.008 / metresPerPoint)
            if star.position.y < 0 { star.position.y += size.height * 1.4 }
        }

        // Speed-streak effect: bright vertical lines when ascending quickly
        if delta > 0.35 { spawnAscendStreak() }
    }

    /// Short white streak that flashes past — reinforces the upward rush.
    private func spawnAscendStreak() {
        guard Double.random(in: 0...1) < 0.25 else { return }

        let length = CGFloat.random(in: 20...60)
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: 0, y: -length))

        let streak = SKShapeNode(path: path)
        streak.strokeColor = UIColor.white.withAlphaComponent(CGFloat.random(in: 0.15...0.45))
        streak.lineWidth = CGFloat.random(in: 0.8...1.8)
        streak.position = CGPoint(
            x: CGFloat.random(in: 8...(size.width - 8)),
            y: size.height * 0.88
        )
        streak.zPosition = 7
        addChild(streak)

        streak.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -6...6), y: -(size.height * 1.1 + length),
                        duration: 0.30),
                .fadeOut(withDuration: 0.30)
            ]),
            .removeFromParent()
        ]))
    }

    private func applyTurbulence() {
        let level = Atmosphere.turbulence(at: engine.state.altitude)
        guard level > 0.05 else {
            balloonSprite.position.x = size.width / 2
            return
        }
        let sway = sin(engine.state.elapsed * 0.9) * CGFloat(level) * 18
        balloonSprite.position.x = size.width / 2 + sway
        syncPayload()
    }

    // MARK: Геометрия оболочки

    /// Диаметр приходит из физики. Форма — каплевидная: снизу горловина,
    /// у растянутой оболочки капля становится сферой, как в реальности.
    private func updateEnvelopeGeometry(diameter: Double, strain: Double) {
        // 30 pt/m makes launch (~1.5 m) = ~45 pt and burst (~6 m) = 180 pt — clearly visible
        let pointsPerMetre: CGFloat = 30
        let width = max(70, CGFloat(diameter) * pointsPerMetre)
        balloonSprite.size = CGSize(width: width, height: width * 1.3)

        // char_3 (blue) — normal ascent
        // char_1 (turquoise) — moderate expansion (strain ≥ 0.45)
        // char_2 (red) — danger, near burst (strain ≥ 0.75)
        let needed: String
        if strain >= 0.75 {
            needed = "char_2"
        } else if strain >= 0.45 {
            needed = "char_1"
        } else {
            needed = "char_3"
        }
        if needed != currentCharTexture {
            currentCharTexture = needed
            balloonSprite.texture = SKTexture(imageNamed: needed)
        }

        syncPayload()
    }

    private func syncPayload() {
        let drop: CGFloat = 20
        let bottom = balloonSprite.position.y - balloonSprite.size.height / 2
        payload.position = CGPoint(x: balloonSprite.position.x, y: bottom - drop)

        let line = UIBezierPath()
        line.move(to: CGPoint(x: balloonSprite.position.x, y: bottom))
        line.addLine(to: payload.position)
        tether.path = line.cgPath
    }

    // MARK: Небо

    /// Текстуру градиента пересобираем только при смене «корзины» высоты —
    /// 200 м. Иначе GPU будет заново заливать градиент каждый кадр.
    private func updateSkyTexture(for altitude: Double, force: Bool) {
        let bucket = Int(altitude / 200)
        guard force || bucket != lastSkyBucket else { return }
        lastSkyBucket = bucket

        let colors = Palette.sky(at: altitude)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 512))
        let image = renderer.image { context in
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [colors.top.cgColor, colors.bottom.cgColor] as CFArray,
                                      locations: [0, 1])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: .zero,
                                                 end: CGPoint(x: 0, y: 512),
                                                 options: [])
        }
        skyNode.texture = SKTexture(image: image)
        skyNode.size = size
    }

    // MARK: Реакция на события

    private func react(to event: MissionEvent) {
        switch event {
        case .burst(let altitude, _):
            playBurst(at: altitude)
        case .ballastDropped:
            emitBallast()
        case .sampleCaptured:
            sampleMarker.position = balloonSprite.position
            sampleMarker.alpha = 1
            sampleMarker.setScale(0.4)
            sampleMarker.run(.group([.scale(to: 2.2, duration: 0.6), .fadeOut(withDuration: 0.6)]))
        default:
            break
        }
    }

    private func playBurst(at altitude: Double) {
        let shards = 14
        for index in 0..<shards {
            let shard = SKShapeNode(rectOf: CGSize(width: 4, height: 12), cornerRadius: 1)
            shard.fillColor = UIColor.white.withAlphaComponent(0.9)
            shard.strokeColor = .clear
            shard.position = balloonSprite.position
            shard.zPosition = 12
            addChild(shard)

            let angle = CGFloat(index) / CGFloat(shards) * .pi * 2
            let distance = CGFloat.random(in: 60...170)
            shard.run(.sequence([
                .group([
                    .move(by: CGVector(dx: cos(angle) * distance, dy: sin(angle) * distance), duration: 0.7),
                    .rotate(byAngle: .pi * 2, duration: 0.7),
                    .fadeOut(withDuration: 0.7)
                ]),
                .removeFromParent()
            ]))
        }
        balloonSprite.run(.fadeOut(withDuration: 0.15))
    }

    private func emitBallast() {
        let grain = SKShapeNode(circleOfRadius: 2)
        grain.fillColor = Palette.brass
        grain.strokeColor = .clear
        grain.position = payload.position
        grain.zPosition = 8
        addChild(grain)
        grain.run(.sequence([
            .group([.moveBy(x: .random(in: -20...20), y: -260, duration: 1.0),
                    .fadeOut(withDuration: 1.0)]),
            .removeFromParent()
        ]))
    }
}

/// Детерминированный генератор: одна и та же миссия — одно и то же небо.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
