import Foundation
import SwiftUI
import PDFKit

class ExportEngine {
    
    static func export(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel, completion: @escaping (URL?) -> Void) {
        for format in profile.formats {
            switch format {
            case .txt:
                if let txtURL = generateTXT(entries: entries, profile: profile, settings: settings) {
                    completion(txtURL)
                }
            case .csv:
                if let csvURL = generateCSV(entries: entries, profile: profile, settings: settings) {
                    completion(csvURL)
                }
            case .pdf:
                if let pdfURL = generatePDF(entries: entries, profile: profile, settings: settings) {
                    completion(pdfURL)
                }
            }
        }
    }

    private static func generateTXT(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        var lines: [String] = []
        lines.append(profile.selectedColumns.map { $0.rawValue.capitalized }.joined(separator: " | "))
        lines.append(String(repeating: "-", count: 50))
        for entry in entries {
            var row: [String] = []
            for column in profile.selectedColumns {
                switch column {
                case .day: row.append(DateFormatterHelper.dayFull.string(from: entry.date))
                case .timings: row.append("\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.toTime))")
                case .hours: row.append(entry.totalHoursString)
                case .payout: row.append("\(settings.currencyCode) \(String(format: "%.2f", entry.totalPayout))")
                case .notes: row.append(entry.notes)
                }
            }
            lines.append(row.joined(separator: " | "))
        }
        if profile.includeMonthlyTotal {
            let totalMinutes = entries.reduce(0) { $0 + $1.totalMinutes }
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            let totalPayout = entries.reduce(0) { $0 + $1.totalPayout }
            lines.append(String(repeating: "-", count: 50))
            lines.append("Monthly Total | | \(String(format: "%02d:%02d", hours, mins)) | \(settings.currencyCode) \(String(format: "%.2f", totalPayout)) |")
        }
        let txtContent = lines.joined(separator: "\n")
        return saveToTemp(fileName: "WorkReport.txt", content: txtContent.data(using: .utf8))
    }

    private static func generateCSV(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        var lines: [String] = []
        lines.append(profile.selectedColumns.map { $0.rawValue.capitalized }.joined(separator: ","))
        for entry in entries {
            var row: [String] = []
            for column in profile.selectedColumns {
                switch column {
                case .day: row.append(DateFormatterHelper.dayFull.string(from: entry.date))
                case .timings: row.append("\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.toTime))")
                case .hours: row.append(entry.totalHoursString)
                case .payout: row.append(String(format: "%.2f", entry.totalPayout))
                case .notes: row.append("\"\(entry.notes)\"")
                }
            }
            lines.append(row.joined(separator: ","))
        }
        if profile.includeMonthlyTotal {
            let totalMinutes = entries.reduce(0) { $0 + $1.totalMinutes }
            let hours = totalMinutes / 60
            let mins = totalMinutes % 60
            let totalPayout = entries.reduce(0) { $0 + $1.totalPayout }
            lines.append("Monthly Total,,\(String(format: "%02d:%02d", hours, mins)),\(String(format: "%.2f", totalPayout)),")
        }
        let csvContent = lines.joined(separator: "\n")
        return saveToTemp(fileName: "WorkReport.csv", content: csvContent.data(using: .utf8))
    }

    private static func generatePDF(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))
        let data = renderer.pdfData { ctx in
            ctx.beginPage()
            var yPosition: CGFloat = 20
            let lineHeight: CGFloat = 20
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .left
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle]
            // Header
            var xPos: CGFloat = 20
            for column in profile.selectedColumns {
                let text = column.rawValue.capitalized
                text.draw(at: CGPoint(x: xPos, y: yPosition), withAttributes: attributes)
                xPos += 100
            }
            yPosition += lineHeight
            // Rows
            for entry in entries {
                xPos = 20
                for column in profile.selectedColumns {
                    let val: String
                    switch column {
                    case .day: val = DateFormatterHelper.dayFull.string(from: entry.date)
                    case .timings: val = "\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.toTime))"
                    case .hours: val = entry.totalHoursString
                    case .payout: val = String(format: "%.2f", entry.totalPayout)
                    case .notes: val = entry.notes
                    }
                    val.draw(at: CGPoint(x: xPos, y: yPosition), withAttributes: attributes)
                    xPos += 100
                }
                yPosition += lineHeight
            }
        }
        return saveToTemp(fileName: "WorkReport.pdf", content: data)
    }

    private static func saveToTemp(fileName: String, content: Data?) -> URL? {
        guard let data = content else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        return url
    }
}