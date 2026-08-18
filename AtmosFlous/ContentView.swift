import SwiftUI

struct ContentView: View {
    @State private var activeBlueprint: MissionBlueprint?

    var body: some View {
        TabView {
            MissionPlannerView { blueprint in
                activeBlueprint = blueprint
            }
            .tabItem { Label("Mission", systemImage: "dial.medium") }

            AtmosphereExplorerView()
                .tabItem { Label("Atmosphere", systemImage: "aqi.medium") }

            LessonsView()
                .tabItem { Label("Learn", systemImage: "graduationcap.fill") }

            LogbookView()
                .tabItem { Label("Logbook", systemImage: "book.closed.fill") }

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
        .tint(Color(Palette.brass))
        .fullScreenCover(item: $activeBlueprint) { blueprint in
            MissionViewControllerWrapper(blueprint: blueprint)
                .ignoresSafeArea()
        }
    }
}

private struct MissionViewControllerWrapper: UIViewControllerRepresentable {
    let blueprint: MissionBlueprint

    func makeUIViewController(context: Context) -> MissionViewController {
        MissionViewController(blueprint: blueprint)
    }

    func updateUIViewController(_ uiViewController: MissionViewController, context: Context) {}
}

#Preview {
    ContentView()
}
