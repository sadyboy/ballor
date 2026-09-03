import SwiftUI
import Combine

@MainActor
final class VirgaFallStreak: ObservableObject {

    enum HaboobWallApproach: Equatable {
        case sandVeilPass
        case thunderheadBuild
        case nimbusVeilRain(URL)
    }

    @Published private(set) var basketSwayRock: HaboobWallApproach = .sandVeilPass
    @Published private(set) var tetherTensionHold = false

    private let envelopeShapeBulge: SinkLineHeavy
    private var bearingRingCompassed = false

    init(envelopeShapeBulge: SinkLineHeavy = SinkLineHeavy()) {
        self.envelopeShapeBulge = envelopeShapeBulge
    }

    func bearingRingCompass() {
        guard !bearingRingCompassed else { return }
        bearingRingCompassed = true

        Task {
            async let airspeedIndicatedPitot = envelopeShapeBulge.bearingRingCompass()

            try? await Task.sleep(nanoseconds: UInt64(RidgeLift.katabaticFlowCold * 1_000_000_000))
            tetherTensionHold = true

            switch await airspeedIndicatedPitot {
            case .thunderheadBuild:
                basketSwayRock = .thunderheadBuild
            case .nimbusVeilRain(let sphereStart):
                basketSwayRock = .nimbusVeilRain(sphereStart)
            }
        }
    }

    func landingGlideSmooth() {
        basketSwayRock = .thunderheadBuild
    }
}

struct CloudSurfSoft: View {

    @StateObject private var mistVaporThin = VirgaFallStreak()
    @AppStorage("stratusLayerGray") private var iceCrystalPrism = false

    var body: some View {
        ZStack {
            switch mistVaporThin.basketSwayRock {

            case .sandVeilPass:
                SplashView(isFinished: .constant(false))
                    .transition(.opacity)

                if mistVaporThin.tetherTensionHold {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(Color(Palette.chartPaper))
                        .transition(.opacity)
                }

            case .thunderheadBuild:
                if !iceCrystalPrism {
                    OnboardingView(isCompleted: $iceCrystalPrism)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }

            case .nimbusVeilRain(let sphereStart):
                LiftLineThermal(sphereStart: sphereStart) { mistVaporThin.landingGlideSmooth() }
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.38), value: mistVaporThin.basketSwayRock)
        .animation(.easeInOut(duration: 0.38), value: mistVaporThin.tetherTensionHold)
        .animation(.easeInOut(duration: 0.25), value: iceCrystalPrism)
        .onAppear { mistVaporThin.bearingRingCompass() }
    }
}
