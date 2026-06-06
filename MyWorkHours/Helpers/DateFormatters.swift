import Foundation

struct DateFormatterHelper {
    static var currentTimeFormat: TimeFormat = .hour24

    static let dayFull: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        return formatter
    }()

    // Cache formatters to avoid expensive re-creation
    private static var formatterCache: [TimeFormat: DateFormatter] = [:]

    static var time: DateFormatter {
        return getFormatter(for: currentTimeFormat)
    }

    static func getFormatter(for format: TimeFormat) -> DateFormatter {
        if let cached = formatterCache[format] {
            return cached
        }
        
        let formatter = DateFormatter()
        switch format {
        case .hour12:
            formatter.dateFormat = "h:mm a"
        case .hour24:
            formatter.dateFormat = "HH:mm"
        }
        formatterCache[format] = formatter
        return formatter
    }

    // Centralized method to use across the app
    static func string(from date: Date, format: TimeFormat? = nil) -> String {
        let targetFormat = format ?? currentTimeFormat
        return getFormatter(for: targetFormat).string(from: date)
    }
}

struct WorkDurationFormatter {
    static func displayString(for minutes: Int) -> String {
        let safeMinutes = max(minutes, 0)
        return String(format: "%02d:%02d", safeMinutes / 60, safeMinutes % 60)
    }

    static func signedDisplayString(for minutes: Int) -> String {
        let prefix = minutes >= 0 ? "+" : "-"
        return prefix + displayString(for: abs(minutes))
    }
}

struct BreakDurationFormatter {
    static func displayString(for minutes: Int) -> String {
        WorkDurationFormatter.displayString(for: minutes)
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

struct HourlyRateParser {
    static func value(from input: String) -> Double {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return 0 }

        let normalized = trimmed.replacingOccurrences(of: ",", with: ".")
        if let directValue = Double(normalized) {
            return directValue
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current

        if let number = formatter.number(from: trimmed) {
            return number.doubleValue
        }

        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.number(from: normalized)?.doubleValue ?? 0
    }
}
