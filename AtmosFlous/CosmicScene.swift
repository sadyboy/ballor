import Combine
import SpriteKit
import SwiftUI

// MARK: - SpriteKit scene

final class CosmicScene: SKScene {

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    override func didMove(to view: SKView) {
        addStars()
        scheduleShootingStar()
    }

    // MARK: Stars

    private func addStars() {
        for _ in 0..<85 {
            let radius = CGFloat.random(in: 0.5...2.2)
            let node   = SKShapeNode(circleOfRadius: radius)
            node.position = CGPoint(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height)
            )
            let baseAlpha = CGFloat.random(in: 0.3...0.92)
            node.fillColor = UIColor.white.withAlphaComponent(baseAlpha)
            node.strokeColor = .clear
            node.blendMode = .add

            let dimAlpha = CGFloat.random(in: 0.04...0.22)
            let period   = Double.random(in: 1.2...5.0)
            let offset   = Double.random(in: 0...period)

            node.run(.sequence([
                .wait(forDuration: offset),
                .repeatForever(.sequence([
                    .fadeAlpha(to: dimAlpha,   duration: period * 0.5),
                    .fadeAlpha(to: baseAlpha,  duration: period * 0.5)
                ]))
            ]))

            addChild(node)
        }
    }

    // MARK: Shooting stars

    private func scheduleShootingStar() {
        run(.sequence([
            .wait(forDuration: Double.random(in: 5...13)),
            .run { [weak self] in
                self?.fireShootingStar()
                self?.scheduleShootingStar()
            }
        ]))
    }

    private func fireShootingStar() {
        let length = CGFloat.random(in: 55...130)
        let angle  = CGFloat.pi + CGFloat.random(in: -0.3...0.3)

        let path = CGMutablePath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: cos(angle) * length, y: sin(angle) * length))

        let node = SKShapeNode(path: path)
        // Warm brass-gold colour to match the app palette
        node.strokeColor = UIColor(red: 0.87, green: 0.80, blue: 0.53, alpha: 0.9)
        node.lineWidth   = 1.5
        node.lineCap     = .round
        node.blendMode   = .add
        node.position    = CGPoint(
            x: CGFloat.random(in: size.width * 0.25...size.width),
            y: CGFloat.random(in: size.height * 0.3...size.height)
        )

        let dist = CGFloat.random(in: 130...240)
        node.run(.sequence([
            .group([
                .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.65),
                .sequence([.wait(forDuration: 0.25), .fadeOut(withDuration: 0.40)])
            ]),
            .removeFromParent()
        ]))
        addChild(node)
    }
}

// MARK: - SwiftUI wrapper

private final class CosmicSceneBox: ObservableObject {
    let scene: CosmicScene
    init() {
        scene = CosmicScene(size: UIScreen.main.bounds.size)
    }
}

/// Drop-in SpriteKit star field with twinkling stars and occasional shooting stars.
/// Transparent background — overlay it on any dark gradient.
struct CosmicSpriteView: View {
    @StateObject private var box = CosmicSceneBox()

    var body: some View {
        SpriteView(scene: box.scene, options: [.allowsTransparency])
            .allowsHitTesting(false)
    }
}
