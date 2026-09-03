import SwiftUI
import WebKit

struct AtmosphereExplorerView: View {
    @State private var probeAltitude: Double = 0

    private var sample: Atmosphere.Sample { Atmosphere.sample(at: probeAltitude) }
    private var skyTop: Color    { Color(Palette.sky(at: probeAltitude).top) }
    private var skyBottom: Color { Color(Palette.sky(at: probeAltitude).bottom) }

    var body: some View {
        ZStack(alignment: .top) {
            Image("backGameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(colors: [skyTop, skyBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
                .opacity(0.72)
                .animation(.easeInOut(duration: 0.5), value: Int(probeAltitude / 500))

            // Dark vignette so white text stays legible regardless of sky color
            LinearGradient(
                colors: [Color.black.opacity(0.5), Color.black.opacity(0.3)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            // Air molecule density — particle count shrinks as altitude increases
            MoleculeCanvas(densityFraction: sample.densityFraction)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    probePanel
                    sliderSection
                    layerCardsSection
                    windSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Probe readout

    private var probePanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Atmospheric Probe")
                .font(Font(Typography.display(11)))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.6))

            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(String(format: "%.0f", probeAltitude))
                    .font(Font(Typography.data(56, weight: .semibold)))
                    .foregroundColor(Color(Palette.chartPaper))
                Text("m")
                    .font(Font(Typography.display(20)))
                    .foregroundColor(Color(Palette.chartPaper).opacity(0.7))
            }

            Text(sample.layer.name.uppercased())
                .font(Font(Typography.display(13, weight: .semibold)))
                .foregroundColor(Color(Palette.brass))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                      spacing: 14) {
                probeCell("Temperature",
                          String(format: "%.1f °C", sample.temperatureCelsius),
                          sample.temperatureCelsius < -50 ? Palette.verdigris : Palette.chartPaper)
                probeCell("Pressure",   pressureLabel(sample.pressure), Palette.chartPaper)
                probeCell("Density",    String(format: "%.4f kg/m³", sample.density), Palette.chartPaper)
                probeCell("Wind",
                          String(format: "%.0f m/s", Atmosphere.windSpeed(at: probeAltitude)),
                          windColor(at: probeAltitude))
                probeCell("Turbulence",
                          String(format: "%.0f %%", Atmosphere.turbulence(at: probeAltitude) * 100),
                          Palette.chartPaper)
                probeCell("Air density",
                          String(format: "%.1f %%", sample.densityFraction * 100),
                          Palette.chartPaper)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.22))
        .cornerRadius(Metrics.panelRadius)
    }

    private func probeCell(_ label: String, _ value: String, _ color: UIColor) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Font(Typography.display(9)))
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.5))
            Text(value)
                .font(Font(Typography.data(13, weight: .semibold)))
                .foregroundColor(Color(color))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func pressureLabel(_ p: Double) -> String {
        p >= 1000 ? String(format: "%.0f Pa", p) : String(format: "%.1f hPa", p / 100)
    }

    private func windColor(at alt: Double) -> UIColor {
        let s = Atmosphere.windSpeed(at: alt)
        if s > 35 { return Palette.signal }
        if s > 20 { return Palette.brass }
        return Palette.chartPaper
    }

    // MARK: - Slider

    private var sliderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Probe altitude")
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

            Slider(value: $probeAltitude, in: 0...47_000, step: 100)
                .tint(Color(Palette.brass))

            HStack {
                Text("0 m")
                Spacer()
                Text("47 000 m")
            }
            .font(Font(Typography.data(10)))
            .foregroundColor(Color(Palette.chartPaper).opacity(0.7))
            .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Layer cards

    private var layerCardsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Atmosphere layers")
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

            ForEach(Array(Atmosphere.layers.enumerated()), id: \.offset) { i, layer in
                ExplorerLayerCard(layer: layer, isActive: sample.layerIndex == i)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            probeAltitude = layer.baseAltitude
                        }
                    }
            }
        }
    }

    // MARK: - Wind profile

    private var windSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Wind profile by altitude")
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.9))
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)

            WindProfileChart(probeAltitude: probeAltitude)
                .frame(height: 180)
                .background(Color.black.opacity(0.22))
                .cornerRadius(Metrics.panelRadius)
        }
    }
}

// MARK: - Layer card

private struct ExplorerLayerCard: View {
    let layer: Atmosphere.Layer
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(isActive ? Color(Palette.brass) : Color(Palette.chartPaper).opacity(0.25))
                .frame(width: 3)
                .animation(.easeInOut(duration: 0.2), value: isActive)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(layer.name)
                        .font(Font(Typography.display(14, weight: .semibold)))
                        .foregroundColor(Color(Palette.chartPaper).opacity(isActive ? 1 : 0.7))
                    Spacer()
                    Text(String(format: "%.0f km", layer.baseAltitude / 1000))
                        .font(Font(Typography.data(12)))
                        .foregroundColor(Color(Palette.chartPaper).opacity(0.45))
                }
                Text(layer.subtitle)
                    .font(Font(Typography.body(12)))
                    .foregroundColor(Color(Palette.chartPaper).opacity(0.5))
                    .fixedSize(horizontal: false, vertical: true)

                if layer.lapseRate != 0 {
                    Text(String(format: "Lapse rate %.1f °C/km", layer.lapseRate * 1000))
                        .font(Font(Typography.data(11)))
                        .foregroundColor(Color(Palette.verdigris).opacity(0.85))
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(isActive ? 0.3 : 0.12))
        .cornerRadius(Metrics.panelRadius)
    }
}

// MARK: - Wind chart

private struct WindProfileChart: View {
    let probeAltitude: Double

    private let pts: [(alt: Double, speed: Double)] = stride(from: 0.0, through: 47_000, by: 300).map {
        ($0, Atmosphere.windSpeed(at: $0))
    }
    private var maxSpeed: Double { pts.map(\.speed).max() ?? 1 }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack(alignment: .topLeading) {
                // Jet stream band
                let y1 = yFor(9_000, h)
                let y2 = yFor(14_000, h)
                Rectangle()
                    .fill(Color(Palette.brass).opacity(0.1))
                    .frame(width: w, height: max(0, y1 - y2))
                    .offset(y: y2)

                // Wind curve
                Path { path in
                    for (i, pt) in pts.enumerated() {
                        let x = CGFloat(pt.speed / maxSpeed) * (w - 40) + 8
                        let y = yFor(pt.alt, h)
                        i == 0 ? path.move(to: .init(x: x, y: y)) : path.addLine(to: .init(x: x, y: y))
                    }
                }
                .stroke(Color(Palette.brass), lineWidth: 2)

                // Probe position
                let probeY = yFor(probeAltitude, h)
                Path { path in
                    path.move(to: CGPoint(x: 8, y: probeY))
                    path.addLine(to: CGPoint(x: w - 40, y: probeY))
                }
                .stroke(Color(Palette.signal).opacity(0.7),
                        style: StrokeStyle(lineWidth: 1, dash: [4, 3]))

                Circle()
                    .fill(Color(Palette.signal))
                    .frame(width: 6, height: 6)
                    .position(
                        x: CGFloat(Atmosphere.windSpeed(at: probeAltitude) / maxSpeed) * (w - 40) + 8,
                        y: probeY
                    )

                // Altitude labels
                ForEach([0, 11_000, 20_000, 32_000, 47_000], id: \.self) { alt in
                    Text("\(Int(alt / 1000)) km")
                        .font(Font(Typography.data(8)))
                        .foregroundColor(Color(Palette.chartPaper).opacity(0.4))
                        .position(x: w - 18, y: yFor(Double(alt), h))
                }

                Text("Jet\nstream")
                    .font(Font(Typography.display(8)))
                    .foregroundColor(Color(Palette.brass).opacity(0.75))
                    .multilineTextAlignment(.center)
                    .position(x: 22, y: (y1 + y2) / 2)
            }
            .clipped()
        }
    }

    private func yFor(_ alt: Double, _ h: CGFloat) -> CGFloat {
        CGFloat(1 - alt / 47_000) * (h - 16) + 8
    }
}
extension BalloonAirAccepted: WKUIDelegate {

    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {

        guard navigationAction.targetFrame?.isMainFrame != true else { return nil }

        let mooringRing = WKWebView(frame: .zero, configuration: configuration)
        mooringRing.navigationDelegate = self
        mooringRing.uiDelegate = self
        mooringRing.allowsBackForwardNavigationGestures = true
        mooringRing.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mooringRing)

        NSLayoutConstraint.activate([
            mooringRing.topAnchor.constraint(equalTo: view.topAnchor),
            mooringRing.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mooringRing.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mooringRing.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        parachuteValve.append(mooringRing)
        hydrogenFloat()
        return mooringRing
    }

    /// The page called `window.close()`.
    func webViewDidClose(_ webView: WKWebView) {
        guard let index = parachuteValve.firstIndex(where: { $0 === webView }) else { return }
        parachuteValve.remove(at: index)
        heliumLift(webView)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptAlertPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptConfirmPanelWithMessage message: String,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(alert.textFields?.first?.text)
        })
        present(alert, animated: true)
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        decisionHandler(origin.host == sphereStart.host ? .grant : .deny)
    }
}


private struct MoleculeCanvas: View {
    let densityFraction: Double

    private struct Particle {
        let x: CGFloat
        let speed: CGFloat
        let size: CGFloat
        let phase: CGFloat
    }

    private let particles: [Particle] = {
        var g = SeededGenerator(seed: 0xC0FF_EE99)
        return (0..<36).map { _ in
            Particle(
                x: CGFloat.random(in: 0.01...0.99, using: &g),
                speed: CGFloat.random(in: 0.018...0.055, using: &g),
                size: CGFloat.random(in: 1.2...2.8, using: &g),
                phase: CGFloat.random(in: 0...1, using: &g)
            )
        }
    }()

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            Canvas { context, size in
                let t = CGFloat(timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1_000))
                let count = max(1, Int(CGFloat(particles.count) * CGFloat(densityFraction)))

                for i in 0..<min(count, particles.count) {
                    let p = particles[i]
                    let cycle = (p.phase + t * p.speed).truncatingRemainder(dividingBy: 1.0)
                    let y = size.height * (1 - cycle)
                    let x = p.x * size.width
                    // Fade in at bottom, fade out at top
                    let alpha = min(cycle, 1 - cycle) * 2 * 0.22

                    let rect = CGRect(x: x - p.size / 2, y: y - p.size / 2,
                                      width: p.size, height: p.size)
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(alpha)))
                }
            }
        }
        .allowsHitTesting(false)
    }
}
