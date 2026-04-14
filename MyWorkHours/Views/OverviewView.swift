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

    private var totalNonWorkingDays: Int {
        max(totalDays - totalWorkDays, 0)
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

    private var metrics: [OverviewMetric] {
        [
            OverviewMetric(title: "Total Days", value: "\(totalDays)"),
            OverviewMetric(title: "Total Work Days", value: "\(totalWorkDays)"),
            OverviewMetric(title: "Total Non Working Days", value: "\(totalNonWorkingDays)"),
            OverviewMetric(title: "Total Leaves", value: "\(totalLeaves)"),
            OverviewMetric(title: "Total Hours", value: durationString(totalSpanMinutes)),
            OverviewMetric(title: "Total Break Time", value: durationString(totalBreakMinutes)),
            OverviewMetric(title: "Total Work Hours", value: durationString(totalWorkMinutes)),
            OverviewMetric(title: "Total Payout", value: String(format: "%.2f", totalPayout))
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
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Period")
                            .font(.headline)

                        Picker("Period", selection: $period) {
                            ForEach(OverviewPeriod.allCases) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        switch period {
                        case .monthly:
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Year", selection: $selectedYear) {
                                    ForEach(years, id: \.self) { year in
                                        Text(String(year)).tag(year)
                                    }
                                }

                                Picker("Month", selection: $selectedMonth) {
                                    ForEach(Array(monthSymbols.enumerated()), id: \.offset) { index, month in
                                        Text(month).tag(index + 1)
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
                            VStack(alignment: .leading, spacing: 12) {
                                DatePicker("Start Date", selection: $customStartDate, displayedComponents: .date)
                                DatePicker("End Date", selection: $customEndDate, displayedComponents: .date)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Text(periodDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(metrics) { metric in
                            overviewCard(title: metric.title, value: metric.value)
                        }
                    }
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

    private func overviewCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func durationString(_ totalMinutes: Int) -> String {
        let safeMinutes = max(totalMinutes, 0)
        return String(format: "%02d:%02d", safeMinutes / 60, safeMinutes % 60)
    }

    private func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy"
        return formatter.string(from: date)
    }
}
