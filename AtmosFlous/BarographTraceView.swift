import UIKit
import Combine

/// Подпись приложения. Пока шар летит, вдоль экрана ползёт бумажная лента
/// и перо чертит на ней настоящую кривую высоты. После посадки лента —
/// это и есть артефакт миссии: её сохраняют, сравнивают и делятся ею.
///
/// Ни один скриншот с такой лентой невозможно спутать с очередным
/// «лопни шарик»: элемент выведен из предмета, а не приклеен для красоты.
public final class BarographTraceView: UIView {

    /// Точки (время, высота). Храним в модели, а не в CAShapeLayer, чтобы
    /// уметь перерисовать при повороте и экспортировать в PDF.
    private var points: [(t: TimeInterval, altitude: Double)] = []
    private var traceWindow: TimeInterval = 900     // видимое окно ленты, с
    private var ceiling: Double = 36_000            // верх шкалы, м

    private let paperLayer = CALayer()
    private let gridLayer = CAShapeLayer()
    private let traceLayer = CAShapeLayer()
    private let penLayer = CAShapeLayer()
    private var cancellables = Set<AnyCancellable>()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isUserInteractionEnabled = false
        layer.cornerRadius = Metrics.panelRadius
        layer.masksToBounds = true

        paperLayer.backgroundColor = Palette.chartPaper.withAlphaComponent(0.92).cgColor
        layer.addSublayer(paperLayer)

        gridLayer.strokeColor = Palette.chartRule.cgColor
        gridLayer.lineWidth = Metrics.hairline
        gridLayer.fillColor = nil
        layer.addSublayer(gridLayer)

        traceLayer.strokeColor = Palette.inkDeep.cgColor
        traceLayer.lineWidth = 1.6
        traceLayer.lineJoin = .round
        traceLayer.lineCap = .round
        traceLayer.fillColor = nil
        layer.addSublayer(traceLayer)

        penLayer.fillColor = Palette.signal.cgColor
        penLayer.path = UIBezierPath(ovalIn: CGRect(x: -3, y: -3, width: 6, height: 6)).cgPath
        layer.addSublayer(penLayer)
    }

    /// Подписка на движок. Прореживаем до 2 Гц — лента должна быть спокойной.
    public func bind(to engine: MissionEngine) {
        engine.$state
            .throttle(for: .milliseconds(500), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] state in
                self?.append(time: state.elapsed, altitude: state.altitude)
            }
            .store(in: &cancellables)
    }

    public func append(time: TimeInterval, altitude: Double) {
        points.append((time, altitude))
        if points.count > 4_000 { points.removeFirst(points.count - 4_000) }
        ceiling = max(ceiling, altitude * 1.1)
        redraw()
    }

    public func reset() {
        points.removeAll()
        redraw()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        paperLayer.frame = bounds
        redraw()
    }

    private func redraw() {
        guard bounds.width > 0, bounds.height > 0 else { return }

        // Сетка: горизонтали каждые 5 км, вертикали — каждые 60 с ленты.
        let grid = UIBezierPath()
        var km = 0.0
        while km <= ceiling {
            let y = yFor(altitude: km)
            grid.move(to: CGPoint(x: 0, y: y))
            grid.addLine(to: CGPoint(x: bounds.width, y: y))
            km += 5_000
        }
        gridLayer.path = grid.cgPath

        // Трасса: скользящее окно, самая свежая точка всегда у правого края.
        guard let last = points.last else {
            traceLayer.path = nil
            penLayer.isHidden = true
            return
        }
        penLayer.isHidden = false

        let start = last.t - traceWindow
        let visible = points.filter { $0.t >= start }
        let path = UIBezierPath()
        var started = false

        for point in visible {
            let x = CGFloat((point.t - start) / traceWindow) * bounds.width
            let p = CGPoint(x: x, y: yFor(altitude: point.altitude))
            if started { path.addLine(to: p) } else { path.move(to: p); started = true }
        }
        traceLayer.path = path.cgPath

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        penLayer.position = CGPoint(x: bounds.width - 1, y: yFor(altitude: last.altitude))
        CATransaction.commit()
    }

    private func yFor(altitude: Double) -> CGFloat {
        let inset: CGFloat = 6
        let usable = bounds.height - inset * 2
        return inset + usable * CGFloat(1 - min(1, max(0, altitude / ceiling)))
    }

    /// Экспорт ленты как артефакта миссии — то, чем делятся.
    public func renderTrace(size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            Palette.chartPaper.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            layer.render(in: context.cgContext)
        }
    }
}
