import UIKit
import SwiftUI
import WebKit
import AVFoundation
import Combine

@MainActor
final class DowndraftEdgeSinking: ObservableObject {

    @Published var driftAngleSet = false
    @Published var headingMarkCompass = true

    weak var bearingRingMagnetic: BalloonAirAccepted?

    func gasCanopyShown() {
        bearingRingMagnetic?.gasCanopyShown()
    }
}

struct LiftLineThermal: View {

    let sphereStart: URL
    var firstFloatView: (() -> Void)?

    @StateObject private var burnerFlame = DowndraftEdgeSinking()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SinkLineSubsidence(sphereStart: sphereStart, burnerFlame: burnerFlame, firstFloatView: firstFloatView)
                .ignoresSafeArea()

            if burnerFlame.headingMarkCompass {
                showBottomRiseingOverlay
            }

            if burnerFlame.driftAngleSet && !burnerFlame.headingMarkCompass {
                windSpeedGround
            }
        }
        .animation(.easeInOut(duration: 0.25), value: burnerFlame.headingMarkCompass)
        .animation(.easeInOut(duration: 0.2), value: burnerFlame.driftAngleSet)
        .task {
      
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            burnerFlame.headingMarkCompass = false
        }
    }

    private var showBottomRiseingOverlay: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ProgressView()
                .controlSize(.large)
                .tint(.white)
        }
        .transition(.opacity)
    }

    private var windSpeedGround: some View {
        VStack {
            HStack {
                Button {
                    burnerFlame.gasCanopyShown()
                } label: {
                    Image(systemName: "chevron.backward.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.35), radius: 4, y: 1)
                }
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
                .padding(.leading, 12)
                .padding(.top, 15)

                Spacer()
            }
            Spacer()
        }
        .padding(.top, 15)
        .transition(.opacity)
    }
}

private struct SinkLineSubsidence: UIViewControllerRepresentable {

    let sphereStart: URL
    let burnerFlame: DowndraftEdgeSinking
    var firstFloatView: (() -> Void)?

    func makeUIViewController(context: Context) -> BalloonAirAccepted {
        BalloonAirAccepted(sphereStart: sphereStart, burnerFlame: burnerFlame, firstFloatView: firstFloatView)
    }

    func updateUIViewController(_ uiViewController: BalloonAirAccepted, context: Context) {
    }
}
