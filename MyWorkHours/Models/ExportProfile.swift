import Foundation

struct ExportProfile: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var selectedColumns: [ExportColumn] = [.day, .timings, .hours, .payout, .notes]
    var includeMonthlyTotal: Bool = true
    var dateRange: ExportDateRange = .currentMonth
    var formats: [ExportFormat] = [.pdf]
    var timeFormatOverride: TimeFormat? = nil
    var currencyOverride: String? = nil
}

enum ExportColumn: String, Codable, CaseIterable, Hashable {
    case day, timings, hours, payout, notes
}

enum ExportDateRange: Codable, Hashable {
    case currentMonth
    case custom(start: Date, end: Date)
}

enum ExportFormat: String, Codable, CaseIterable, Hashable {
    case pdf, txt, csv
}

enum TimeFormat: String, Codable, Hashable {
    case hour12, hour24
}
