import SwiftUI

// MARK: - Main screen

struct LessonsView: View {
    @ObservedObject private var logbook = FlightLogbook.shared

    private var unlockedIds: Set<String> { logbook.unlockedLessonIds }
    private var unlockedCount: Int { unlockedIds.count }
    private var total: Int { Curriculum.lessons.count }

    var body: some View {
        NavigationStack {
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
                    VStack(spacing: 0) {
                        academyHeader
                        lessonCards
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header

    private var academyHeader: some View {
        ZStack(alignment: .bottomLeading) {
            // Sky gradient background
            LinearGradient(
                colors: [Color(Palette.inkDeep), Color(UIColor(hex: 0x1A2A44))],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: 220)

            // Live star field (SpriteKit)
            CosmicSpriteView()
                .frame(height: 220)

            // Constellation: lesson progress map
            ConstellationMap(unlockedIds: unlockedIds)
                .frame(height: 220)

            VStack(alignment: .leading, spacing: 16) {
                Text("FLIGHT ACADEMY")
                    .font(Font(Typography.display(11)))
                    .kerning(2.8)
                    .foregroundColor(Color(Palette.brass))

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(unlockedCount) of \(total)")
                        .font(Font(Typography.data(42, weight: .semibold)))
                        .foregroundColor(Color(Palette.chartPaper))
                    Text("insights discovered")
                        .font(Font(Typography.display(15)))
                        .foregroundColor(Color(Palette.chartPaper).opacity(0.6))
                }

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(Palette.chartPaper).opacity(0.12))
                            .frame(height: 5)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(Palette.brass))
                            .frame(
                                width: unlockedCount == 0 ? 0 :
                                    geo.size.width * CGFloat(unlockedCount) / CGFloat(total),
                                height: 5
                            )
                            .animation(.spring(duration: 0.6), value: unlockedCount)
                    }
                }
                .frame(height: 5)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 26)
        }
    }

    // MARK: - Lesson cards

    private var lessonCards: some View {
        VStack(spacing: 10) {
            ForEach(Array(Curriculum.lessons.enumerated()), id: \.offset) { i, lesson in
                let isUnlocked = unlockedIds.contains(lesson.id)
                NavigationLink {
                    LessonDetailView(lesson: lesson, isUnlocked: isUnlocked)
                } label: {
                    LessonCard(index: i + 1, lesson: lesson, isUnlocked: isUnlocked)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 36)
    }
}

// MARK: - Lesson card

private struct LessonCard: View {
    let index: Int
    let lesson: Lesson
    let isUnlocked: Bool

    @State private var appeared = false

    var body: some View {
        HStack(spacing: 0) {
            // Status stripe
            Rectangle()
                .fill(isUnlocked ? Color(Palette.brass) : Color(Palette.chartRule).opacity(0.5))
                .frame(width: 3)

            HStack(spacing: 14) {
                // Number + status icon
                VStack(spacing: 6) {
                    Text(String(format: "%02d", index))
                        .font(Font(Typography.data(13, weight: .semibold)))
                        .foregroundColor(
                            isUnlocked ? Color(Palette.brass) : Color(Palette.inkSoft).opacity(0.35)
                        )

                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .font(.system(size: isUnlocked ? 15 : 12))
                        .foregroundColor(
                            isUnlocked ? Color(Palette.verdigris) : Color(Palette.chartRule)
                        )
                }
                .frame(width: 34)

                // Text content
                VStack(alignment: .leading, spacing: 5) {
                    Text(lesson.title)
                        .font(Font(Typography.display(15, weight: .semibold)))
                        .foregroundColor(
                            isUnlocked ? Color(Palette.inkDeep) : Color(Palette.inkDeep).opacity(0.4)
                        )

                    Text(isUnlocked
                         ? lesson.insight.prefix(90).appending("…")
                         : lesson.question)
                        .font(Font(Typography.body(12)))
                        .foregroundColor(
                            isUnlocked ? Color(Palette.inkSoft) : Color(Palette.inkSoft).opacity(0.5)
                        )
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    if isUnlocked, let formula = lesson.formula {
                        Text(formula)
                            .font(Font(Typography.data(11)))
                            .foregroundColor(Color(Palette.verdigris))
                            .lineLimit(1)
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(
                        isUnlocked ? Color(Palette.brass) : Color(Palette.chartRule)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: Metrics.panelRadius)
                .fill(Color(isUnlocked ? Palette.chartPaper : Palette.inkDeep).opacity(isUnlocked ? 1 : 0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.panelRadius)
                .strokeBorder(
                    isUnlocked ? Color(Palette.chartRule).opacity(0.45) : Color(Palette.chartRule).opacity(0.18),
                    lineWidth: 1
                )
        )
        .cornerRadius(Metrics.panelRadius)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 14)
        .onAppear {
            withAnimation(.easeOut(duration: 0.45).delay(Double(index - 1) * 0.055)) {
                appeared = true
            }
        }
    }
}

// MARK: - Lesson detail

struct LessonDetailView: View {
    let lesson: Lesson
    let isUnlocked: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .top) {
            Color(Palette.chartPaper).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    detailHeader
                    detailBody
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Academy")
                            .font(Font(Typography.display(14)))
                    }
                    .foregroundColor(Color(Palette.brass))
                }
            }
        }
    }

    // MARK: Dark header

    private var detailHeader: some View {
        ZStack(alignment: .bottomLeading) {
            Color(Palette.inkDeep)
                .frame(minHeight: 200)

            VStack(alignment: .leading, spacing: 12) {
                // Status badge
                HStack(spacing: 6) {
                    Image(systemName: isUnlocked ? "checkmark.circle.fill" : "lock.fill")
                        .font(.system(size: 13))
                    Text(isUnlocked ? "Insight Discovered" : "Locked")
                        .font(Font(Typography.display(11)))
                        .textCase(.uppercase)
                        .kerning(1.4)
                }
                .foregroundColor(
                    isUnlocked ? Color(Palette.verdigris) : Color(Palette.chartPaper).opacity(0.4)
                )

                Text(lesson.title)
                    .font(Font(Typography.display(30, weight: .semibold)))
                    .foregroundColor(Color(Palette.chartPaper))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 60)
            .padding(.bottom, 28)
        }
    }

    // MARK: Content body

    @ViewBuilder
    private var detailBody: some View {
        if isUnlocked {
            unlockedContent
        } else {
            lockedContent
        }
    }

    private var unlockedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Insight text
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("Insight")
                Text(lesson.insight)
                    .font(Font(Typography.body(16)))
                    .foregroundColor(Color(Palette.inkDeep))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Formula block
            if let formula = lesson.formula {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Formula")
                    Text(formula)
                        .font(Font(Typography.data(15)))
                        .foregroundColor(Color(Palette.verdigris))
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(Palette.verdigris).opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: Metrics.panelRadius)
                                .strokeBorder(Color(Palette.verdigris).opacity(0.2), lineWidth: 1)
                        )
                        .cornerRadius(Metrics.panelRadius)
                }
            }

            // Mission condition
            VStack(alignment: .leading, spacing: 8) {
                sectionLabel("Unlocked by")
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 14))
                        .foregroundColor(Color(Palette.brass))
                        .padding(.top, 1)
                    Text(lesson.question)
                        .font(Font(Typography.body(14)))
                        .foregroundColor(Color(Palette.inkDeep))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Unlocks badge
            if let unlocks = lesson.unlocks {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 13))
                    Text("Unlocks: \(unlocks)")
                        .font(Font(Typography.display(13, weight: .semibold)))
                }
                .foregroundColor(Color(Palette.brass))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(Palette.brass).opacity(0.1))
                .cornerRadius(Metrics.panelRadius)
            }
        }
        .padding(24)
    }

    private var lockedContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                sectionLabel("How to unlock")
                Text(lesson.question)
                    .font(Font(Typography.display(20, weight: .semibold)))
                    .foregroundColor(Color(Palette.inkDeep))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("Complete this mission objective and the full scientific insight will be revealed in your debrief.")
                .font(Font(Typography.body(15)))
                .foregroundColor(Color(Palette.inkSoft))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // Teaser: formula hidden but visible
            if lesson.formula != nil {
                VStack(alignment: .leading, spacing: 8) {
                    sectionLabel("Formula")
                    ZStack {
                        Text("P = ρ · R · T  ···  d = ∛(6V/π)")
                            .font(Font(Typography.data(15)))
                            .foregroundColor(Color(Palette.verdigris).opacity(0.3))
                            .redacted(reason: .placeholder)
                        Text("Unlock to reveal")
                            .font(Font(Typography.display(12)))
                            .foregroundColor(Color(Palette.inkSoft))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(Palette.chartRule).opacity(0.2))
                    .cornerRadius(Metrics.panelRadius)
                }
            }

            // Hint: what mission type helps
            HStack(spacing: 10) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 14))
                    .foregroundColor(Color(Palette.brass))
                Text("Head to the Mission tab, configure your balloon, and launch.")
                    .font(Font(Typography.body(13)))
                    .foregroundColor(Color(Palette.inkSoft))
            }
            .padding(14)
            .background(Color(Palette.brass).opacity(0.07))
            .cornerRadius(Metrics.panelRadius)
        }
        .padding(24)
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Font(Typography.display(10)))
            .textCase(.uppercase)
            .kerning(1.4)
            .foregroundColor(Color(Palette.inkSoft))
    }
}

// MARK: - Constellation progress map

private struct ConstellationMap: View {
    let unlockedIds: Set<String>

    // 11 stars arranged as a zigzag constellation across the header's upper region
    private let starPositions: [(CGFloat, CGFloat)] = [
        (0.07, 0.26), (0.17, 0.09), (0.28, 0.30),
        (0.38, 0.12), (0.48, 0.28), (0.58, 0.09),
        (0.67, 0.32), (0.76, 0.14), (0.84, 0.30),
        (0.92, 0.36), (0.97, 0.16),
    ]

    @State private var pulseScale: CGFloat = 1.0
    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            let activePairs = (0..<min(starPositions.count - 1, Curriculum.lessons.count - 1)).filter { i in
                unlockedIds.contains(Curriculum.lessons[i].id) &&
                unlockedIds.contains(Curriculum.lessons[i + 1].id)
            }

            ZStack {
                // Animated connection lines between consecutive unlocked stars
                ForEach(activePairs, id: \.self) { i in
                    AnimatedLineView(
                        start: CGPoint(x: starPositions[i].0 * geo.size.width,
                                       y: starPositions[i].1 * geo.size.height),
                        end: CGPoint(x: starPositions[i + 1].0 * geo.size.width,
                                     y: starPositions[i + 1].1 * geo.size.height),
                        delay: Double(i) * 0.10
                    )
                }

                // Stars
                ForEach(0..<min(starPositions.count, Curriculum.lessons.count), id: \.self) { i in
                    let pos = starPositions[i]
                    let isUnlocked = unlockedIds.contains(Curriculum.lessons[i].id)

                    ZStack {
                        if isUnlocked {
                            Circle()
                                .fill(Color(Palette.brass).opacity(0.15))
                                .frame(width: 24, height: 24)
                                .scaleEffect(pulseScale)
                        }
                        Circle()
                            .fill(isUnlocked ? Color(Palette.brass) : Color.white.opacity(0.22))
                            .frame(width: isUnlocked ? 6 : 2.5,
                                   height: isUnlocked ? 6 : 2.5)
                    }
                    .position(x: pos.0 * geo.size.width, y: pos.1 * geo.size.height)
                    .animation(.easeInOut(duration: 0.5), value: isUnlocked)
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .onAppear {
            withAnimation(.easeIn(duration: 1.6)) { appeared = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.9
            }
        }
    }
}

private struct AnimatedLineView: View {
    let start: CGPoint
    let end: CGPoint
    let delay: Double

    @State private var progress: CGFloat = 0

    var body: some View {
        Path { p in
            p.move(to: start)
            p.addLine(to: end)
        }
        .trim(from: 0, to: progress)
        .stroke(Color(Palette.brass).opacity(0.38),
                style: StrokeStyle(lineWidth: 1, dash: [4, 5]))
        .onAppear {
            withAnimation(.easeInOut(duration: 0.85).delay(delay)) {
                progress = 1
            }
        }
    }
}
