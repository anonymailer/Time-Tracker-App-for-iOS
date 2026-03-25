import SwiftUI

struct ReportsView: View {
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

                // Table Header
                HStack {
                    Text("Day").bold().frame(width: 120, alignment: .leading)
                    Text("Timings").bold().frame(width: 100, alignment: .leading)
                    Text("Hours").bold().frame(width: 60, alignment: .trailing)
                    Text("Payout").bold().frame(width: 80, alignment: .trailing)
                    Text("Notes").bold().frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                Divider()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(daysInMonth, id: \.self) { date in
                            let entry = calendarVM.entry(for: date)
                            HStack {
                                Text(dayString(date)).frame(width: 120, alignment: .leading)
                                Text(entry != nil ? "\(timeString(entry!.fromTime))-\(timeString(entry!.toTime))" : "--").frame(width: 100, alignment: .leading)
                                Text(entry != nil ? totalHoursString(entry!) : "--").frame(width: 60, alignment: .trailing)
                                Text(entry != nil ? payoutString(entry!) : "--").frame(width: 80, alignment: .trailing)
                                Text(entry?.notes ?? "").frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.vertical, 4)
                            Divider()
                        }

                        // Monthly totals
                        HStack {
                            Text("Monthly Total").bold().frame(width: 120, alignment: .leading)
                            Spacer()
                            Text(totalHoursInMonth()).bold().frame(width: 60, alignment: .trailing)
                            Text(totalPayoutInMonth()).bold().frame(width: 80, alignment: .trailing)
                            Spacer()
                        }
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
                ExportProfilesView()
                    .environmentObject(calendarVM)
                    .environmentObject(settings)
                    .environmentObject(exportVM)
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
        let totalMinutes = calendarVM.entries.reduce(0) { $0 + $1.totalMinutes }
        let hours = totalMinutes / 60
        let mins = totalMinutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    func totalPayoutInMonth() -> String {
        let total = calendarVM.entries.reduce(0) { $0 + $1.totalPayout }
        return "\(settings.currencyCode) \(String(format: "%.2f", total))"
    }
}