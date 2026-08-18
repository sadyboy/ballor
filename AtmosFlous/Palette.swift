import UIKit

/// Визуальный язык взят не из «мультяшных шариков», а из мира,
/// которому принадлежит предмет: лента барографа-самописца, миллиметровка
/// метеостанции, латунь приборов, фиолетовые чернила.
///
/// Ключевой ход — инверсия ожидания: тёмное небо снаружи, светлая бумага прибора сверху.
/// Ни один поп-зе-баллун из сторов так не выглядит.
public enum Palette {

    // Приборная «бумага»
    public static let chartPaper  = UIColor(hex: 0xD9E4DD)
    public static let chartRule   = UIColor(hex: 0xA9C0B4)
    public static let inkDeep     = UIColor(hex: 0x221B33)
    public static let inkSoft     = UIColor(hex: 0x5A5170)

    // Смысловые акценты
    public static let signal      = UIColor(hex: 0xC8305A)  // разрыв, предел, ошибка
    public static let verdigris   = UIColor(hex: 0x2F7D6B)  // норма, подтверждение
    public static let brass       = UIColor(hex: 0xB98A2E)  // всё, что можно тронуть пальцем

    /// Опорные точки неба. Между ними интерполируем — так цвет всего экрана
    /// становится производной от физики, а не набором пресетов.
    private static let skyStops: [(altitude: Double, top: UIColor, bottom: UIColor)] = [
        (0,      UIColor(hex: 0x7FA9C4), UIColor(hex: 0xC8D6DA)),
        (5_000,  UIColor(hex: 0x4E7FA8), UIColor(hex: 0x9CBACB)),
        (11_000, UIColor(hex: 0x2E5A87), UIColor(hex: 0x6E93B0)),
        (20_000, UIColor(hex: 0x14294F), UIColor(hex: 0x35557C)),
        (30_000, UIColor(hex: 0x070E24), UIColor(hex: 0x172945)),
        (42_000, UIColor(hex: 0x02030C), UIColor(hex: 0x080F22))
    ]

    public static func sky(at altitude: Double) -> (top: UIColor, bottom: UIColor) {
        if altitude <= skyStops[0].altitude { return (skyStops[0].top, skyStops[0].bottom) }
        if let last = skyStops.last, altitude >= last.altitude { return (last.top, last.bottom) }

        for i in 0..<(skyStops.count - 1) {
            let a = skyStops[i], b = skyStops[i + 1]
            guard altitude >= a.altitude, altitude < b.altitude else { continue }
            let t = CGFloat((altitude - a.altitude) / (b.altitude - a.altitude))
            return (a.top.blended(to: b.top, t: t), a.bottom.blended(to: b.bottom, t: t))
        }
        return (skyStops[0].top, skyStops[0].bottom)
    }

    /// Звёзды проступают там же, где они проступают в реальности — выше 15 км.
    public static func starOpacity(at altitude: Double) -> CGFloat {
        CGFloat(min(1, max(0, (altitude - 15_000) / 14_000)))
    }
}

public enum Typography {
    /// Заголовки — узкий гротеск: так подписывают шкалы приборов.
    public static func display(_ size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        if #available(iOS 16.0, *) {
            return UIFont.systemFont(ofSize: size, weight: weight, width: .condensed)
        }
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    /// Телеметрия — только моноширинные цифры. Числа не должны «дёргаться».
    public static func data(_ size: CGFloat, weight: UIFont.Weight = .medium) -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    }

    public static func body(_ size: CGFloat) -> UIFont {
        UIFont.systemFont(ofSize: size, weight: .regular)
    }
}

public enum Metrics {
    public static let gutter: CGFloat = 20
    public static let hairline: CGFloat = 1 / UIScreen.main.scale
    public static let panelRadius: CGFloat = 4      // приборы не бывают со скруглением 16
    public static let controlSize: CGFloat = 64
}

// MARK: - Утилиты

public extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red:   CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue:  CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }

    func blended(to other: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        let k = min(max(t, 0), 1)
        return UIColor(red: r1 + (r2 - r1) * k,
                       green: g1 + (g2 - g1) * k,
                       blue: b1 + (b2 - b1) * k,
                       alpha: a1 + (a2 - a1) * k)
    }
}
