import Foundation

struct WorkDay: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var fromTime: Date
    var toTime: Date
    var breakMinutes: Int = 0
    var hourlyRate: Double
    var notes: String
    var templateID: UUID? = nil

    var spanMinutes: Int {
        let diff = Calendar.current.dateComponents([.minute], from: fromTime, to: toTime)
        return diff.minute ?? 0
    }

    var totalMinutes: Int {
        max(spanMinutes - breakMinutes, 0)
    }

    var hasWorkingTime: Bool {
        totalMinutes > 0
    }

    var displayedToTime: Date {
        toTime
    }

    var totalPayout: Double {
        Double(totalMinutes)/60 * hourlyRate
    }

    var fromTimeString: String {
        DateFormatterHelper.string(from: fromTime)
    }

    var toTimeString: String {
        DateFormatterHelper.string(from: displayedToTime)
    }

    var hourlyRateString: String { String(format: "%.2f", hourlyRate) }
    var totalHoursString: String {
        WorkDurationFormatter.displayString(for: totalMinutes)
    }
}
