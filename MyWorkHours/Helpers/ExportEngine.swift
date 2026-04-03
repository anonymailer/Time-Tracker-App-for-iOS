import Foundation
import SwiftUI
import PDFKit
import UIKit

class ExportEngine {
    private static let textColumnSeparator = "    "
    private static let visualColumnGutter: CGFloat = 14

    private struct ExportColumnLayout {
        let column: ExportColumn
        let title: String
        let textAlignment: NSTextAlignment
        let width: CGFloat
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

    static func copyReportToPasteboard(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) {
        if let image = renderClipboardImage(entries: entries, profile: profile, settings: settings) {
            UIPasteboard.general.image = image
        }
    }

    private static func generateTXT(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        let txtContent = renderPlainText(entries: entries, profile: profile, settings: settings)
        return saveToTemp(fileName: "WorkReport.txt", content: txtContent.data(using: .utf8))
    }

    private static func generateCSV(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        var lines: [String] = []
        lines.append(profile.selectedColumns.map { columnTitle(for: $0) }.joined(separator: ","))

        for entry in entries {
            let row = profile.selectedColumns.map { csvValue(for: $0, entry: entry, settings: settings) }
            lines.append(row.joined(separator: ","))
        }

        if profile.includeMonthlyTotal {
            let totals = monthlyTotals(entries: entries, settings: settings)
            let totalRow = profile.selectedColumns.map { column in
                switch column {
                case .day:
                    return "Monthly Total"
                case .timings:
                    return ""
                case .hours:
                    return totals.hours
                case .payout:
                    return totals.payoutValue
                case .notes:
                    return ""
                }
            }
            lines.append(totalRow.joined(separator: ","))
        }

        let csvContent = lines.joined(separator: "\n")
        return saveToTemp(fileName: "WorkReport.csv", content: csvContent.data(using: .utf8))
    }

    private static func generatePDF(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> URL? {
        let layouts = columnLayouts(for: entries, profile: profile, settings: settings, baseFont: UIFont.systemFont(ofSize: 12), boldFont: UIFont.boldSystemFont(ofSize: 12))
        let totalWidth = layouts.reduce(CGFloat(40)) { $0 + $1.width } + (CGFloat(max(layouts.count - 1, 0)) * visualColumnGutter)
        let pageWidth = max(595, totalWidth + 20)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: 842))

        let data = renderer.pdfData { context in
            context.beginPage()

            var yPosition: CGFloat = 24
            let lineHeight: CGFloat = 20
            let leftAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 12)]
            let leftBoldAttributes: [NSAttributedString.Key: Any] = [.font: UIFont.boldSystemFont(ofSize: 12)]
            let rightAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle(alignment: .right)
            ]
            let rightBoldAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 12),
                .paragraphStyle: paragraphStyle(alignment: .right)
            ]

            var xPosition: CGFloat = 20
            for layout in layouts {
                drawPDFText(
                    layout.title,
                    atX: xPosition,
                    y: yPosition,
                    width: layout.width,
                    attributes: layout.textAlignment == .right ? rightBoldAttributes : leftBoldAttributes
                )
                xPosition += layout.width + visualColumnGutter
            }
            yPosition += lineHeight

            for entry in entries {
                xPosition = 20
                for layout in layouts {
                    drawPDFText(
                        displayValue(for: layout.column, entry: entry, settings: settings),
                        atX: xPosition,
                        y: yPosition,
                        width: layout.width,
                        attributes: layout.textAlignment == .right ? rightAttributes : leftAttributes
                    )
                    xPosition += layout.width + visualColumnGutter
                }
                yPosition += lineHeight
            }

            if profile.includeMonthlyTotal {
                let totals = monthlyTotals(entries: entries, settings: settings)
                xPosition = 20
                yPosition += 4
                for layout in layouts {
                    let totalValue = totalValue(for: layout.column, totals: totals)
                    drawPDFText(
                        totalValue,
                        atX: xPosition,
                        y: yPosition,
                        width: layout.width,
                        attributes: layout.textAlignment == .right ? rightBoldAttributes : leftBoldAttributes
                    )
                    xPosition += layout.width + visualColumnGutter
                }
            }
        }

        return saveToTemp(fileName: "WorkReport.pdf", content: data)
    }

    private static func renderPlainText(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> String {
        let widths = textColumnWidths(for: entries, profile: profile, settings: settings)
        let header = profile.selectedColumns
            .map { padded(columnTitle(for: $0), width: widths[$0] ?? columnTitle(for: $0).count, alignment: textAlignment(for: $0)) }
            .joined(separator: textColumnSeparator)
        let divider = String(repeating: "-", count: max(20, header.count))

        var lines = [header, divider]
        lines.append(contentsOf: entries.map { entry in
            profile.selectedColumns
                .map { padded(displayValue(for: $0, entry: entry, settings: settings), width: widths[$0] ?? 0, alignment: textAlignment(for: $0)) }
                .joined(separator: textColumnSeparator)
        })

        if profile.includeMonthlyTotal {
            let totals = monthlyTotals(entries: entries, settings: settings)
            let totalLine = profile.selectedColumns
                .map { padded(totalValue(for: $0, totals: totals), width: widths[$0] ?? 0, alignment: textAlignment(for: $0)) }
                .joined(separator: textColumnSeparator)
            lines.append(divider)
            lines.append(totalLine)
        }

        return lines.joined(separator: "\n")
    }

    private static func renderClipboardImage(entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> UIImage? {
        let font = UIFont.systemFont(ofSize: 14)
        let boldFont = UIFont.boldSystemFont(ofSize: 14)
        let layouts = columnLayouts(for: entries, profile: profile, settings: settings, baseFont: font, boldFont: boldFont)
        let rowHeight: CGFloat = 28
        let horizontalPadding: CGFloat = 16
        let verticalPadding: CGFloat = 20
        let dividerHeight: CGFloat = 1

        let totalWidth = layouts.reduce(horizontalPadding * 2) { $0 + $1.width } + (CGFloat(max(layouts.count - 1, 0)) * visualColumnGutter)
        let totalRows = CGFloat(entries.count + 1 + (profile.includeMonthlyTotal ? 1 : 0))
        let totalDividers = CGFloat(entries.count + 1)
        let totalHeight = verticalPadding * 2 + totalRows * rowHeight + totalDividers * dividerHeight

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: totalWidth, height: totalHeight))
        return renderer.image { context in
            let cgContext = context.cgContext
            UIColor.systemBackground.setFill()
            cgContext.fill(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

            var y = verticalPadding
            var x = horizontalPadding
            for layout in layouts {
                drawImageText(layout.title, x: x, y: y, width: layout.width, font: boldFont, alignment: layout.textAlignment)
                x += layout.width + visualColumnGutter
            }

            y += rowHeight
            drawDivider(in: cgContext, y: y, width: totalWidth, horizontalPadding: horizontalPadding)
            y += dividerHeight

            for entry in entries {
                x = horizontalPadding
                for layout in layouts {
                    drawImageText(displayValue(for: layout.column, entry: entry, settings: settings), x: x, y: y, width: layout.width, font: font, alignment: layout.textAlignment)
                    x += layout.width + visualColumnGutter
                }
                y += rowHeight
                drawDivider(in: cgContext, y: y, width: totalWidth, horizontalPadding: horizontalPadding)
                y += dividerHeight
            }

            if profile.includeMonthlyTotal {
                let totals = monthlyTotals(entries: entries, settings: settings)
                x = horizontalPadding
                for layout in layouts {
                    drawImageText(totalValue(for: layout.column, totals: totals), x: x, y: y, width: layout.width, font: boldFont, alignment: layout.textAlignment)
                    x += layout.width + visualColumnGutter
                }
            }
        }
    }

    private static func textColumnWidths(for entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel) -> [ExportColumn: Int] {
        let totals = monthlyTotals(entries: entries, settings: settings)
        return Dictionary(uniqueKeysWithValues: profile.selectedColumns.map { column in
            let headerWidth = columnTitle(for: column).count
            let rowWidth = entries.map { displayValue(for: column, entry: $0, settings: settings).count }.max() ?? 0
            let totalWidth = totalValue(for: column, totals: totals).count
            return (column, max(headerWidth, rowWidth, totalWidth))
        })
    }

    private static func columnLayouts(for entries: [WorkDay], profile: ExportProfile, settings: SettingsViewModel, baseFont: UIFont, boldFont: UIFont) -> [ExportColumnLayout] {
        let totals = monthlyTotals(entries: entries, settings: settings)
        return profile.selectedColumns.map { column in
            let title = columnTitle(for: column)
            let alignment = textAlignment(for: column)
            let width = max(
                textWidth(title, font: boldFont),
                entries.map { textWidth(displayValue(for: column, entry: $0, settings: settings), font: baseFont) }.max() ?? 0,
                textWidth(totalValue(for: column, totals: totals), font: boldFont),
                minimumWidth(for: column)
            ) + 24
            return ExportColumnLayout(column: column, title: title, textAlignment: alignment, width: width)
        }
    }

    private static func columnTitle(for column: ExportColumn) -> String {
        switch column {
        case .day: return "Day"
        case .timings: return "Timings"
        case .hours: return "Work Hours"
        case .payout: return "Payout"
        case .notes: return "Notes"
        }
    }

    private static func displayValue(for column: ExportColumn, entry: WorkDay, settings: SettingsViewModel) -> String {
        switch column {
        case .day:
            return DateFormatterHelper.dayFull.string(from: entry.date)
        case .timings:
            return "\(DateFormatterHelper.time.string(from: entry.fromTime))-\(DateFormatterHelper.time.string(from: entry.displayedToTime))"
        case .hours:
            return entry.totalHoursString
        case .payout:
            return "\(settings.currencyCode) \(String(format: "%.2f", entry.totalPayout))"
        case .notes:
            return entry.notes
        }
    }

    private static func totalValue(for column: ExportColumn, totals: (hours: String, payoutDisplay: String, payoutValue: String)) -> String {
        switch column {
        case .day:
            return "Monthly Total"
        case .timings:
            return ""
        case .hours:
            return totals.hours
        case .payout:
            return totals.payoutDisplay
        case .notes:
            return ""
        }
    }

    private static func csvValue(for column: ExportColumn, entry: WorkDay, settings: SettingsViewModel) -> String {
        switch column {
        case .notes:
            return "\"\(entry.notes)\""
        case .payout:
            return String(format: "%.2f", entry.totalPayout)
        default:
            return displayValue(for: column, entry: entry, settings: settings)
        }
    }

    private static func monthlyTotals(entries: [WorkDay], settings: SettingsViewModel) -> (hours: String, payoutDisplay: String, payoutValue: String) {
        let totalMinutes = entries.reduce(0) { $0 + $1.totalMinutes }
        let totalHours = String(format: "%02d:%02d", totalMinutes / 60, totalMinutes % 60)
        let totalPayout = entries.reduce(0) { $0 + $1.totalPayout }
        let payoutValue = String(format: "%.2f", totalPayout)
        return (totalHours, "\(settings.currencyCode) \(payoutValue)", payoutValue)
    }

    private static func minimumWidth(for column: ExportColumn) -> CGFloat {
        switch column {
        case .day: return 90
        case .timings: return 100
        case .hours: return 60
        case .payout: return 80
        case .notes: return 140
        }
    }

    private static func textAlignment(for column: ExportColumn) -> NSTextAlignment {
        switch column {
        case .hours, .payout:
            return .right
        default:
            return .left
        }
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

    private static func drawImageText(_ text: String, x: CGFloat, y: CGFloat, width: CGFloat, font: UIFont, alignment: NSTextAlignment) {
        let rect = CGRect(x: x, y: y + 5, width: width, height: 18)
        text.draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.label,
                .paragraphStyle: paragraphStyle(alignment: alignment)
            ]
        )
    }

    private static func drawDivider(in context: CGContext, y: CGFloat, width: CGFloat, horizontalPadding: CGFloat) {
        context.setFillColor(UIColor.separator.cgColor)
        context.fill(CGRect(x: horizontalPadding, y: y, width: width - (horizontalPadding * 2), height: 1))
    }

    private static func textWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    private static func paragraphStyle(alignment: NSTextAlignment) -> NSMutableParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = alignment
        return style
    }

    private static func saveToTemp(fileName: String, content: Data?) -> URL? {
        guard let data = content else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
        return url
    }
}
