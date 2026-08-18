import SwiftUI

public struct Lesson: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let question: String
    public let insight: String
    public let formula: String?
    public let unlocks: String?

    public let isSatisfied: (FlightState, MissionBlueprint) -> Bool

    public static func == (lhs: Lesson, rhs: Lesson) -> Bool { lhs.id == rhs.id }
    public func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

public enum Curriculum {

    public static let lessons: [Lesson] = [
        Lesson(id: "archimedes",
               title: "Why It Even Flies",
               question: "Lift the balloon above 1,000 m.",
               insight: """
               The balloon isn't "light" — it displaces air heavier than itself. Lift equals \
               the weight of displaced air minus the weight of gas and structure. That's why \
               the same balloon won't fly with a heavier payload, even with the same gas fill.
               """,
               formula: "F = (ρair − ρgas)·V·g − m·g",
               unlocks: "Payload mass slider",
               isSatisfied: { state, _ in state.peakAltitude > 1_000 }),

        Lesson(id: "expansion",
               title: "The Balloon Grows by Itself",
               question: "Push envelope strain to 50% of rated burst diameter.",
               insight: """
               Gas mass stays constant, but outside pressure drops. Volume grows inversely \
               with pressure: at 16 km the balloon is roughly ten times larger than at launch. \
               That's why you can't fill it to the brim on the ground.
               """,
               formula: "V = m / ρgas,  ρgas = P / (Rgas·T)",
               unlocks: "Balloon catalogue",
               isSatisfied: { state, _ in state.envelopeStrain >= 0.5 }),

        Lesson(id: "tropopause",
               title: "Where Weather Ends",
               question: "Cross the tropopause — climb above 11 km.",
               insight: """
               Below 11 km, air cools at 6.5 °C per kilometre. Then the fall stops: the \
               tropopause begins. That's also where jet streams live — narrow rivers of wind \
               up to 50 m/s that carry the balloon the furthest.
               """,
               formula: "T = T₀ + L·h,  L = −6.5 °C/km",
               unlocks: "Drift map",
               isSatisfied: { state, _ in state.peakAltitude > 11_000 }),

        Lesson(id: "burst",
               title: "Material Limit",
               question: "Fly until the envelope bursts.",
               insight: """
               Latex tears from diameter, not altitude. The non-obvious consequence: to fly \
               higher, fill with less gas — the balloon expands more slowly and climbs further \
               before reaching its burst diameter.
               """,
               formula: "d = ∛(6V/π) ≥ d_burst",
               unlocks: "Altitude Record mode",
               isSatisfied: { state, _ in state.phase == .descent || state.phase == .landed }),

        Lesson(id: "ballast",
               title: "The Cost of One Kilogram",
               question: "Drop ballast during ascent.",
               insight: """
               Ballast is the only way to add lift during flight without adding gas. But every \
               kilogram dropped accelerates envelope expansion: you buy ascent rate at the cost \
               of burst altitude. The discipline is knowing when to spend that reserve.
               """,
               formula: nil,
               unlocks: "Long Drift campaign",
               isSatisfied: { state, blueprint in
                   state.ballastRemaining < blueprint.ballastMass - 0.05
               }),

        Lesson(id: "science",
               title: "Why Balloons Are Launched",
               question: "Capture five samples at different altitudes.",
               insight: """
               A radiosonde is valuable not for the flight, but for the profile: temperature \
               and pressure versus altitude. Twice a day, such profiles from hundreds of \
               stations worldwide become the input data for weather forecasts. Your trace is \
               the same document, just at smaller scale.
               """,
               formula: nil,
               unlocks: "CSV profile export",
               isSatisfied: { state, _ in state.samplesCaptured >= 5 }),

        Lesson(id: "stratosphere",
               title: "Into the Stratosphere",
               question: "Climb above 20 km.",
               insight: """
               The stratosphere does something unexpected: temperature rises as you climb. \
               The culprit is ozone — O₃ molecules absorb UV-B radiation and convert it into \
               heat, creating a stable temperature inversion. No convection means no weather \
               events. The stratosphere is eerily calm, which is why commercial aircraft cruise \
               at its lower edge.
               """,
               formula: "O₃ + UV-B → O₂ + O  (UV energy → heat)",
               unlocks: "Ozone layer overlay",
               isSatisfied: { state, _ in state.peakAltitude > 20_000 }),

        Lesson(id: "jetstream",
               title: "Riding the Jet Stream",
               question: "Drift more than 80 km from the launch site.",
               insight: """
               Your balloon was carried by a jet stream — a narrow tube of fast air driven by \
               the temperature contrast between polar and equatorial air masses. Meteorologists \
               place them at 200–300 hPa (9–12 km altitude). The same winds that delay \
               transatlantic flights or give them tailwinds are what sent your payload 80 km \
               downrange.
               """,
               formula: nil,
               unlocks: "Wind vector display",
               isSatisfied: { state, _ in state.horizontalDrift > 80_000 }),

        Lesson(id: "lastresort",
               title: "The Last Resort",
               question: "Use every gram of ballast.",
               insight: """
               Auguste Piccard reached the stratosphere in 1931 by managing ballast this same \
               way. Each kilogram you drop is a one-way trade — altitude for control. Once the \
               sandbags are empty, the balloon flies on its own terms. The discipline of ballast \
               management — drop late, drop decisively — separates a controlled flight from a \
               runaway ascent.
               """,
               formula: nil,
               unlocks: "Extended ballast loadout",
               isSatisfied: { state, blueprint in
                   state.ballastRemaining < 0.01 && blueprint.ballastMass > 0.01
               }),

        Lesson(id: "upperstrato",
               title: "Above the Ozone Peak",
               question: "Reach the upper stratosphere — above 32 km.",
               insight: """
               At 32 km, air density is less than 1% of sea level — roughly equivalent to \
               Mars's surface atmosphere. Concorde cruised at 18 km; you have climbed nearly \
               twice as high. Ozone concentration drops here as you leave the absorbing layer. \
               Radio waves bounce off the ionosphere just above, enabling long-distance \
               shortwave communication.
               """,
               formula: "ρ₃₂ₖₘ ≈ 0.014 kg/m³  (< 1.2% of sea level)",
               unlocks: "Density profile overlay",
               isSatisfied: { state, _ in state.peakAltitude > 32_000 }),

        Lesson(id: "nearspace",
               title: "Near-Space",
               question: "Reach the stratopause — above 40 km.",
               insight: """
               Above 40 km lies the stratopause: the warmest point in the stratosphere, where \
               ozone heating peaks. Felix Baumgartner stepped out of a capsule at 39 km in 2012. \
               At these altitudes the sky is near-black in daylight, the curvature of Earth is \
               visible, and pressure is less than 300 Pa — one three-hundredths of sea level. \
               Beyond this, temperature falls again through the cold mesosphere toward the \
               mesopause at 85 km.
               """,
               formula: "P₄₀ₖₘ ≈ 300 Pa  ≈ 0.3% of sea level",
               unlocks: "Near-space mission badge",
               isSatisfied: { state, _ in state.peakAltitude > 40_000 })
    ]

    public static func completed(by state: FlightState,
                                 blueprint: MissionBlueprint) -> [Lesson] {
        lessons.filter { $0.isSatisfied(state, blueprint) }
    }
}

// MARK: - Debrief screen

public struct DebriefView: View {
    let state: FlightState
    let blueprint: MissionBlueprint
    let traceImage: UIImage

    @State private var unlocked: [Lesson] = []

    public init(state: FlightState, blueprint: MissionBlueprint, traceImage: UIImage) {
        self.state = state
        self.blueprint = blueprint
        self.traceImage = traceImage
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                Text("Flight Trace")
                    .font(Font(Typography.display(12)))
                    .textCase(.uppercase)
                    .kerning(1.4)
                    .foregroundColor(Color(Palette.inkSoft))

                Image(uiImage: traceImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(Metrics.panelRadius)

                HStack(spacing: 24) {
                    figure("Ceiling", String(format: "%.0f m", state.peakAltitude))
                    figure("Drift",   String(format: "%.0f km", state.horizontalDrift / 1000))
                    figure("Samples", "\(state.samplesCaptured)")
                }

                if !unlocked.isEmpty {
                    Text("What This Flight Revealed")
                        .font(Font(Typography.display(12)))
                        .textCase(.uppercase)
                        .kerning(1.4)
                        .foregroundColor(Color(Palette.inkSoft))

                    ForEach(unlocked) { lesson in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(lesson.title)
                                .font(Font(Typography.display(17, weight: .semibold)))
                                .foregroundColor(Color(Palette.inkDeep))
                            Text(lesson.insight)
                                .font(Font(Typography.body(14)))
                                .foregroundColor(Color(Palette.inkSoft))
                            if let formula = lesson.formula {
                                Text(formula)
                                    .font(Font(Typography.data(14)))
                                    .foregroundColor(Color(Palette.verdigris))
                            }
                            if let unlocks = lesson.unlocks {
                                Text("Unlocks: \(unlocks)")
                                    .font(Font(Typography.display(12)))
                                    .foregroundColor(Color(Palette.brass))
                            }
                        }
                        .padding(.vertical, 6)
                    }
                }

                ShareLink(item: Image(uiImage: traceImage),
                          preview: SharePreview("Flight Trace", image: Image(uiImage: traceImage))) {
                    Text("Share Flight Trace")
                        .font(Font(Typography.display(16, weight: .semibold)))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(Palette.inkDeep))
                        .foregroundColor(Color(Palette.chartPaper))
                        .cornerRadius(Metrics.panelRadius)
                }
            }
            .padding(Metrics.gutter)
        }
        .background(Color(Palette.chartPaper).ignoresSafeArea())
        .task {
            unlocked = Curriculum.completed(by: state, blueprint: blueprint)
            let record = FlightRecord(
                id: UUID(),
                missionName: blueprint.name,
                date: Date(),
                peakAltitude: state.peakAltitude,
                horizontalDrift: state.horizontalDrift,
                samplesCaptured: state.samplesCaptured,
                balloonModel: blueprint.balloon.model,
                gasTitle: blueprint.gas.title,
                lessonsCompleted: unlocked.count,
                lessonIds: unlocked.map(\.id),
                duration: state.elapsed
            )
            FlightLogbook.shared.save(record)
        }
    }

    private func figure(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.inkSoft))
            Text(value)
                .font(Font(Typography.data(22, weight: .semibold)))
                .foregroundColor(Color(Palette.inkDeep))
        }
    }
}
