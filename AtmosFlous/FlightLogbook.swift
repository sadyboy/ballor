import SwiftUI
import Combine

// MARK: - Record model

public struct FlightRecord: Identifiable {
    public let id: UUID
    public let missionName: String
    public let date: Date
    public let peakAltitude: Double
    public let horizontalDrift: Double
    public let samplesCaptured: Int
    public let balloonModel: String
    public let gasTitle: String
    public let lessonsCompleted: Int
    public let lessonIds: [String]
    public let duration: TimeInterval
}

extension FlightRecord: Codable {
    enum CodingKeys: String, CodingKey {
        case id, missionName, date, peakAltitude, horizontalDrift, samplesCaptured
        case balloonModel, gasTitle, lessonsCompleted, lessonIds, duration
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,         forKey: .id)
        missionName      = try c.decode(String.self,       forKey: .missionName)
        date             = try c.decode(Date.self,         forKey: .date)
        peakAltitude     = try c.decode(Double.self,       forKey: .peakAltitude)
        horizontalDrift  = try c.decode(Double.self,       forKey: .horizontalDrift)
        samplesCaptured  = try c.decode(Int.self,          forKey: .samplesCaptured)
        balloonModel     = try c.decode(String.self,       forKey: .balloonModel)
        gasTitle         = try c.decode(String.self,       forKey: .gasTitle)
        lessonsCompleted = try c.decode(Int.self,          forKey: .lessonsCompleted)
        lessonIds        = (try? c.decode([String].self,   forKey: .lessonIds)) ?? []
        duration         = try c.decode(TimeInterval.self, forKey: .duration)
    }
}

// MARK: - Storage

public final class FlightLogbook: ObservableObject {
    public static let shared = FlightLogbook()

    @Published public private(set) var records: [FlightRecord] = []

    /// Union of all lesson IDs earned across every flight.
    public var unlockedLessonIds: Set<String> {
        Set(records.flatMap(\.lessonIds))
    }

    private let key = "atmos.logbook.v1"

    private init() { load() }

    public func save(_ record: FlightRecord) {
        guard !records.contains(where: { $0.id == record.id }) else { return }
        records.insert(record, at: 0)
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let saved = try? JSONDecoder().decode([FlightRecord].self, from: data) else { return }
        records = saved
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Logbook screen

struct LogbookView: View {
    @ObservedObject private var logbook = FlightLogbook.shared

    var body: some View {
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

            if logbook.records.isEmpty {
                emptyState
            } else {
                recordList
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "book.closed")
                .font(.system(size: 52))
                .foregroundColor(Color(Palette.chartRule))

            Text("Logbook Empty")
                .font(Font(Typography.display(18, weight: .semibold)))
                .foregroundColor(Color(Palette.inkDeep))

            Text("Complete your first mission —\nthe record will appear here automatically.")
                .font(Font(Typography.body(14)))
                .foregroundColor(Color(Palette.inkSoft))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(40)
    }

    // MARK: Record list

    private var recordList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                listHeader
                ForEach(logbook.records) { record in
                    LogbookRow(record: record)
                    Divider()
                        .background(Color(Palette.chartRule))
                        .padding(.leading, 20)
                }
            }
            .padding(.top, 50)
        }
    }

    private var listHeader: some View {
        HStack {
            Text("Flight Logbook")
                .font(Font(Typography.display(13)))
                .kerning(1.6)
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.inkSoft))
            Spacer()
            Text("\(logbook.records.count) entries")
                .font(Font(Typography.data(12)))
                .foregroundColor(Color(Palette.inkSoft))
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Logbook row

private struct LogbookRow: View {
    let record: FlightRecord

    private var dateString: String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: record.date)
    }

    private var durationString: String {
        let m = Int(record.duration.rounded()) / 60
        return m < 60 ? "\(m) min" : String(format: "%d h %02d min", m / 60, m % 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(record.missionName)
                        .font(Font(Typography.display(16, weight: .semibold)))
                        .foregroundColor(Color(Palette.inkDeep))
                    Text(dateString)
                        .font(Font(Typography.body(12)))
                        .foregroundColor(Color(Palette.inkSoft))
                }
                Spacer()
                if record.lessonsCompleted > 0 {
                    lessonBadge
                }
            }

            // Stats strip
            HStack(spacing: 0) {
                statCell("Ceiling",  String(format: "%.0f m",  record.peakAltitude))
                dividerLine
                statCell("Drift",    String(format: "%.0f km", record.horizontalDrift / 1000))
                dividerLine
                statCell("Samples",  "\(record.samplesCaptured)")
                dividerLine
                statCell("Duration", durationString)
            }
            .padding(10)
            .background(Color(Palette.chartRule).opacity(0.3))
            .cornerRadius(Metrics.panelRadius)

            // Equipment
            HStack(spacing: 6) {
                Image(systemName: "arrow.up.circle")
                    .font(.system(size: 11))
                    .foregroundColor(Color(Palette.inkSoft).opacity(0.6))
                Text(record.balloonModel)
                    .font(Font(Typography.body(12)))
                    .foregroundColor(Color(Palette.inkSoft))
                Text("·")
                    .foregroundColor(Color(Palette.chartRule))
                Text(record.gasTitle)
                    .font(Font(Typography.body(12)))
                    .foregroundColor(Color(Palette.inkSoft))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var lessonBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "lightbulb.fill").font(.system(size: 10))
            Text("\(record.lessonsCompleted)")
                .font(Font(Typography.display(12, weight: .semibold)))
        }
        .foregroundColor(Color(Palette.verdigris))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(Palette.verdigris).opacity(0.12))
        .cornerRadius(Metrics.panelRadius)
    }

    private func statCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Font(Typography.display(9)))
                .textCase(.uppercase)
                .foregroundColor(Color(Palette.inkSoft))
            Text(value)
                .font(Font(Typography.data(14, weight: .semibold)))
                .foregroundColor(Color(Palette.inkDeep))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color(Palette.chartRule))
            .frame(width: 1, height: 32)
            .padding(.horizontal, 8)
    }
}
