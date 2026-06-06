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

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = settings.weekStartDay.firstWeekday
        return calendar
    }

    var body: some View {
        NavigationView {
            VStack {
                reportHeader
                    .padding(.horizontal)
                    .padding(.top, 8)

                monthlySummaryGrid
                    .padding(.horizontal)

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
                            .foregroundColor(isWeekend(row.date) ? .red : .primary)
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
            .id("\(settings.timeFormat.rawValue)-\(settings.weekStartDay.rawValue)")
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
        .id("\(settings.timeFormat.rawValue)-\(settings.weekStartDay.rawValue)")
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

    private var monthlySummaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            reportSummaryCard(title: "Worked", value: totalHoursInMonth())
            reportSummaryCard(title: "Expected", value: durationString(expectedMinutesInMonth))
            reportSummaryCard(title: "Month Target", value: durationString(expectedMinutesThroughMonthEnd))
            reportSummaryCard(title: "Overtime", value: WorkDurationFormatter.signedDisplayString(for: overtimeMinutesInMonth))
            reportSummaryCard(title: "Shortfall", value: durationString(shortfallMinutesInMonth))
        }
    }

    private func reportSummaryCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    private var entriesInCurrentMonth: [WorkDay] {
        entries(for: .currentMonth)
    }

    private var expectedMinutesInMonth: Int {
        settings.expectedDailyMinutes * expectedWeekdayCount(from: monthStart, to: expectedMonthEnd)
    }

    private var expectedMinutesThroughMonthEnd: Int {
        settings.expectedDailyMinutes * expectedWeekdayCount(from: monthStart, to: monthEnd)
    }

    private var monthStart: Date {
        calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
    }

    private var monthEnd: Date {
        guard let interval = calendar.dateInterval(of: .month, for: currentMonth) else { return currentMonth }
        return calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
    }

    private var expectedMonthEnd: Date {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: monthStart)
        let end = calendar.startOfDay(for: monthEnd)

        if start <= today && today <= end {
            return today
        }

        return monthEnd
    }

    private var overtimeMinutesInMonth: Int {
        entriesInCurrentMonth.reduce(0) { total, entry in
            guard entry.hasWorkingTime else { return total }
            return total + max(entry.totalMinutes - settings.expectedDailyMinutes, 0)
        }
    }

    private var shortfallMinutesInMonth: Int {
        let totalMinutes = entriesInCurrentMonth.reduce(0) { $0 + $1.totalMinutes }
        return max(expectedMinutesInMonth - totalMinutes, 0)
    }

    func previousMonth() { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
    func nextMonth() { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }

    func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy  EEEE"
        return formatter.string(from: date)
    }

    func isWeekend(_ date: Date) -> Bool {
        Calendar.current.isDateInWeekend(date)
    }

    func timeString(_ date: Date) -> String {
        DateFormatterHelper.string(from: date, format: settings.timeFormat)
    }

    func totalHoursString(_ entry: WorkDay) -> String { entry.totalHoursString }

    func timingsString(_ entry: WorkDay) -> String {
        guard entry.hasWorkingTime else { return "No Working" }
        return "\(timeString(entry.fromTime))-\(timeString(entry.toTime))"
    }

    func payoutString(_ entry: WorkDay) -> String { String(format: "%.2f", entry.totalPayout) }

    func totalHoursInMonth() -> String {
        let totalMinutes = entriesInCurrentMonth.reduce(0) { $0 + $1.totalMinutes }
        return durationString(totalMinutes)
    }

    func totalPayoutInMonth() -> String {
        let total = entriesInCurrentMonth.reduce(0) { $0 + $1.totalPayout }
        return String(format: "%.2f", total)
    }

    func totalWorkDaysInMonth() -> String {
        "Work Days : \(entriesInCurrentMonth.filter(\.hasWorkingTime).count)"
    }

    func durationString(_ minutes: Int) -> String {
        WorkDurationFormatter.displayString(for: minutes)
    }

    func expectedWeekdayCount(from startDate: Date, to endDate: Date) -> Int {
        let start = calendar.startOfDay(for: min(startDate, endDate))
        let end = calendar.startOfDay(for: max(startDate, endDate))
        let dayCount = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1

        guard dayCount > 0 else { return 0 }

        return (0..<dayCount).reduce(0) { count, offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return count }
            return calendar.isDateInWeekend(date) ? count : count + 1
        }
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
