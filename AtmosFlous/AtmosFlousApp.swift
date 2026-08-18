import SwiftUI

@main
struct AtmosFlousApp: App {
    @AppStorage("onboarding.v1.completed") private var onboardingCompleted = false
    @State private var splashFinished = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !splashFinished {
                    SplashView(isFinished: $splashFinished)
                } else if !onboardingCompleted {
                    OnboardingView(isCompleted: $onboardingCompleted)
                        .transition(.opacity)
                } else {
                    ContentView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.38), value: splashFinished)
            .animation(.easeInOut(duration: 0.38), value: onboardingCompleted)
        }
    }
}
