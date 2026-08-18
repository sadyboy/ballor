import SwiftUI

struct ProfileView: View {
    @ObservedObject private var logbook = FlightLogbook.shared
    @AppStorage("pilot.name") private var pilotName: String = ""
    @State private var showNameEdit = false

    private var stats: PilotStats { PilotStats(from: logbook.records) }

    var body: some View {
        ZStack(alignment: .top) {
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
                VStack(alignment: .leading, spacing: 0) {
                    header
                    statsGrid
                    recentSection
                    lessonLibrary
                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showNameEdit) {
            PilotNameSheet(name: $pilotName)
        }
    }

    // MARK: - Header

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            // Sky gradient
            LinearGradient(
                colors: [Color(Palette.inkDeep), Color(Palette.inkSoft)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 210)

            // Live star field (SpriteKit)
            CosmicSpriteView()
                .frame(height: 210)

            // Pilot card
            HStack(alignment: .bottom, spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color(Palette.brass).opacity(0.15))
                        .frame(width: 72, height: 72)
                    Circle()
                        .strokeBorder(Color(Palette.brass).opacity(0.5), lineWidth: 1.5)
                        .frame(width: 72, height: 72)
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color(Palette.brass))
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(pilotName.isEmpty ? "Unnamed Pilot" : pilotName)
                        .font(Font(Typography.display(22, weight: .semibold)))
                        .foregroundColor(Color(Palette.chartPaper))

                    HStack(spacing: 6) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 11))
                        Text("\(logbook.records.count) mission\(logbook.records.count == 1 ? "" : "s") logged")
                            .font(Font(Typography.body(13)))
                    }
                    .foregroundColor(Color(Palette.chartPaper).opacity(0.5))
                }

                Spacer()

                Button {
                    showNameEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(Palette.brass))
                        .frame(width: 36, height: 36)
                        .background(Color(Palette.brass).opacity(0.15))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 22)
        }
    }

    // MARK: - Stats

    private var statsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("Personal Records")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                statCard(
                    icon: "arrow.up.to.line",
                    iconColor: Palette.verdigris,
                    label: "Peak Altitude",
                    value: stats.peakAltitude > 0 ? String(format: "%.0f m", stats.peakAltitude) : "—"
                )
                statCard(
                    icon: "arrow.left.and.right",
                    iconColor: Palette.brass,
                    label: "Max Drift",
                    value: stats.maxDrift > 0 ? String(format: "%.0f km", stats.maxDrift / 1000) : "—"
                )
                statCard(
                    icon: "thermometer.medium",
                    iconColor: Palette.verdigris,
                    label: "Samples Taken",
                    value: "\(stats.totalSamples)"
                )
                statCard(
                    icon: "lightbulb.fill",
                    iconColor: Palette.brass,
                    label: "Lessons Earned",
                    value: "\(stats.totalLessons)"
                )
                statCard(
                    icon: "stopwatch",
                    iconColor: Palette.chartPaper,
                    label: "Total Flight Time",
                    value: stats.totalDuration > 0 ? durationString(stats.totalDuration) : "—"
                )
                statCard(
                    icon: "flag.fill",
                    iconColor: Palette.signal,
                    label: "Flights Completed",
                    value: "\(logbook.records.count)"
                )
            }
        }
        .padding(20)
    }

    private func statCard(icon: String, iconColor: UIColor, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(Color(iconColor))

            Text(value)
                .font(Font(Typography.data(28, weight: .semibold)))
                .foregroundColor(Color(Palette.inkDeep))
                .minimumScaleFactor(0.55)
                .lineLimit(1)

            Text(label)
                .font(Font(Typography.display(9)))
                .textCase(.uppercase)
                .kerning(0.5)
                .foregroundColor(Color(Palette.inkSoft))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(Palette.chartRule).opacity(0.28))
        .cornerRadius(Metrics.panelRadius)
    }

    // MARK: - Recent missions

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionLabel("Recent Missions")

            if logbook.records.isEmpty {
                Text("No missions yet. Launch your first balloon from the Mission tab.")
                    .font(Font(Typography.body(14)))
                    .foregroundColor(Color(Palette.inkSoft))
                    .padding(.horizontal, 20)
                    .lineSpacing(4)
            } else {
                VStack(spacing: 0) {
                    ForEach(logbook.records.prefix(5)) { record in
                        ProfileMissionRow(record: record)
                        if record.id != logbook.records.prefix(5).last?.id {
                            Divider()
                                .background(Color(Palette.chartRule))
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Color(Palette.chartRule).opacity(0.18))
                .cornerRadius(Metrics.panelRadius)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Lesson library

    private var lessonLibrary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                sectionLabel("Lesson Library")
                Spacer()
                Text("\(Curriculum.lessons.count) lessons")
                    .font(Font(Typography.data(12)))
                    .foregroundColor(Color(Palette.inkSoft))
                    .padding(.trailing, 20)
            }

            Text("Each lesson unlocks when its flight condition is met. Complete missions to earn insights.")
                .font(Font(Typography.body(12)))
                .foregroundColor(Color(Palette.inkSoft))
                .lineSpacing(3)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)

            VStack(spacing: 0) {
                ForEach(Array(Curriculum.lessons.enumerated()), id: \.offset) { i, lesson in
                    LessonLibraryRow(index: i + 1, lesson: lesson)
                    if i < Curriculum.lessons.count - 1 {
                        Divider()
                            .background(Color(Palette.chartRule))
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(Palette.chartRule).opacity(0.18))
            .cornerRadius(Metrics.panelRadius)
            .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Font(Typography.display(11)))
            .textCase(.uppercase)
            .kerning(1.4)
            .foregroundColor(Color(Palette.inkSoft))
            .padding(.horizontal, 20)
    }

    private func durationString(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600
        let m = (Int(t) % 3600) / 60
        return h > 0 ? "\(h)h \(m)m" : "\(m)m"
    }
}

// MARK: - Mission row

private struct ProfileMissionRow: View {
    let record: FlightRecord

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.missionName)
                    .font(Font(Typography.display(14, weight: .semibold)))
                    .foregroundColor(Color(Palette.inkDeep))

                Text(String(format: "%.0f m  ·  %.0f km drift  ·  %d samples",
                            record.peakAltitude,
                            record.horizontalDrift / 1000,
                            record.samplesCaptured))
                    .font(Font(Typography.data(11)))
                    .foregroundColor(Color(Palette.inkSoft))
            }

            Spacer()

            if record.lessonsCompleted > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 10))
                    Text("\(record.lessonsCompleted)")
                        .font(Font(Typography.display(12, weight: .semibold)))
                }
                .foregroundColor(Color(Palette.brass))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(Palette.brass).opacity(0.1))
                .cornerRadius(Metrics.panelRadius)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }
}

// MARK: - Lesson library row

private struct LessonLibraryRow: View {
    let index: Int
    let lesson: Lesson

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Index badge
            Text(String(format: "%02d", index))
                .font(Font(Typography.data(12, weight: .semibold)))
                .foregroundColor(Color(Palette.brass))
                .frame(width: 28, alignment: .center)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(Font(Typography.display(13, weight: .semibold)))
                    .foregroundColor(Color(Palette.inkDeep))

                Text(lesson.question)
                    .font(Font(Typography.body(11)))
                    .foregroundColor(Color(Palette.inkSoft))
                    .fixedSize(horizontal: false, vertical: true)

                if let unlocks = lesson.unlocks {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 9))
                        Text(unlocks)
                            .font(Font(Typography.display(10)))
                    }
                    .foregroundColor(Color(Palette.verdigris).opacity(0.8))
                    .padding(.top, 2)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Name editor sheet

struct PilotNameSheet: View {
    @Binding var name: String
    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("How should the logbook address you?")
                    .font(Font(Typography.body(15)))
                    .foregroundColor(Color(Palette.inkSoft))
                    .padding(.top, 8)

                TextField("Pilot name", text: $draft)
                    .font(Font(Typography.data(17)))
                    .padding(14)
                    .background(Color(Palette.chartRule).opacity(0.35))
                    .cornerRadius(Metrics.panelRadius)

                Spacer()
            }
            .padding(.horizontal, 20)
            .background(Color(Palette.chartPaper).ignoresSafeArea())
            .navigationTitle("Edit Pilot Name")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(Palette.inkSoft))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        name = draft.trimmingCharacters(in: .whitespaces)
                        dismiss()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(Color(Palette.brass))
                }
            }
        }
        .onAppear { draft = name }
    }
}

// MARK: - Stats model

struct PilotStats {
    let peakAltitude: Double
    let maxDrift: Double
    let totalSamples: Int
    let totalLessons: Int
    let totalDuration: TimeInterval

    init(from records: [FlightRecord]) {
        peakAltitude  = records.map(\.peakAltitude).max() ?? 0
        maxDrift      = records.map(\.horizontalDrift).max() ?? 0
        totalSamples  = records.map(\.samplesCaptured).reduce(0, +)
        totalLessons  = records.map(\.lessonsCompleted).reduce(0, +)
        totalDuration = records.map(\.duration).reduce(0, +)
    }
}
