import WidgetKit
import SwiftUI
import AppIntents

private let appGroupId = "group.com.mounim.assistme"

// MARK: - Data Model

struct EventItem: Identifiable {
    let id = UUID()
    let title: String
    let time: String
    let color: Color
}

// MARK: - Timeline Entry

struct TodayEventsEntry: TimelineEntry {
    let date: Date
    let dayOffset: Int
    let dayName: String
    let dateString: String
    let events: [EventItem]
}

// MARK: - App Intents for Interactive Navigation

struct PreviousDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Day"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroupId)
        let current = defaults?.integer(forKey: "day_offset") ?? 0
        let newOffset = max(-7, current - 1)
        defaults?.set(newOffset, forKey: "day_offset")
        return .result()
    }
}

struct NextDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Day"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroupId)
        let current = defaults?.integer(forKey: "day_offset") ?? 0
        let newOffset = min(7, current + 1)
        defaults?.set(newOffset, forKey: "day_offset")
        return .result()
    }
}

struct GoToTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Go to Today"

    func perform() async throws -> some IntentResult {
        let defaults = UserDefaults(suiteName: appGroupId)
        defaults?.set(0, forKey: "day_offset")
        return .result()
    }
}

// MARK: - Color Helper

private func colorFromInt(_ value: Int) -> Color {
    let red = Double((value >> 16) & 0xFF) / 255.0
    let green = Double((value >> 8) & 0xFF) / 255.0
    let blue = Double(value & 0xFF) / 255.0
    let alpha = Double((value >> 24) & 0xFF) / 255.0
    return Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
}

// MARK: - Timeline Provider

struct TodayEventsProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEventsEntry {
        TodayEventsEntry(
            date: Date(),
            dayOffset: 0,
            dayName: "TODAY",
            dateString: formatDate(Date()),
            events: [
                EventItem(title: "Sample Event", time: "9:00 AM", color: .blue),
                EventItem(title: "Another Event", time: "2:00 PM", color: .green),
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEventsEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEventsEntry>) -> Void) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> TodayEventsEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let dayOffset = defaults?.integer(forKey: "day_offset") ?? 0

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: today)!

        let dayName: String
        switch dayOffset {
        case 0: dayName = "TODAY"
        case 1: dayName = "TOMORROW"
        case -1: dayName = "YESTERDAY"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            dayName = formatter.string(from: targetDate).uppercased()
        }

        let keyFormatter = DateFormatter()
        keyFormatter.dateFormat = "yyyy-MM-dd"
        let dateKey = keyFormatter.string(from: targetDate)

        var eventsJson = defaults?.string(forKey: "events_\(dateKey)")
        if (eventsJson == nil || eventsJson?.isEmpty == true) && dayOffset == 0 {
            eventsJson = defaults?.string(forKey: "today_events")
        }

        var events: [EventItem] = []
        if let json = eventsJson, let data = json.data(using: .utf8) {
            if let array = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                events = array.map { dict in
                    let title = dict["title"] as? String ?? "Untitled"
                    let time = dict["time"] as? String ?? ""
                    let colorValue = dict["color"] as? Int ?? 0xFF2196F3
                    return EventItem(title: title, time: time, color: colorFromInt(colorValue))
                }
            }
        }

        return TodayEventsEntry(
            date: Date(),
            dayOffset: dayOffset,
            dayName: dayName,
            dateString: formatDate(targetDate),
            events: events
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Event Row View

struct EventRowView: View {
    let event: EventItem

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(event.color)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text(event.time)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Widget View

struct TodayEventsWidgetView: View {
    var entry: TodayEventsEntry
    @Environment(\.widgetFamily) var family

    var maxEvents: Int {
        switch family {
        case .systemLarge: return 7
        default: return 3
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with navigation
            HStack {
                Button(intent: PreviousDayIntent()) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)

                Spacer()

                VStack(spacing: 2) {
                    Text(entry.dayName)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.098, green: 0.463, blue: 0.824)) // #1976D2
                    Text(entry.dateString)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                Button(intent: NextDayIntent()) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
                .padding(.horizontal, 4)

            // Events list or empty state
            if entry.events.isEmpty {
                Spacer()
                Text("No events today")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
            } else {
                VStack(spacing: 4) {
                    ForEach(Array(entry.events.prefix(maxEvents))) { event in
                        EventRowView(event: event)
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 4)

                Spacer(minLength: 0)
            }

            // Footer - Go to Today button
            if entry.dayOffset != 0 {
                Button(intent: GoToTodayIntent()) {
                    Text("GO TO TODAY")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color(red: 0.098, green: 0.463, blue: 0.824))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 8)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

struct TodayEventsWidget: Widget {
    let kind: String = "TodayEventsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayEventsProvider()) { entry in
            TodayEventsWidgetView(entry: entry)
        }
        .configurationDisplayName("Today's Events")
        .description("Shows today's calendar events with day navigation")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
