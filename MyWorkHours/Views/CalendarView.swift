import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var selectedDate: Date = Date()
    @State private var selectedDates: [Date] = []
    @State private var isSelectingMultipleDates = false
    @State private var showEntrySheet = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    CalendarPickerView(
                        selectedDate: $selectedDate,
                        selectedDates: $selectedDates,
                        isSelectingMultipleDates: $isSelectingMultipleDates,
                        entries: calendarVM.entries,
                        timeFormat: settings.timeFormat,
                        weekStartDay: settings.weekStartDay,
                        expectedDailyMinutes: settings.expectedDailyMinutes
                    )
                    .frame(height: 470)
                    .padding(.horizontal)

                    if isSelectingMultipleDates {
                        if !selectedDates.isEmpty {
                            Text(selectionSummary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top, 4)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelectingMultipleDates ? "Cancel Selection" : "Select Days") {
                        if isSelectingMultipleDates {
                            cancelSelection()
                        } else {
                            selectedDates = []
                            isSelectingMultipleDates = true
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add/Edit") {
                        showEntrySheet = true
                    }
                }
            }
            .sheet(isPresented: $showEntrySheet) {
                DayEntrySheetView(dates: entryDates)
                    .environmentObject(calendarVM)
                    .environmentObject(templatesVM)
            }
            .safeAreaInset(edge: .bottom) {
                selectedEntryDetails
                    .padding(.top, 12)
            }
        }
    }

    private var selectedEntryDetails: some View {
        Group {
            if let entry = calendarVM.entry(for: selectedDate) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("From: \(timeString(entry.fromTime))")
                    Text("To: \(timeString(entry.displayedToTime))")
                    Text("Work Hours: \(entry.totalHoursString)")
                    Text("Expected: \(durationString(settings.expectedDailyMinutes))")
                    Text("Overtime: \(WorkDurationFormatter.signedDisplayString(for: dailyDeltaMinutes(entry)))")
                        .foregroundColor(dailyDeltaMinutes(entry) >= 0 ? .green : .orange)
                    Text("Payout: \(String(format: "%.2f", entry.totalPayout))")
                    Text("Notes: \(entry.notes)")
                }
            } else {
                Text("No entry for this day")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 12)
    }

    private var entryDates: [Date] {
        if isSelectingMultipleDates, !selectedDates.isEmpty {
            return selectedDates.sorted()
        }
        return [normalizedDate(selectedDate)]
    }

    private var selectionSummary: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return selectedDates
            .sorted()
            .map { formatter.string(from: $0) }
            .joined(separator: ", ")
    }

    private func normalizedDate(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    private func cancelSelection() {
        selectedDates = []
        isSelectingMultipleDates = false
    }

    private func timeString(_ date: Date) -> String {
        DateFormatterHelper.string(from: date, format: settings.timeFormat)
    }

    private func durationString(_ minutes: Int) -> String {
        WorkDurationFormatter.displayString(for: minutes)
    }

    private func dailyDeltaMinutes(_ entry: WorkDay) -> Int {
        entry.totalMinutes - settings.expectedDailyMinutes
    }
}

private struct CalendarPickerView: View {
    @Binding var selectedDate: Date
    @Binding var selectedDates: [Date]
    @Binding var isSelectingMultipleDates: Bool

    let entries: [WorkDay]
    let timeFormat: TimeFormat
    let weekStartDay: WeekStartDay
    let expectedDailyMinutes: Int
    @State private var displayedMonth: Date = Date()

    private var configuredCalendar: Calendar {
        var calendar = Calendar.current
        calendar.firstWeekday = weekStartDay.firstWeekday
        return calendar
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(monthYearString)
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 14) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(weekdayHeaderColor(for: symbol))
                        .frame(maxWidth: .infinity)
                }

                ForEach(monthCells) { cell in
                    switch cell.kind {
                    case .empty:
                        Color.clear
                            .frame(height: 68)
                    case let .day(date):
                        Button {
                            select(date)
                        } label: {
                            VStack(spacing: 6) {
                                Text(dayNumberString(for: date))
                                    .font(.title3.weight(.semibold))
                                    .frame(width: 40, height: 40)
                                    .background(
                                        Circle()
                                            .fill(isSelected(date) ? Color.blue : Color.clear)
                                    )
                                    .foregroundColor(dayTextColor(for: date))

                                if let timingTextLines = entryTimingTextLines(for: date) {
                                    VStack(spacing: 1) {
                                        ForEach(timingTextLines, id: \.self) { line in
                                            Text(line)
                                                .font(.system(size: 9, weight: .semibold))
                                                .lineLimit(1)
                                                .minimumScaleFactor(0.7)
                                        }
                                    }
                                    .foregroundColor(isSelected(date) ? .blue : entryTimingForegroundColor(for: date))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 3)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(entryTimingBackgroundColor(for: date, isSelected: isSelected(date)))
                                    )
                                    .frame(maxWidth: .infinity)
                                } else {
                                    Color.clear
                                        .frame(height: 22)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 68)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    if value.translation.width < -40 {
                        moveMonth(by: 1)
                    } else if value.translation.width > 40 {
                        moveMonth(by: -1)
                    }
                }
        )
        .onAppear {
            displayedMonth = monthStart(for: isSelectingMultipleDates ? (selectedDates.first ?? selectedDate) : selectedDate)
        }
        .onChange(of: selectedDate) { _, newValue in
            if !isSelectingMultipleDates {
                displayedMonth = monthStart(for: newValue)
            }
        }
        .onChange(of: isSelectingMultipleDates) { _, isSelecting in
            displayedMonth = monthStart(for: isSelecting ? (selectedDates.first ?? selectedDate) : selectedDate)
        }
        .onChange(of: weekStartDay) { _, _ in
            displayedMonth = monthStart(for: displayedMonth)
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.calendar = configuredCalendar
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.calendar = configuredCalendar
        let symbols = formatter.shortStandaloneWeekdaySymbols ?? formatter.shortWeekdaySymbols ?? []
        let shift = max(configuredCalendar.firstWeekday - 1, 0)
        guard !symbols.isEmpty else { return [] }
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private var monthCells: [CalendarDayCell] {
        guard
            let monthInterval = configuredCalendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = configuredCalendar.range(of: .day, in: .month, for: displayedMonth)
        else {
            return []
        }

        let firstDay = monthInterval.start
        let weekday = configuredCalendar.component(.weekday, from: firstDay)
        let leadingPadding = (weekday - configuredCalendar.firstWeekday + 7) % 7

        var cells = Array(repeating: CalendarDayCell(kind: .empty), count: leadingPadding)
        cells.append(contentsOf: dayRange.compactMap { day -> CalendarDayCell? in
            configuredCalendar.date(byAdding: .day, value: day - 1, to: firstDay).map { CalendarDayCell(kind: .day($0)) }
        })

        let trailingPadding = (7 - (cells.count % 7)) % 7
        cells.append(contentsOf: Array(repeating: CalendarDayCell(kind: .empty), count: trailingPadding))
        return cells
    }

    private func moveMonth(by value: Int) {
        if let updated = configuredCalendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = monthStart(for: updated)
        }
    }

    private func select(_ date: Date) {
        let normalized = configuredCalendar.startOfDay(for: date)
        selectedDate = normalized

        if isSelectingMultipleDates {
            if let existingIndex = selectedDates.firstIndex(where: { configuredCalendar.isDate($0, inSameDayAs: normalized) }) {
                selectedDates.remove(at: existingIndex)
            } else {
                selectedDates.append(normalized)
                selectedDates.sort()
            }
        } else {
            displayedMonth = monthStart(for: normalized)
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        if isSelectingMultipleDates {
            return selectedDates.contains { configuredCalendar.isDate($0, inSameDayAs: date) }
        }
        return configuredCalendar.isDate(selectedDate, inSameDayAs: date)
    }

    private func entry(for date: Date) -> WorkDay? {
        entries.first { configuredCalendar.isDate($0.date, inSameDayAs: date) }
    }

    private func entryTimingTextLines(for date: Date) -> [String]? {
        guard let entry = entry(for: date) else { return nil }
        guard entry.hasWorkingTime else { return ["Leave"] }
        return [timeString(entry.fromTime), timeString(entry.toTime)]
    }

    private func entryTimingForegroundColor(for date: Date) -> Color {
        guard let entry = entry(for: date), entry.hasWorkingTime else { return .primary }
        return entry.totalMinutes >= expectedDailyMinutes ? .orange : .primary
    }

    private func entryTimingBackgroundColor(for date: Date, isSelected: Bool) -> Color {
        guard !isSelected else { return .white }
        guard let entry = entry(for: date), entry.hasWorkingTime else { return Color(.systemGray6) }
        return entry.totalMinutes >= expectedDailyMinutes ? Color.orange.opacity(0.16) : Color(.systemGray6)
    }

    private func dayNumberString(for date: Date) -> String {
        String(configuredCalendar.component(.day, from: date))
    }

    private func dayTextColor(for date: Date) -> Color {
        if isSelected(date) {
            return .white
        }
        return configuredCalendar.isDateInWeekend(date) ? .red : .blue
    }

    private func weekdayHeaderColor(for symbol: String) -> Color {
        guard let weekdayIndex = weekdaySymbols.firstIndex(of: symbol) else {
            return .secondary
        }
        let weekday = ((configuredCalendar.firstWeekday - 1 + weekdayIndex) % 7) + 1
        return weekday == 1 || weekday == 7 ? .red : .secondary
    }

    private func monthStart(for date: Date) -> Date {
        configuredCalendar.date(from: configuredCalendar.dateComponents([.year, .month], from: date)) ?? date
    }

    private func timeString(_ date: Date) -> String {
        DateFormatterHelper.string(from: date, format: timeFormat)
    }
}

private struct CalendarDayCell: Identifiable {
    enum Kind {
        case empty
        case day(Date)
    }

    let id = UUID()
    let kind: Kind
}
