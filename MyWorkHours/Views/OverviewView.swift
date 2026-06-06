import SwiftUI

struct OverviewView: View {
    private enum OverviewPeriod: String, CaseIterable, Identifiable {
        case monthly = "Monthly"
        case yearly = "Yearly"
        case custom = "Custom"

        var id: String { rawValue }
    }

    private struct OverviewMetric: Identifiable {
        let id = UUID()
        let title: String
        let value: String
    }

    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var period: OverviewPeriod = .monthly
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: Date())
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var customStartDate: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    @State private var customEndDate: Date = Date()

    private var calendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = settings.weekStartDay.firstWeekday
        return calendar
    }

    private var years: [Int] {
        let currentYear = calendar.component(.year, from: Date())
        let entryYears = calendarVM.entries.map { calendar.component(.year, from: $0.date) }
        let minYear = min(entryYears.min() ?? currentYear, currentYear)
        let maxYear = max(entryYears.max() ?? currentYear, currentYear)
        return Array(minYear...maxYear).sorted(by: >)
    }

    private var monthSymbols: [String] {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        return formatter.monthSymbols
    }

    private var rangeStart: Date {
        switch period {
        case .monthly:
            return calendar.date(from: DateComponents(year: selectedYear, month: selectedMonth, day: 1)) ?? Date()
        case .yearly:
            return calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? Date()
        case .custom:
            return calendar.startOfDay(for: min(customStartDate, customEndDate))
        }
    }

    private var rangeEnd: Date {
        switch period {
        case .monthly:
            let start = rangeStart
            guard let monthInterval = calendar.dateInterval(of: .month, for: start) else { return start }
            return calendar.date(byAdding: .second, value: -1, to: monthInterval.end) ?? start
        case .yearly:
            let start = rangeStart
            guard let yearInterval = calendar.dateInterval(of: .year, for: start) else { return start }
            return calendar.date(byAdding: .second, value: -1, to: yearInterval.end) ?? start
        case .custom:
            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: max(customStartDate, customEndDate)) ?? max(customStartDate, customEndDate)
        }
    }

    private var filteredEntries: [WorkDay] {
        calendarVM.entries
            .filter { $0.date >= rangeStart && $0.date <= rangeEnd }
            .sorted { $0.date < $1.date }
    }

    private var totalDays: Int {
        let start = calendar.startOfDay(for: rangeStart)
        let end = calendar.startOfDay(for: rangeEnd)
        return (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1
    }

    private var totalWorkDays: Int {
        filteredEntries.filter(\.hasWorkingTime).count
    }

    private var totalLeaves: Int {
        filteredEntries.filter { !$0.hasWorkingTime }.count
    }

    private var totalSpanMinutes: Int {
        filteredEntries.reduce(0) { $0 + max($1.spanMinutes, 0) }
    }

    private var totalBreakMinutes: Int {
        filteredEntries.reduce(0) { $0 + max($1.breakMinutes, 0) }
    }

    private var totalWorkMinutes: Int {
        filteredEntries.reduce(0) { $0 + $1.totalMinutes }
    }

    private var totalPayout: Double {
        filteredEntries.reduce(0) { $0 + $1.totalPayout }
    }

    private var expectedWorkMinutes: Int {
        settings.expectedDailyMinutes * expectedWeekdayCount(from: rangeStart, to: expectedRangeEnd)
    }

    private var expectedRangeEnd: Date {
        let today = calendar.startOfDay(for: Date())
        let start = calendar.startOfDay(for: rangeStart)
        let end = calendar.startOfDay(for: rangeEnd)

        if start <= today && today <= end {
            return today
        }

        return rangeEnd
    }

    private var expectedMonthlyMinutes: Int {
        settings.expectedDailyMinutes * expectedWeekdayCount(from: rangeStart, to: rangeEnd)
    }

    private var expectedWorkDays: Int {
        expectedWeekdayCount(from: rangeStart, to: expectedRangeEnd)
    }

    private var totalOvertimeMinutes: Int {
        max(totalWorkMinutes - expectedWorkMinutes, 0)
    }

    private var shortfallMinutes: Int {
        max(expectedWorkMinutes - totalWorkMinutes, 0)
    }

    private var averageWorkMinutes: Int {
        guard totalWorkDays > 0 else { return 0 }
        return totalWorkMinutes / totalWorkDays
    }

    private var summaryMetrics: [OverviewMetric] {
        var metrics = [
            OverviewMetric(title: "Worked", value: durationString(totalWorkMinutes)),
            OverviewMetric(title: "Expected", value: durationString(expectedWorkMinutes)),
            OverviewMetric(title: "Total Overtime", value: signedDurationString(totalOvertimeMinutes)),
            OverviewMetric(title: "Shortfall", value: durationString(shortfallMinutes)),
            OverviewMetric(title: "Avg Day", value: durationString(averageWorkMinutes))
        ]

        if period == .monthly {
            metrics.insert(OverviewMetric(title: "Month Target", value: durationString(expectedMonthlyMinutes)), at: 2)
        }

        return metrics
    }

    private var detailMetrics: [OverviewMetric] {
        [
            OverviewMetric(title: "Work Days", value: "\(totalWorkDays)"),
            OverviewMetric(title: "Expected Days", value: "\(expectedWorkDays)"),
            OverviewMetric(title: "Leaves", value: "\(totalLeaves)"),
            OverviewMetric(title: "Break Time", value: durationString(totalBreakMinutes)),
            OverviewMetric(title: "Span Hours", value: durationString(totalSpanMinutes)),
            OverviewMetric(title: "Payout", value: String(format: "%.2f", totalPayout))
        ]
    }

    private var periodDescription: String {
        switch period {
        case .monthly:
            return "\(monthSymbols[selectedMonth - 1]) \(selectedYear)"
        case .yearly:
            return "\(selectedYear)"
        case .custom:
            return "\(dateString(rangeStart)) - \(dateString(rangeEnd))"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    periodControls

                    VStack(alignment: .leading, spacing: 4) {
                        Text(periodDescription)
                            .font(.headline)
                        Text("Expected hours use Monday-Friday weekdays.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    summaryPanel

                    DisclosureGroup("Details") {
                        VStack(spacing: 0) {
                            ForEach(detailMetrics) { metric in
                                detailRow(title: metric.title, value: metric.value)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Overview")
        }
        .onAppear {
            if !years.contains(selectedYear), let firstYear = years.first {
                selectedYear = firstYear
            }
        }
    }

    private var periodControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Period", selection: $period) {
                ForEach(OverviewPeriod.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            switch period {
            case .monthly:
                HStack(spacing: 12) {
                    Picker("Month", selection: $selectedMonth) {
                        ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, month in
                            Text(month).tag(index + 1)
                        }
                    }

                    Picker("Year", selection: $selectedYear) {
                        ForEach(years, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                }
            case .yearly:
                Picker("Year", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            case .custom:
                VStack(spacing: 8) {
                    DatePicker("Start", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("End", selection: $customEndDate, displayedComponents: .date)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var summaryPanel: some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalWorkDays) days worked")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Worked")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(durationString(totalWorkMinutes))
                        .font(.system(.title, design: .rounded).weight(.semibold))
                        .minimumScaleFactor(0.8)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(expectedWorkDays) days expected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Expected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(durationString(expectedWorkMinutes))
                        .font(.title3.weight(.semibold))
                        .minimumScaleFactor(0.8)
                }
            }

            ProgressView(value: progressValue)
                .tint(progressTint)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(summaryMetrics.dropFirst(2)) { metric in
                    compactMetric(title: metric.title, value: metric.value)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var progressValue: Double {
        guard expectedWorkMinutes > 0 else { return 0 }
        return min(Double(totalWorkMinutes) / Double(expectedWorkMinutes), 1)
    }

    private var progressTint: Color {
        totalWorkMinutes >= expectedWorkMinutes ? .green : .blue
    }

    private func compactMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
        .padding(.vertical, 7)
    }

    private func expectedWeekdayCount(from startDate: Date, to endDate: Date) -> Int {
        let start = calendar.startOfDay(for: min(startDate, endDate))
        let end = calendar.startOfDay(for: max(startDate, endDate))
        let dayCount = (calendar.dateComponents([.day], from: start, to: end).day ?? 0) + 1

        guard dayCount > 0 else { return 0 }

        return (0..<dayCount).reduce(0) { count, offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: start) else { return count }
            return calendar.isDateInWeekend(date) ? count : count + 1
        }
    }

    private func durationString(_ totalMinutes: Int) -> String {
        WorkDurationFormatter.displayString(for: totalMinutes)
    }

    private func signedDurationString(_ totalMinutes: Int) -> String {
        WorkDurationFormatter.signedDisplayString(for: totalMinutes)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}
