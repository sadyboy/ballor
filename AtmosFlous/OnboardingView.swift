import SwiftUI

struct OnboardingView: View {
    @Binding var isCompleted: Bool
    @State private var page = 0

    private let pages = OnboardingPage.all

    var body: some View {
        ZStack {
            Image("backGameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Dark vignette — keeps white text readable over the light sky image
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.65)],
                startPoint: .init(x: 0.5, y: 0.3),
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { i, p in
                        OnboardingPageView(page: p).tag(i)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                bottomBar
            }
        }
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        VStack(spacing: 20) {
            // Progress dots
            HStack(spacing: 7) {
                ForEach(0..<pages.count, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color(Palette.brass) : Color(Palette.chartPaper).opacity(0.2))
                        .frame(width: i == page ? 22 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.25), value: page)
                }
            }

            // Primary action
            Button {
                if page < pages.count - 1 {
                    withAnimation(.easeInOut(duration: 0.3)) { page += 1 }
                } else {
                    isCompleted = true
                }
            } label: {
                Text(page < pages.count - 1 ? "Continue" : "Start Flying")
                    .font(Font(Typography.display(17, weight: .semibold)))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color(Palette.brass))
                    .foregroundColor(Color(Palette.inkDeep))
                    .cornerRadius(Metrics.panelRadius)
            }
            .padding(.horizontal, 24)

            // Skip
            if page < pages.count - 1 {
                Button("Skip") { isCompleted = true }
                    .font(Font(Typography.body(14)))
                    .foregroundColor(Color(Palette.chartPaper).opacity(0.55))
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 1)
            } else {
                Spacer().frame(height: 20)
            }
        }
        .padding(.bottom, 44)
        .padding(.top, 16)
    }
}

// MARK: - Page data

struct OnboardingPage {
    let icon: String
    let accent: UIColor
    let title: String
    let body: String
    let visual: AnyView

    static let all: [OnboardingPage] = [
        OnboardingPage(
            icon: "dial.medium",
            accent: Palette.brass,
            title: "Plan Your Mission",
            body: "Configure balloon, gas type, payload, and launch elevation. The ISA physics engine calculates burst altitude, ascent rate, and wind drift instantly — no network required.",
            visual: AnyView(PlannerVisual())
        ),
        OnboardingPage(
            icon: "aqi.medium",
            accent: Palette.verdigris,
            title: "Explore the Atmosphere",
            body: "Drag a virtual probe through all five ISA layers. Temperature, pressure, density, and wind — the same numbers the flight engine uses during your real mission.",
            visual: AnyView(AtmosphereVisual())
        ),
        OnboardingPage(
            icon: "paperplane.fill",
            accent: Palette.chartPaper,
            title: "Fly the Balloon",
            body: "Hold Vent to release gas and control strain. Drop ballast to recover ascent rate. Tap Sample to capture atmospheric data at key altitudes — timing matters.",
            visual: AnyView(FlightVisual())
        ),
        OnboardingPage(
            icon: "book.closed.fill",
            accent: Palette.brass,
            title: "Build Your Logbook",
            body: "Every completed mission is logged automatically: peak altitude, drift, samples, and lessons unlocked. Your personal records update with each flight.",
            visual: AnyView(LogbookVisual())
        )
    ]
}

// MARK: - Page view

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Visual panel
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.25))
                    .frame(height: 220)

                page.visual
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 28)

            Spacer().frame(height: 44)

            // Text
            VStack(spacing: 16) {
                Text(page.title)
                    .font(Font(Typography.display(30, weight: .semibold)))
                    .foregroundColor(Color(Palette.chartPaper))
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.75), radius: 8, x: 0, y: 2)

                Text(page.body)
                    .font(Font(Typography.body(15)))
                    .foregroundColor(Color(Palette.chartPaper).opacity(0.88))
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .shadow(color: .black.opacity(0.65), radius: 6, x: 0, y: 1)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Visual panels

private struct PlannerVisual: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Spacer()
            row("Burst altitude", "28 340 m", Palette.brass)
            row("Ascent rate", "5.2 m/s", Palette.verdigris)
            row("Wind drift", "87 km", Palette.chartPaper)
            row("Time to burst", "1 h 31 min", Palette.chartPaper)
            row("Gas volume", "4.2 m³", Palette.chartPaper)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    private func row(_ label: String, _ value: String, _ color: UIColor) -> some View {
        HStack {
            Text(label)
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.chartPaper).opacity(0.45))
            Spacer()
            Text(value)
                .font(Font(Typography.data(15, weight: .semibold)))
                .foregroundColor(Color(color))
        }
    }
}

private struct AtmosphereVisual: View {
    private let layers: [(name: String, color: UIColor, thick: CGFloat)] = [
        ("Troposphere",       UIColor(hex: 0x7FA9C4), 56),
        ("Tropopause",        UIColor(hex: 0x4E7FA8), 28),
        ("Lower Stratosphere",UIColor(hex: 0x2E5A87), 36),
        ("Upper Stratosphere",UIColor(hex: 0x14294F), 36),
        ("Stratopause",       UIColor(hex: 0x070E24), 28)
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(layers, id: \.name) { layer in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(layer.color))
                    Text(layer.name)
                        .font(Font(Typography.display(9)))
                        .foregroundColor(Color(Palette.chartPaper).opacity(0.7))
                        .padding(.leading, 12)
                }
                .frame(height: layer.thick)
            }
        }
    }
}

private struct FlightVisual: View {
    @State private var phase: CGFloat = 0

    var body: some View {
        ZStack {
            // Barograph trace
            GeometryReader { geo in
                Path { path in
                    let w = geo.size.width
                    let h = geo.size.height
                    path.move(to: CGPoint(x: 0, y: h * 0.9))
                    path.addCurve(
                        to: CGPoint(x: w * 0.65, y: h * 0.12),
                        control1: CGPoint(x: w * 0.2, y: h * 0.8),
                        control2: CGPoint(x: w * 0.45, y: h * 0.15)
                    )
                    path.addCurve(
                        to: CGPoint(x: w, y: h * 0.85),
                        control1: CGPoint(x: w * 0.8, y: h * 0.1),
                        control2: CGPoint(x: w * 0.85, y: h * 0.9)
                    )
                }
                .stroke(Color(Palette.inkDeep), lineWidth: 2)

                // Burst marker
                Circle()
                    .fill(Color(Palette.signal))
                    .frame(width: 8, height: 8)
                    .position(x: geo.size.width * 0.65, y: geo.size.height * 0.12)
            }
            .padding(20)
            .background(Color(Palette.chartPaper))

            // Pen dot
            GeometryReader { geo in
                Circle()
                    .fill(Color(Palette.signal))
                    .frame(width: 6, height: 6)
                    .position(x: geo.size.width - 22, y: geo.size.height * 0.85)
            }
        }
    }
}

private struct LogbookVisual: View {
    private let entries: [(name: String, alt: String, drift: String)] = [
        ("Unnamed Mission",  "31 200 m", "94 km"),
        ("Tropopause Run",   "11 540 m", "38 km"),
        ("Science Payload",  "24 870 m", "72 km")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries, id: \.name) { entry in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name)
                            .font(Font(Typography.display(13, weight: .semibold)))
                            .foregroundColor(Color(Palette.inkDeep))
                        Text("\(entry.alt)  ·  \(entry.drift) drift")
                            .font(Font(Typography.data(11)))
                            .foregroundColor(Color(Palette.inkSoft))
                    }
                    Spacer()
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(Palette.brass))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                Divider().background(Color(Palette.chartRule))
            }
            Spacer()
        }
        .background(Color(Palette.chartPaper))
    }
}
