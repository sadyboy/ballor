import SwiftUI
import Combine

public final class PlannerViewModel: ObservableObject {

    @Published public var blueprint: MissionBlueprint
    @Published public var targetAscentRate: Double = 5.0
    @Published public var gasPrice: Double

    @Published public private(set) var prediction: FlightPrediction
    @Published public private(set) var warnings: [String] = []

    private var cancellables = Set<AnyCancellable>()

    public init(blueprint: MissionBlueprint = MissionBlueprint()) {
        self.blueprint = blueprint
        self.gasPrice = blueprint.gas.defaultPricePerCubicMeter
        self.prediction = FlightSolver.predict(blueprint)

        Publishers.CombineLatest($blueprint, $gasPrice)
            .removeDuplicates { $0.0 == $1.0 && $0.1 == $1.1 }
            .debounce(for: .milliseconds(16), scheduler: DispatchQueue.global(qos: .userInitiated))
            .map { blueprint, price in
                (FlightSolver.predict(blueprint, gasPricePerCubicMeter: price), blueprint)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prediction, blueprint in
                self?.prediction = prediction
                self?.warnings = FlightSolver.warnings(for: prediction, blueprint: blueprint)
            }
            .store(in: &cancellables)
    }

    public func fillForTargetRate() {
        blueprint.launchGasVolume = FlightSolver.gasVolume(forTargetAscentRate: targetAscentRate,
                                                          blueprint: blueprint)
    }
}

public struct MissionPlannerView: View {

    @StateObject private var model: PlannerViewModel
    private let onLaunch: (MissionBlueprint) -> Void

    public init(blueprint: MissionBlueprint = MissionBlueprint(),
                onLaunch: @escaping (MissionBlueprint) -> Void) {
        _model = StateObject(wrappedValue: PlannerViewModel(blueprint: blueprint))
        self.onLaunch = onLaunch
    }

    public var body: some View {
        ZStack {
            Image("backGameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.42)],
                startPoint: .init(x: 0.5, y: 0.55),
                endPoint: .bottom
            ).ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    readout
                    hardware
                    loadout
                    if !model.warnings.isEmpty { warningBlock }
                    launchButton
                }
                .padding(.vertical, 50)
                .padding(Metrics.gutter)
            }
        }
    }

    // MARK: - Readout

    private var readout: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Mission name — editable directly in the planner
            TextField("Mission Name", text: $model.blueprint.name)
                .font(Font(Typography.display(22, weight: .semibold)))
                .foregroundColor(Color(Palette.inkDeep))
                .submitLabel(.done)
                .padding(.bottom, 2)

            Text("Mission Estimate")
                .font(Font(Typography.display(13)))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.inkSoft))

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(String(format: "%.1f", model.prediction.burstAltitude / 1000))
                    .font(Font(Typography.data(56, weight: .semibold)))
                Text("km to burst")
                    .font(Font(Typography.display(15)))
                    .foregroundColor(Color(Palette.inkSoft))
            }
            .foregroundColor(Color(Palette.inkDeep))

            Divider().background(Color(Palette.chartRule))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                metric("Ascent Rate",    String(format: "%.1f m/s", model.prediction.ascentRate))
                metric("Free Lift",      String(format: "%.2f kg",  model.prediction.freeLift))
                metric("Neck Lift",      String(format: "%.2f kg",  model.prediction.neckLift))
                metric("Time to Burst",  duration(model.prediction.timeToBurst))
                metric("Descent",        duration(model.prediction.descentDuration))
                metric("Landing Speed",  String(format: "%.1f m/s", model.prediction.landingSpeed))
                metric("Wind Drift",     String(format: "%.0f km",  model.prediction.horizontalDrift / 1000))
                metric("Gas",            String(format: "%.1f m³ · %.0f",
                                                model.prediction.launchGasVolume,
                                                model.prediction.gasCost))
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Font(Typography.display(11)))
                .textCase(.uppercase)
                .kerning(0.8)
                .foregroundColor(Color(Palette.inkSoft))
            Text(value)
                .font(Font(Typography.data(18, weight: .medium)))
                .foregroundColor(Color(Palette.inkDeep))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Hardware

    private var hardware: some View {
        section("Envelope & Gas") {
            Picker("Balloon model", selection: $model.blueprint.balloon) {
                ForEach(BalloonSpec.catalog) { spec in
                    Text("\(spec.model) · burst \(String(format: "%.2f", spec.burstDiameter)) m")
                        .tag(spec)
                }
            }
            .pickerStyle(.menu)
            .tint(Color(Palette.brass))

            Picker("Gas", selection: $model.blueprint.gas) {
                ForEach(LiftGas.allCases) { gas in Text(gas.title).tag(gas) }
            }
            .pickerStyle(.segmented)

            slider("Gas price per m³", value: $model.gasPrice, range: 20...900, format: "%.0f")
        }
    }

    // MARK: - Loadout

    private var loadout: some View {
        section("Payload") {
            slider("Payload mass, kg",        value: $model.blueprint.payloadMass,    range: 0.1...6,    format: "%.2f")
            slider("Ballast, kg",             value: $model.blueprint.ballastMass,    range: 0...3,      format: "%.2f")
            slider("Launch gas volume, m³",   value: $model.blueprint.launchGasVolume, range: 0.5...20, format: "%.2f")
            slider("Launch elevation, m",     value: $model.blueprint.launchElevation, range: 0...2500, format: "%.0f")

            HStack {
                slider("Target ascent rate, m/s", value: $model.targetAscentRate, range: 2...9, format: "%.1f")
                Button("Auto-fill") { model.fillForTargetRate() }
                    .font(Font(Typography.display(14)))
                    .foregroundColor(Color(Palette.brass))
            }
        }
    }

    private var warningBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pre-launch Warnings")
                .font(Font(Typography.display(12)))
                .textCase(.uppercase)
                .kerning(1.2)
                .foregroundColor(Color(Palette.signal))
            ForEach(model.warnings, id: \.self) { text in
                HStack(alignment: .top, spacing: 8) {
                    Rectangle()
                        .fill(Color(Palette.signal))
                        .frame(width: 2)
                    Text(text)
                        .font(Font(Typography.body(14)))
                        .foregroundColor(Color(Palette.inkDeep))
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(Color(Palette.signal).opacity(0.07))
        .cornerRadius(Metrics.panelRadius)
    }

    private var launchButton: some View {
        Button {
            onLaunch(model.blueprint)
        } label: {
            Text("Launch This Mission")
                .font(Font(Typography.display(17, weight: .semibold)))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color(Palette.inkDeep))
                .foregroundColor(Color(Palette.chartPaper))
                .cornerRadius(Metrics.panelRadius)
        }
        .disabled(model.prediction.freeLift <= 0)
        .opacity(model.prediction.freeLift <= 0 ? 0.4 : 1)
    }

    // MARK: - Building blocks

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(Font(Typography.display(12)))
                .textCase(.uppercase)
                .kerning(1.4)
                .foregroundColor(Color(Palette.inkSoft))
            content()
        }
    }

    private func slider(_ label: String, value: Binding<Double>,
                        range: ClosedRange<Double>, format: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(Font(Typography.body(13)))
                    .foregroundColor(Color(Palette.inkSoft))
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .font(Font(Typography.data(14, weight: .semibold)))
                    .foregroundColor(Color(Palette.inkDeep))
            }
            Slider(value: value, in: range)
                .tint(Color(Palette.brass))
        }
    }

    private func duration(_ seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d h %02d min", total / 3600, (total % 3600) / 60)
    }
}
