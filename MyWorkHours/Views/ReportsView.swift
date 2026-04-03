import SwiftUI
import UIKit

struct ReportsView: View {
    private struct ReportRow: Identifiable {
        let id = UUID()
        let day: String
        let timings: String
        let workHours: String
        let payout: String
        let notes: String
    }

    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @StateObject private var exportVM = ExportProfilesViewModel()

    @State private var currentMonth: Date = Date()
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack {
                // Month navigation
                HStack {
                    Button(action: { previousMonth() }) { Image(systemName: "chevron.left") }
                    Spacer()
                    Text(monthYearString).font(.headline)
                    Spacer()
                    Button(action: { nextMonth() }) { Image(systemName: "chevron.right") }
                }
                .padding()

                ScrollView([.horizontal, .vertical]) {
                    VStack(spacing: 0) {
                        HStack {
                            Text("Day").bold().frame(width: dayColumnWidth, alignment: .leading)
                            Text("Timings").bold().frame(width: timingsColumnWidth, alignment: .leading)
                            Text("Work Hours").bold().frame(width: hoursColumnWidth, alignment: .trailing)
                            Text("Payout").bold().frame(width: payoutColumnWidth, alignment: .trailing)
                            Spacer().frame(width: 12)
                            Text("Notes").bold().frame(width: notesColumnWidth, alignment: .leading)
                        }
                        .padding(.horizontal)
                        Divider()

                        ForEach(reportRows) { row in
                            HStack {
                                Text(row.day).frame(width: dayColumnWidth, alignment: .leading)
                                Text(row.timings).frame(width: timingsColumnWidth, alignment: .leading)
                                Text(row.workHours).frame(width: hoursColumnWidth, alignment: .trailing)
                                Text(row.payout).frame(width: payoutColumnWidth, alignment: .trailing)
                                Spacer().frame(width: 12)
                                Text(row.notes).frame(width: notesColumnWidth, alignment: .leading)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            Divider()
                        }

                        HStack {
                            Text("Monthly Total").bold().frame(width: dayColumnWidth, alignment: .leading)
                            Text("").frame(width: timingsColumnWidth, alignment: .leading)
                            Text(totalHoursInMonth()).bold().frame(width: hoursColumnWidth, alignment: .trailing)
                            Text(totalPayoutInMonth()).bold().frame(width: payoutColumnWidth, alignment: .trailing)
                            Spacer().frame(width: 12)
                            Text("").frame(width: notesColumnWidth, alignment: .leading)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Reports")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportProfilesView(
                    onExportProfile: { profile in
                        exportReport(using: profile)
                    },
                    onCopyProfile: { profile in
                        copyReport(using: profile)
                    }
                )
                    .environmentObject(calendarVM)
                    .environmentObject(settings)
                    .environmentObject(exportVM)
            }
            .sheet(isPresented: $showShareSheet, onDismiss: {
                exportURL = nil
            }) {
                if let exportURL {
                    ShareSheet(activityItems: [exportURL])
                }
            }
        }
    }

    // MARK: Helpers
    var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }
        return (0..<calendar.range(of: .day, in: .month, for: currentMonth)!.count).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monthInterval.start)
        }
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    private var reportRows: [ReportRow] {
        daysInMonth.map { date in
            let entry = calendarVM.entry(for: date)
            return ReportRow(
                day: dayString(date),
                timings: entry.map { "\(timeString($0.fromTime))-\(timeString($0.displayedToTime))" } ?? "--",
                workHours: entry.map(totalHoursString) ?? "--",
                payout: entry.map(payoutString) ?? "--",
                notes: entry?.notes ?? ""
            )
        }
    }

    private var dayColumnWidth: CGFloat {
        columnWidth(header: "Day", values: reportRows.map(\.day) + ["Monthly Total"])
    }

    private var timingsColumnWidth: CGFloat {
        columnWidth(header: "Timings", values: reportRows.map(\.timings))
    }

    private var hoursColumnWidth: CGFloat {
        columnWidth(header: "Work Hours", values: reportRows.map(\.workHours) + [totalHoursInMonth()], minimum: 90, alignment: .right)
    }

    private var payoutColumnWidth: CGFloat {
        columnWidth(header: "Payout", values: reportRows.map(\.payout) + [totalPayoutInMonth()], minimum: 80, alignment: .right)
    }

    private var notesColumnWidth: CGFloat {
        columnWidth(header: "Notes", values: reportRows.map(\.notes), minimum: 140)
    }

    func previousMonth() { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
    func nextMonth() { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }

    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        return formatter.string(from: date)
    }

    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func totalHoursString(_ entry: WorkDay) -> String { entry.totalHoursString }

    func payoutString(_ entry: WorkDay) -> String { "\(settings.currencyCode) \(String(format: "%.2f", entry.totalPayout))" }

    func totalHoursInMonth() -> String {
        let totalMinutes = entries(for: .currentMonth).reduce(0) { $0 + $1.totalMinutes }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    func totalPayoutInMonth() -> String {
        let total = entries(for: .currentMonth).reduce(0) { $0 + $1.totalPayout }
        return "\(settings.currencyCode) \(String(format: "%.2f", total))"
    }

    func columnWidth(header: String, values: [String], minimum: CGFloat = 0, alignment: NSTextAlignment = .left) -> CGFloat {
        let font = alignment == .right ? UIFont.systemFont(ofSize: UIFont.labelFontSize) : UIFont.systemFont(ofSize: UIFont.labelFontSize)
        let headerFont = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        let contentWidth = values.reduce(CGFloat(0)) { currentMax, value in
            max(currentMax, textWidth(value, font: font))
        }
        return max(minimum, textWidth(header, font: headerFont), contentWidth) + 16
    }

    func textWidth(_ text: String, font: UIFont) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return ceil((text as NSString).size(withAttributes: attributes).width)
    }

    func exportReport(using profile: ExportProfile) {
        let entries = entries(for: profile.dateRange)
        ExportEngine.export(entries: entries, profile: profile, settings: settings) { url in
            guard let url else { return }
            exportURL = url
            showShareSheet = true
        }
    }

    func copyReport(using profile: ExportProfile) {
        let entries = entries(for: profile.dateRange)
        ExportEngine.copyReportToPasteboard(
            entries: entries,
            profile: profile,
            settings: settings
        )
    }

    func entries(for dateRange: ExportDateRange) -> [WorkDay] {
        switch dateRange {
        case .currentMonth:
            return calendarVM.entries
                .filter { calendar.isDate($0.date, equalTo: currentMonth, toGranularity: .month) }
                .sorted { $0.date < $1.date }
        case .previousMonth:
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) else {
                return []
            }
            return calendarVM.entries
                .filter { calendar.isDate($0.date, equalTo: previousMonth, toGranularity: .month) }
                .sorted { $0.date < $1.date }
        case .nextMonth:
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) else {
                return []
            }
            return calendarVM.entries
                .filter { calendar.isDate($0.date, equalTo: nextMonth, toGranularity: .month) }
                .sorted { $0.date < $1.date }
        case let .custom(start, end):
            return calendarVM.entries
                .filter { $0.date >= start && $0.date <= end }
                .sorted { $0.date < $1.date }
        }
    }
}
