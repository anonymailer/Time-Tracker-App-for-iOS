import Foundation

struct WorkTemplate: Identifiable {
    var id: UUID
    var name: String
    var fromTime: Date
    var toTime: Date
    var hourlyRate: Double
    var notes: String
    var isDefault: Bool

    var fromTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: fromTime)
    }

    var toTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: toTime)
    }

    var hourlyRateString: String {
        String(format: "%.2f", hourlyRate)
    }
}