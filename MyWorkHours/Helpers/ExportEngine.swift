import Foundation
import SwiftUI
import PDFKit

class ExportEngine {
    private struct ReportRow {
        let day: String
        let timings: String
        let hours: String
        let payout: String
        let notes: String
    }

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

    static func clipboardText(entries: [WorkDay], settings: SettingsViewModel, includeMonthlyTotal: Bool) -> String {
        renderPlainText(entries: entries, settings: settings, includeMonthlyTotal: includeMonthlyTotal)
    }

    private static func generateTXT(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        let txtContent = renderPlainText(
            entries: entries,
            settings: settings,
            includeMonthlyTotal: profile.includeMonthlyTotal
        )
        return saveToTemp(fileName: "WorkReport.txt", content: txtContent.data(using: .utf8))
    }

    private static func generateCSV(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        var lines: [String] = []
        lines.append(profile.selectedColumns.map { $0.rawValue.capitalized }.joined(separator: ","))

        for entry in entries {
            var row: [String] = []
            for column in profile.selectedColumns {
                switch column {
                case .day:
                    row.append(DateFormatterHelper.dayFull.string(from: entry.date))
                case .timings:
                    row.append("\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.toTime))")
                case .hours:
                    row.append(entry.totalHoursString)
                case .payout:
                    row.append(String(format: "%.2f", entry.totalPayout))
                case .notes:
                    row.append("\"\(entry.notes)\"")
                }
            }
            lines.append(row.joined(separator: ","))
        }

        if profile.includeMonthlyTotal {
            let totals = monthlyTotals(entries: entries, settings: settings)
            lines.append("Monthly Total,,\(totals.hours),\(totals.payoutValue),")
        }

        let csvContent = lines.joined(separator: "\n")
        return saveToTemp(fileName: "WorkReport.csv", content: csvContent.data(using: .utf8))
    }

    private static func generatePDF(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        let rows = reportRows(entries: entries, settings: settings)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 595, height: 842))

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 24
            let lineHeight: CGFloat = 20
            let leftAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12)
            ]
            let leftBoldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12)
            ]
            let rightAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: rightAlignedParagraphStyle()
            ]
            let rightBoldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .paragraphStyle: rightAlignedParagraphStyle()
            ]

            drawPDFText("Day", atX: 20, y: yPosition, width: 110, attributes: leftBoldAttributes)
            drawPDFText("Timings", atX: 140, y: yPosition, width: 120, attributes: leftBoldAttributes)
            drawPDFText("Hours", atX: 270, y: yPosition, width: 60, attributes: rightBoldAttributes)
            drawPDFText("Payout", atX: 340, y: yPosition, width: 80, attributes: rightBoldAttributes)
            drawPDFText("Notes", atX: 430, y: yPosition, width: 145, attributes: leftBoldAttributes)
            yPosition += lineHeight

            for row in rows {
                drawPDFText(row.day, atX: 20, y: yPosition, width: 110, attributes: leftAttributes)
                drawPDFText(row.timings, atX: 140, y: yPosition, width: 120, attributes: leftAttributes)
                drawPDFText(row.hours, atX: 270, y: yPosition, width: 60, attributes: rightAttributes)
                drawPDFText(row.payout, atX: 340, y: yPosition, width: 80, attributes: rightAttributes)
                drawPDFText(row.notes, atX: 430, y: yPosition, width: 145, attributes: leftAttributes)
                yPosition += lineHeight
            }

            if profile.includeMonthlyTotal {
                let totals = monthlyTotals(entries: entries, settings: settings)
                yPosition += 4
                drawPDFText("Monthly Total", atX: 20, y: yPosition, width: 110, attributes: leftBoldAttributes)
                drawPDFText(totals.hours, atX: 270, y: yPosition, width: 60, attributes: rightBoldAttributes)
                drawPDFText(totals.payoutDisplay, atX: 340, y: yPosition, width: 80, attributes: rightBoldAttributes)
            }
        }

        return saveToTemp(fileName: "WorkReport.pdf", content: data)
    }

    private static func renderPlainText(entries: [WorkDay], settings: SettingsViewModel, includeMonthlyTotal: Bool) -> String {
        let rows = reportRows(entries: entries, settings: settings)
        let header = formattedRow(day: "Day", timings: "Timings", hours: "Hours", payout: "Payout", notes: "Notes")
        let divider = String(repeating: "-", count: 90)

        var lines = [header, divider]
        lines.append(contentsOf: rows.map {
            formattedRow(day: $0.day, timings: $0.timings, hours: $0.hours, payout: $0.payout, notes: $0.notes)
        })

        if includeMonthlyTotal {
            let totals = monthlyTotals(entries: entries, settings: settings)
            lines.append(divider)
            lines.append(
                formattedRow(
                    day: "Monthly Total",
                    timings: "",
                    hours: totals.hours,
                    payout: totals.payoutDisplay,
                    notes: ""
                )
            )
        }

        return lines.joined(separator: "\n")
    }

    private static func reportRows(entries: [WorkDay], settings: SettingsViewModel) -> [ReportRow] {
        entries.map { entry in
            ReportRow(
                day: DateFormatterHelper.dayFull.string(from: entry.date),
                timings: "\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.toTime))",
                hours: entry.totalHoursString,
                payout: "\(settings.currencyCode) \(String(format: "%.2f", entry.totalPayout))",
                notes: entry.notes
            )
        }
    }

    private static func monthlyTotals(entries: [WorkDay], settings: SettingsViewModel) -> (hours: String, payoutDisplay: String, payoutValue: String) {
        let totalMinutes = entries.reduce(0) { $0 + $1.totalMinutes }
        let totalHours = String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
        let totalPayout = entries.reduce(0) { $0 + $1.totalPayout }
        let payoutValue = String(format: "%.2f", totalPayout)
        return (totalHours, "\(settings.currencyCode) \(payoutValue)", payoutValue)
    }

    private static func formattedRow(day: String, timings: String, hours: String, payout: String, notes: String) -> String {
        [
            padded(day, width: 18, alignment: .left),
            padded(timings, width: 15, alignment: .left),
            padded(hours, width: 7, alignment: .right),
            padded(payout, width: 10, alignment: .right),
            notes
        ].joined(separator: "  ")
    }

    private static func padded(_ value: String, width: Int, alignment: NSTextAlignment) -> String {
        if value.count >= width {
            return value
        }

        let padding = String(repeating: " ", count: width - value.count)
        switch alignment {
        case .right:
            return padding + value
        default:
            return value + padding
        }
    }

    private static func drawPDFText(_ text: String, atX x: CGFloat, y: CGFloat, width: CGFloat, attributes: [NSAttributedString.Key: Any]) {
        let rect = CGRect(x: x, y: y, width: width, height: 18)
        text.draw(in: rect, withAttributes: attributes)
    }

    private static func rightAlignedParagraphStyle() -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = .right
        return style
    }

    private static func saveToTemp(fileName: String, content: Data?) -> URL? {
        guard let data = content else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        return url
    }
}
