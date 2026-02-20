import WidgetKit
import SwiftUI

private let appGroupId = "group.com.mounim.assitme"

// MARK: - Timeline Entry

struct DailyFitnessEntry: TimelineEntry {
    let date: Date
    let totalCalories: Int
    let gymStreak: Int
    let hasLoggedToday: Bool
}

// MARK: - Timeline Provider

struct DailyFitnessProvider: TimelineProvider {
    func placeholder(in context: Context) -> DailyFitnessEntry {
        DailyFitnessEntry(
            date: Date(),
            totalCalories: 1850,
            gymStreak: 5,
            hasLoggedToday: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyFitnessEntry) -> Void) {
        completion(createEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyFitnessEntry>) -> Void) {
        let entry = createEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> DailyFitnessEntry {
        let defaults = UserDefaults(suiteName: appGroupId)
        let totalCalories = defaults?.integer(forKey: "total_calories") ?? 0
        let gymStreak = defaults?.integer(forKey: "gym_streak") ?? 0
        let hasLoggedToday = defaults?.bool(forKey: "has_logged_today") ?? false

        return DailyFitnessEntry(
            date: Date(),
            totalCalories: totalCalories,
            gymStreak: gymStreak,
            hasLoggedToday: hasLoggedToday
        )
    }
}

// MARK: - Widget View

struct DailyFitnessWidgetView: View {
    var entry: DailyFitnessEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            Text("Daily Fitness")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
                .padding(.bottom, 12)

            // Calories row
            HStack {
                Text("Calories:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.totalCalories) kcal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 8)

            // Streak row
            HStack {
                Text("Streak:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(entry.gymStreak) days")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 8)

            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.25))
                .frame(height: 1)
                .padding(.vertical, 4)

            // Reminder
            if !entry.hasLoggedToday {
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Text("Log gym session!")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color(red: 0.961, green: 0.486, blue: 0.0)) // #F57C00
                    Spacer()
                }
            } else {
                Spacer(minLength: 0)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

// MARK: - Widget Definition

struct DailyFitnessWidget: Widget {
    let kind: String = "DailyFitnessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DailyFitnessProvider()) { entry in
            DailyFitnessWidgetView(entry: entry)
        }
        .configurationDisplayName("Daily Fitness")
        .description("View today's calories and gym streak at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
