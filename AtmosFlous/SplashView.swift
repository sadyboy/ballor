import SwiftUI

struct SplashView: View {
    @Binding var isFinished: Bool
    @State private var titleOpacity: Double = 0
    @State private var titleOffset: CGFloat = 20
    @State private var balloonY: CGFloat = 30
    @State private var starsOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0

    var body: some View {
        ZStack {
            Image("backGameImg")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Tonal vignette: dark at bottom where balloon + text live
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.72)],
                startPoint: .init(x: 0.5, y: 0.28),
                endPoint: .bottom
            )
            .ignoresSafeArea()

            CosmicSpriteView()
                .ignoresSafeArea()
                .opacity(starsOpacity * 0.5)

            VStack(spacing: 0) {
                Spacer()

                SplashBalloon()
                    .offset(y: balloonY)
                    .padding(.bottom, 52)

                VStack(spacing: 12) {
                    Text("ATMOSFLOUS")
                        .font(Font(Typography.display(38, weight: .semibold)))
                        .foregroundColor(Color(Palette.chartPaper))
                        .kerning(6)
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 0, y: 3)

                    Text("HIGH-ALTITUDE BALLOON MISSION PLANNER")
                        .font(Font(Typography.display(9)))
                        .foregroundColor(Color(Palette.brass))
                        .kerning(2.5)
                        .shadow(color: .black.opacity(0.75), radius: 6, x: 0, y: 2)
                        .opacity(subtitleOpacity)
                }
                .opacity(titleOpacity)
                .offset(y: titleOffset)

                Spacer()
                Spacer()
            }
        }
        .onAppear { animate() }
    }

    private func animate() {
        withAnimation(.easeOut(duration: 0.9)) { starsOpacity = 1 }
        withAnimation(.easeOut(duration: 0.65).delay(0.25)) {
            titleOpacity = 1
            titleOffset = 0
        }
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) { subtitleOpacity = 1 }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            balloonY = -18
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) {
            withAnimation(.easeIn(duration: 0.45)) {
                titleOpacity = 0
                starsOpacity = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isFinished = true
            }
        }
    }
}

// MARK: - Balloon illustration

private struct PressureRing: View {
    let delay: Double
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.5

    var body: some View {
        Circle()
            .strokeBorder(Color(Palette.chartPaper), lineWidth: 1)
            .frame(width: 104, height: 104)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeOut(duration: 2.4).delay(delay).repeatForever(autoreverses: false)) {
                    scale = 3.8
                    opacity = 0
                }
            }
    }
}

private struct SplashBalloon: View {
    var body: some View {
        ZStack {
            // Expanding pressure rings
            PressureRing(delay: 0)
            PressureRing(delay: 0.8)
            PressureRing(delay: 1.6)

            // Glow
            Ellipse()
                .fill(Color(Palette.chartPaper).opacity(0.07))
                .frame(width: 130, height: 150)
                .blur(radius: 16)

            // Body
            Ellipse()
                .fill(Color(Palette.chartPaper).opacity(0.9))
                .frame(width: 80, height: 98)

            // Specular highlight
            Ellipse()
                .fill(Color.white.opacity(0.22))
                .frame(width: 28, height: 38)
                .offset(x: -16, y: -18)

            // Seam lines
            ForEach([-18, 0, 18], id: \.self) { x in
                Ellipse()
                    .stroke(Color(Palette.inkDeep).opacity(0.08), lineWidth: 1)
                    .frame(width: CGFloat(x == 0 ? 80 : 44), height: 98)
                    .offset(x: CGFloat(x))
            }

            // Tether
            Path { p in
                p.move(to: CGPoint(x: 0, y: 49))
                p.addLine(to: CGPoint(x: 0, y: 84))
            }
            .stroke(Color(Palette.inkDeep).opacity(0.45), lineWidth: 1.5)

            // Payload
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(Palette.brass))
                .frame(width: 26, height: 16)
                .offset(y: 92)

            // Brass accent stripe on payload
            Rectangle()
                .fill(Color(Palette.inkDeep).opacity(0.2))
                .frame(width: 26, height: 1.5)
                .offset(y: 92)
        }
        .frame(width: 130, height: 110)
    }
}

