import SwiftUI
import UIKit

struct ReportsView: View {
    private struct ReportRow: Identifiable {
        let date: Date
        let entry: WorkDay?

        var id: Date { date }
    }

    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var exportVM: ExportProfilesViewModel

    @State private var currentMonth: Date = Date()
    @State private var showExportSheet = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    private let calendar = Calendar.current

    var body: some View {
        NavigationView {
            VStack {
                reportHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

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
                                Text(dayString(row.date)).frame(width: dayColumnWidth, alignment: .leading)
                                Text(row.entry.map(timingsString) ?? "--").frame(width: timingsColumnWidth, alignment: .leading)
                                Text(row.entry.map(totalHoursString) ?? "--").frame(width: hoursColumnWidth, alignment: .trailing)
                                Text(row.entry.map(payoutString) ?? "--").frame(width: payoutColumnWidth, alignment: .trailing)
                                Spacer().frame(width: 12)
                                Text(row.entry?.notes ?? "").frame(width: notesColumnWidth, alignment: .leading)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4)
                            Divider()
                        }

                        HStack {
                            Text("Monthly Total").bold().frame(width: dayColumnWidth, alignment: .leading)
                            Text(totalWorkDaysInMonth()).bold().frame(width: timingsColumnWidth, alignment: .leading)
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
            .id(settings.timeFormat)
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
        .id(settings.timeFormat)
    }

    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !exportVM.exportSettings.firmName.isEmpty {
                Text(exportVM.exportSettings.firmName)
                    .font(.title3.weight(.bold))
            }
            if !exportVM.exportSettings.personName.isEmpty {
                Text(exportVM.exportSettings.personName)
                    .font(.subheadline)
            }
            Text(currentReportPeriodTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var currentReportPeriodTitle: String {
        "Report for the month of \(monthYearString)"
    }

    private var reportRows: [ReportRow] {
        daysInMonth.map { date in
            ReportRow(date: date, entry: calendarVM.entry(for: date))
        }
    }

    private var dayColumnWidth: CGFloat {
        columnWidth(header: "Day", values: reportRows.map { dayString($0.date) } + ["Monthly Total"])
    }

    private var timingsColumnWidth: CGFloat {
        columnWidth(header: "Timings", values: reportRows.map { $0.entry.map(timingsString) ?? "--" } + [totalWorkDaysInMonth()])
    }

    private var hoursColumnWidth: CGFloat {
        columnWidth(header: "Work Hours", values: reportRows.map { $0.entry.map(totalHoursString) ?? "--" } + [totalHoursInMonth()], minimum: 90, alignment: .right)
    }

    private var payoutColumnWidth: CGFloat {
        columnWidth(header: "Payout", values: reportRows.map { $0.entry.map(payoutString) ?? "--" } + [totalPayoutInMonth()], minimum: 80, alignment: .right)
    }

    private var notesColumnWidth: CGFloat {
        columnWidth(header: "Notes", values: reportRows.map { $0.entry?.notes ?? "" }, minimum: 140)
    }

    func previousMonth() { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
    func nextMonth() { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }

    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        return formatter.string(from: date)
    }

    func timeString(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0

        switch settings.timeFormat {
        case .hour24:
            return String(format: "%02d:%02d", hour, minute)
        case .hour12:
            let formatter = DateFormatterHelper.timeFormatter(for: .hour12)
            return formatter.string(from: date)
        }
    }

    func totalHoursString(_ entry: WorkDay) -> String { entry.totalHoursString }

    func timingsString(_ entry: WorkDay) -> String {
        guard entry.hasWorkingTime else { return "No Working" }
        return "\(timeString(entry.fromTime))-\(timeString(entry.toTime))"
    }

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

    func totalWorkDaysInMonth() -> String {
        "Work Days : \(entries(for: .currentMonth).filter(\.hasWorkingTime).count)"
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
        ExportEngine.export(entries: entries, profile: resolvedProfile(profile), settings: settings) { url in
            guard let url else { return }
            exportURL = url
            showShareSheet = true
        }
    }

    func copyReport(using profile: ExportProfile) {
        let entries = entries(for: profile.dateRange)
        ExportEngine.copyReportToPasteboard(
            entries: entries,
            profile: resolvedProfile(profile),
            settings: settings
        )
    }

    func resolvedProfile(_ profile: ExportProfile) -> ExportProfile {
        var profile = profile
        profile.reportPeriodTitle = reportPeriodTitle(for: profile.dateRange)
        return profile
    }

    func reportPeriodTitle(for dateRange: ExportDateRange) -> String {
        switch dateRange {
        case .currentMonth:
            return currentReportPeriodTitle
        case .previousMonth:
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
            return "Report for the month of \(monthYearString(for: previousMonth))"
        case .nextMonth:
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
            return "Report for the month of \(monthYearString(for: nextMonth))"
        case let .custom(start, end):
            return "Report for the period of \(periodDateString(start))-\(periodDateString(end))"
        }
    }

    func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    func periodDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
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
