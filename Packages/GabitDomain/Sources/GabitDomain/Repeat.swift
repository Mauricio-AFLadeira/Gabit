import Foundation

/// Copying yesterday forward — the operation the two-tap claim in plan §8 rests on.
public enum RepeatMeal {

    /// Copies entries onto `day`, keeping each one's slot and time of day.
    ///
    /// Every copy gets a fresh identity: a repeated meal is a new entry that
    /// happens to match an old one, not the same entry appearing twice. Sharing
    /// ids would make deleting today's breakfast delete yesterday's too.
    public static func copy(
        _ entries: [FoodEntry],
        onto day: Date,
        in calendar: Calendar
    ) -> [FoodEntry] {
        let start = DayBoundary.startOfDay(for: day, in: calendar)
        return entries.map { entry in
            let time = calendar.dateComponents([.hour, .minute, .second], from: entry.loggedAt)
            let loggedAt =
                calendar.date(
                    bySettingHour: time.hour ?? 0,
                    minute: time.minute ?? 0,
                    second: time.second ?? 0,
                    of: start
                ) ?? start
            return FoodEntry(
                name: entry.name,
                kcal: entry.kcal,
                macros: entry.macros,
                slot: entry.slot,
                loggedAt: loggedAt
            )
        }
    }

    /// The distinct foods the user logged most recently, newest first.
    ///
    /// Deduplicated by name so the quick-add strip offers four different things
    /// rather than four copies of this morning's coffee.
    public static func recent(from logs: [DayLog], limit: Int = 4) -> [FoodEntry] {
        let entries =
            logs
            .flatMap(\.food)
            .sorted { $0.loggedAt > $1.loggedAt }

        var seen = Set<String>()
        var result: [FoodEntry] = []
        for entry in entries {
            let key = entry.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(entry)
            if result.count == limit { break }
        }
        return result
    }
}
