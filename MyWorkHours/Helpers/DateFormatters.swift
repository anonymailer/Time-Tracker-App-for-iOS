import Foundation

struct DateFormatterHelper {
    static let dayFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        return formatter
    }()

    static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

struct BreakDurationFormatter {
    static func displayString(for minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    static func components(for minutes: Int) -> (hours: Int, minutes: Int) {
        (
            minutes / 60,
            minutes % 60
        )
    }

    static func minutes(from input: String) -> Int {
        let parts = input.split(separator: ":")
        guard parts.count == 2,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]),
              parts[1].count == 2,
              minutes < 60 else {
            return 0
        }
        return (hours * 60) + minutes
    }

    static func minutes(hours: String, minutes: String) -> Int {
        let hourValue = Int(hours) ?? 0
        let minuteValue = min(Int(minutes) ?? 0, 59)
        return (hourValue * 60) + minuteValue
    }
}
