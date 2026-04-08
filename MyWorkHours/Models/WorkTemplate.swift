import Foundation

struct WorkTemplate: Identifiable, Codable {
    var id: UUID
    var name: String
    var fromTime: Date
    var toTime: Date
    var breakMinutes: Int
    var hourlyRate: Double
    var notes: String
    var isDefault: Bool

    var fromTimeString: String {
        DateFormatterHelper.time.string(from: fromTime)
    }

    var toTimeString: String {
        DateFormatterHelper.time.string(from: displayedToTime)
    }

    var hourlyRateString: String {
        String(format: "%.2f", hourlyRate)
    }

    var displayedToTime: Date {
        Calendar.current.date(byAdding: .minute, value: breakMinutes, to: toTime) ?? toTime
    }
}
