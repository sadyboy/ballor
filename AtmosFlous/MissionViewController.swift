import UIKit
import SpriteKit
import SwiftUI
import Combine

/// UIKit держит композицию: SpriteKit рисует мир, SwiftUI показывает панели,
/// Combine связывает всё с движком. Каждая технология занята тем,
/// в чём она объективно сильнее.
public final class MissionViewController: UIViewController {

    private let engine: MissionEngine
    private var cancellables = Set<AnyCancellable>()

    private let skView = SKView()
    private let trace = BarographTraceView()
    private let altitudeLabel = UILabel()
    private let speedLabel = UILabel()
    private let layerLabel = UILabel()
    private let strainBar = StrainIndicator()
    private let ventButton = InstrumentButton(title: "Vent", glyph: "arrow.down.to.line")
    private let ballastButton = InstrumentButton(title: "Ballast", glyph: "shippingbox")
    private let sampleButton = InstrumentButton(title: "Sample", glyph: "thermometer.medium")

    private let pauseButton = UIButton(type: .system)
    private var pauseOverlay: PauseOverlayView?

    private let impact = UIImpactFeedbackGenerator(style: .soft)
    private let notify = UINotificationFeedbackGenerator()
    private var ventStart: Date?

    public init(blueprint: MissionBlueprint) {
        self.engine = MissionEngine(blueprint: blueprint)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        layoutScene()
        layoutHUD()
        layoutControls()
        bind()
        engine.launch()
    }

    // MARK: Композиция

    private func layoutScene() {
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60
        view.addSubview(skView)
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard skView.scene == nil, skView.bounds.width > 0 else { return }
        skView.presentScene(AscentScene(engine: engine, size: skView.bounds.size))
    }

    private func layoutHUD() {
        [altitudeLabel, speedLabel, layerLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = Palette.chartPaper
            $0.layer.shadowColor = UIColor.black.cgColor
            $0.layer.shadowOpacity = 0.85
            $0.layer.shadowRadius = 6
            $0.layer.shadowOffset = CGSize(width: 0, height: 2)
            $0.layer.masksToBounds = false
            view.addSubview($0)
        }
        altitudeLabel.font = Typography.data(44, weight: .semibold)
        speedLabel.font = Typography.data(17)
        layerLabel.font = Typography.display(12)
        layerLabel.textColor = Palette.chartPaper.withAlphaComponent(0.85)

        trace.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(trace)

        strainBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(strainBar)

        // Pause button — top center
        let pauseImage = UIImage(systemName: "pause.circle.fill",
                                 withConfiguration: UIImage.SymbolConfiguration(pointSize: 26, weight: .medium))
        pauseButton.setImage(pauseImage, for: .normal)
        pauseButton.tintColor = Palette.chartPaper
        pauseButton.layer.shadowColor = UIColor.black.cgColor
        pauseButton.layer.shadowOpacity = 0.8
        pauseButton.layer.shadowRadius = 6
        pauseButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        pauseButton.layer.masksToBounds = false
        pauseButton.translatesAutoresizingMaskIntoConstraints = false
        pauseButton.addTarget(self, action: #selector(togglePause), for: .touchUpInside)
        view.addSubview(pauseButton)

        let guide = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            altitudeLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            altitudeLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: Metrics.gutter),

            speedLabel.topAnchor.constraint(equalTo: altitudeLabel.bottomAnchor, constant: 2),
            speedLabel.leadingAnchor.constraint(equalTo: altitudeLabel.leadingAnchor),

            layerLabel.topAnchor.constraint(equalTo: speedLabel.bottomAnchor, constant: 6),
            layerLabel.leadingAnchor.constraint(equalTo: altitudeLabel.leadingAnchor),

            trace.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -Metrics.gutter),
            trace.topAnchor.constraint(equalTo: guide.topAnchor, constant: 12),
            trace.widthAnchor.constraint(equalToConstant: 132),
            trace.heightAnchor.constraint(equalToConstant: 96),

            strainBar.topAnchor.constraint(equalTo: trace.bottomAnchor, constant: 10),
            strainBar.trailingAnchor.constraint(equalTo: trace.trailingAnchor),
            strainBar.widthAnchor.constraint(equalTo: trace.widthAnchor),
            strainBar.heightAnchor.constraint(equalToConstant: 6),

            pauseButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 14),
            pauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pauseButton.widthAnchor.constraint(equalToConstant: 44),
            pauseButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func layoutControls() {
        let stack = UIStackView(arrangedSubviews: [ventButton, ballastButton, sampleButton])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                           constant: Metrics.gutter),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                                            constant: -Metrics.gutter),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                                          constant: -18),
            stack.heightAnchor.constraint(equalToConstant: Metrics.controlSize)
        ])

        // Клапан удерживают — это непрерывное действие, а не тап.
        ventButton.addTarget(self, action: #selector(ventDown), for: .touchDown)
        ventButton.addTarget(self, action: #selector(ventUp),
                             for: [.touchUpInside, .touchUpOutside, .touchCancel])
        ballastButton.addTarget(self, action: #selector(dropBallast), for: .touchUpInside)
        sampleButton.addTarget(self, action: #selector(captureSample), for: .touchUpInside)
    }

    // MARK: Связывание

    private func bind() {
        trace.bind(to: engine)

        engine.telemetry
            .sink { [weak self] telemetry in
                guard let self else { return }
                self.altitudeLabel.text = "\(telemetry.altitude) m"
                self.speedLabel.text = String(format: "%+.1f m/s · %.1f °C · %.0f Pa",
                                              telemetry.verticalSpeed,
                                              telemetry.temperature,
                                              telemetry.pressure)
                self.layerLabel.text = telemetry.layerName.uppercased()
                self.strainBar.setLevel(CGFloat(telemetry.strain))
                self.ballastButton.isEnabled = telemetry.ballast > 0
            }
            .store(in: &cancellables)

        engine.turbulence
            .filter { $0 > 0.35 }
            .throttle(for: .milliseconds(400), scheduler: DispatchQueue.main, latest: false)
            .sink { [weak self] level in
                self?.impact.impactOccurred(intensity: CGFloat(level))
            }
            .store(in: &cancellables)

        engine.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in self?.handle(event) }
            .store(in: &cancellables)
    }

    private func handle(_ event: MissionEvent) {
        switch event {
        case .enteredLayer(let index, let name):
            presentLayerCard(index: index, name: name)
        case .burst:
            notify.notificationOccurred(.warning)
            ventButton.isEnabled = false
            ballastButton.isEnabled = false
        case .sampleCaptured:
            notify.notificationOccurred(.success)
        case .landed(let drift, _):
            presentDebrief(drift: drift)
        default:
            break
        }
    }

    /// Момент обучения встроен в полёт, а не вынесен в отдельный «раздел уроков».
    /// Карточка появляется ровно тогда, когда игрок видит явление своими глазами.
    private func presentLayerCard(index: Int, name: String) {
        let layer = Atmosphere.layers[index]
        let card = LayerCardView(title: name, subtitle: layer.subtitle)
        card.present(in: view)
    }

    private func presentDebrief(drift: Double) {
        let debrief = UIHostingController(
            rootView: DebriefView(state: engine.state,
                                  blueprint: engine.blueprint,
                                  traceImage: trace.renderTrace(size: CGSize(width: 900, height: 520)))
        )
        debrief.modalPresentationStyle = .pageSheet
        present(debrief, animated: true)
    }

    // MARK: Действия

    @objc private func ventDown() {
        ventStart = Date()
        impact.impactOccurred()
    }

    @objc private func ventUp() {
        guard let start = ventStart else { return }
        ventStart = nil
        engine.vent(for: Date().timeIntervalSince(start))
    }

    @objc private func dropBallast() {
        if engine.dropBallast(0.1) { impact.impactOccurred(intensity: 0.9) }
    }

    @objc private func captureSample() {
        if !engine.captureSample() { notify.notificationOccurred(.error) }
    }

    @objc private func togglePause() {
        if skView.isPaused { resumeGame() } else { pauseGame() }
    }

    private func pauseGame() {
        skView.isPaused = true
        let cfg = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        pauseButton.setImage(UIImage(systemName: "play.circle.fill", withConfiguration: cfg), for: .normal)

        let overlay = PauseOverlayView(
            altitude: engine.state.altitude,
            onContinue: { [weak self] in self?.resumeGame() },
            onExit: { [weak self] in self?.dismiss(animated: true) }
        )
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pauseOverlay = overlay
        overlay.animateIn()
    }

    private func resumeGame() {
        let cfg = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        pauseButton.setImage(UIImage(systemName: "pause.circle.fill", withConfiguration: cfg), for: .normal)
        pauseOverlay?.animateOut { [weak self] in
            self?.pauseOverlay?.removeFromSuperview()
            self?.pauseOverlay = nil
            self?.skView.isPaused = false
        }
    }
}

// MARK: - Мелкие элементы

/// Индикатор натяжения оболочки. Одна полоса, три состояния цвета —
/// вся опасность читается периферийным зрением.
final class StrainIndicator: UIView {
    private let fill = CALayer()
    private var level: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.backgroundColor = Palette.chartPaper.withAlphaComponent(0.25).cgColor
        layer.cornerRadius = 3
        layer.masksToBounds = true
        layer.addSublayer(fill)
    }

    required init?(coder: NSCoder) { fatalError() }

    func setLevel(_ value: CGFloat) {
        level = min(1, max(0, value))
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.2)
        fill.frame = CGRect(x: 0, y: 0, width: bounds.width * level, height: bounds.height)
        let danger = min(1, max(0, (level - 0.75) / 0.25))
        fill.backgroundColor = Palette.verdigris.blended(to: Palette.signal, t: danger).cgColor
        CATransaction.commit()
    }
}

final class InstrumentButton: UIControl {
    private let label = UILabel()
    private let icon = UIImageView()

    init(title: String, glyph: String) {
        super.init(frame: .zero)
        layer.cornerRadius = Metrics.panelRadius
        layer.borderWidth = 1
        layer.borderColor = Palette.brass.withAlphaComponent(0.8).cgColor
        backgroundColor = Palette.inkDeep.withAlphaComponent(0.55)

        icon.image = UIImage(systemName: glyph)
        icon.tintColor = Palette.brass
        icon.contentMode = .scaleAspectFit

        label.text = title
        label.font = Typography.display(12)
        label.textColor = Palette.chartPaper
        label.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, label])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center
        stack.isUserInteractionEnabled = false
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            icon.heightAnchor.constraint(equalToConstant: 22)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1 : 0.35 }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
}

// MARK: - Pause overlay

final class PauseOverlayView: UIView {

    init(altitude: Double, onContinue: @escaping () -> Void, onExit: @escaping () -> Void) {
        super.init(frame: .zero)
        backgroundColor = UIColor.black.withAlphaComponent(0.62)

        // Card
        let card = UIView()
        card.backgroundColor = Palette.inkDeep.withAlphaComponent(0.94)
        card.layer.cornerRadius = 20
        card.layer.borderWidth = 1
        card.layer.borderColor = Palette.chartPaper.withAlphaComponent(0.08).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        // Icon
        let iconView = UIImageView(image: UIImage(systemName: "pause.circle",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 36, weight: .light)))
        iconView.tintColor = Palette.brass
        iconView.contentMode = .scaleAspectFit

        // "MISSION PAUSED"
        let titleLabel = UILabel()
        titleLabel.text = "MISSION PAUSED"
        titleLabel.font = Typography.display(11)
        titleLabel.textColor = Palette.chartPaper.withAlphaComponent(0.5)
        titleLabel.textAlignment = .center

        // Altitude number
        let altLabel = UILabel()
        altLabel.text = "\(Int(altitude.rounded())) m"
        altLabel.font = Typography.data(52, weight: .semibold)
        altLabel.textColor = Palette.chartPaper
        altLabel.textAlignment = .center
        altLabel.adjustsFontSizeToFitWidth = true

        // "CURRENT ALTITUDE"
        let subLabel = UILabel()
        subLabel.text = "CURRENT ALTITUDE"
        subLabel.font = Typography.display(10)
        subLabel.textColor = Palette.brass
        subLabel.textAlignment = .center

        // Separator
        let sep = UIView()
        sep.backgroundColor = Palette.chartPaper.withAlphaComponent(0.1)
        sep.heightAnchor.constraint(equalToConstant: 1).isActive = true

        // Continue button
        let continueBtn = UIButton(type: .system)
        continueBtn.setTitle("Continue Flight", for: .normal)
        continueBtn.titleLabel?.font = Typography.display(17)
        continueBtn.backgroundColor = Palette.brass
        continueBtn.setTitleColor(Palette.inkDeep, for: .normal)
        continueBtn.layer.cornerRadius = Metrics.panelRadius
        continueBtn.heightAnchor.constraint(equalToConstant: 52).isActive = true
        continueBtn.addAction(UIAction { _ in onContinue() }, for: .touchUpInside)

        // Exit button
        let exitBtn = UIButton(type: .system)
        exitBtn.setTitle("Exit Mission", for: .normal)
        exitBtn.titleLabel?.font = Typography.display(15)
        exitBtn.setTitleColor(Palette.chartPaper.withAlphaComponent(0.6), for: .normal)
        exitBtn.layer.cornerRadius = Metrics.panelRadius
        exitBtn.layer.borderWidth = 1
        exitBtn.layer.borderColor = Palette.chartPaper.withAlphaComponent(0.22).cgColor
        exitBtn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        exitBtn.addAction(UIAction { _ in onExit() }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, altLabel, subLabel, sep, continueBtn, exitBtn])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 10
        stack.setCustomSpacing(16, after: iconView)
        stack.setCustomSpacing(2,  after: titleLabel)
        stack.setCustomSpacing(4,  after: altLabel)
        stack.setCustomSpacing(20, after: subLabel)
        stack.setCustomSpacing(16, after: sep)
        stack.setCustomSpacing(10, after: continueBtn)
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 288),

            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -24),

            iconView.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func animateIn() {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }

    func animateOut(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.18, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }, completion: { _ in completion() })
    }
}

/// Карточка слоя атмосферы: появляется на границе, живёт 6 секунд, не блокирует управление.
final class LayerCardView: UIView {
    init(title: String, subtitle: String) {
        super.init(frame: .zero)
        backgroundColor = Palette.chartPaper.withAlphaComponent(0.94)
        layer.cornerRadius = Metrics.panelRadius

        let titleLabel = UILabel()
        titleLabel.text = title.uppercased()
        titleLabel.font = Typography.display(13)
        titleLabel.textColor = Palette.inkDeep

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = Typography.body(13)
        subtitleLabel.textColor = Palette.inkSoft
        subtitleLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14)
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func present(in parent: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(self)
        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: parent.centerXAnchor),
            widthAnchor.constraint(lessThanOrEqualToConstant: 320),
            leadingAnchor.constraint(greaterThanOrEqualTo: parent.leadingAnchor, constant: Metrics.gutter),
            centerYAnchor.constraint(equalTo: parent.centerYAnchor, constant: parent.bounds.height * 0.22)
        ])

        alpha = 0
        transform = CGAffineTransform(translationX: 0, y: 12)
        UIView.animate(withDuration: 0.35, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.4, delay: 6) {
                self.alpha = 0
            } completion: { _ in self.removeFromSuperview() }
        }
    }
}
