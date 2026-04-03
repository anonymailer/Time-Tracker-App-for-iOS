import SwiftUI
import UIKit

struct CalendarView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel

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
                        entryDates: calendarVM.entries.map(\.date)
                    )
                    .frame(height: 420)
                    .padding(.horizontal)

                    if isSelectingMultipleDates {
                        if !selectedDates.isEmpty {
                            Text(selectionSummary)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button("Cancel Selection") {
                            cancelSelection()
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.top)
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isSelectingMultipleDates ? "Done Selecting" : "Select Days") {
                        if isSelectingMultipleDates {
                            isSelectingMultipleDates = false
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
                    Text("From: \(entry.fromTimeString)")
                    Text("To: \(entry.toTimeString)")
                    Text("Work Hours: \(entry.totalHoursString)")
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
}

private struct CalendarPickerView: UIViewRepresentable {
    @Binding var selectedDate: Date
    @Binding var selectedDates: [Date]
    @Binding var isSelectingMultipleDates: Bool

    let entryDates: [Date]

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UICalendarView {
        let calendarView = UICalendarView()
        calendarView.calendar = Calendar.current
        calendarView.locale = .current
        calendarView.fontDesign = .rounded
        calendarView.delegate = context.coordinator
        context.coordinator.configureSelectionBehavior(for: calendarView)
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
        uiView.delegate = context.coordinator
        context.coordinator.configureSelectionBehavior(for: uiView)

        let visibleDate = isSelectingMultipleDates ? (selectedDates.first ?? selectedDate) : selectedDate
        uiView.setVisibleDateComponents(dateComponents(for: visibleDate), animated: false)

        if let singleSelection = uiView.selectionBehavior as? UICalendarSelectionSingleDate {
            singleSelection.setSelected(dateComponents(for: selectedDate), animated: false)
        }

        if let multiSelection = uiView.selectionBehavior as? UICalendarSelectionMultiDate {
            multiSelection.setSelectedDates(selectedDates.map(dateComponents(for:)), animated: false)
        }

        let reloadedComponents = Array(
            Set(context.coordinator.decoratedDateComponents + entryDates.map(dateComponents(for:)))
        )
        context.coordinator.decoratedDateComponents = entryDates.map(dateComponents(for:))
        uiView.reloadDecorations(forDateComponents: reloadedComponents, animated: false)
    }

    private func dateComponents(for date: Date) -> DateComponents {
        Calendar.current.dateComponents([.calendar, .year, .month, .day], from: Calendar.current.startOfDay(for: date))
    }

    final class Coordinator: NSObject, UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate, UICalendarSelectionMultiDateDelegate {
        var parent: CalendarPickerView
        var decoratedDateComponents: [DateComponents] = []

        init(_ parent: CalendarPickerView) {
            self.parent = parent
        }

        func configureSelectionBehavior(for calendarView: UICalendarView) {
            if parent.isSelectingMultipleDates {
                if !(calendarView.selectionBehavior is UICalendarSelectionMultiDate) {
                    calendarView.selectionBehavior = UICalendarSelectionMultiDate(delegate: self)
                }
            } else {
                if !(calendarView.selectionBehavior is UICalendarSelectionSingleDate) {
                    calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
                }
            }
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents) else { return }
            parent.selectedDate = Calendar.current.startOfDay(for: date)
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            guard let date = Calendar.current.date(from: dateComponents) else { return }
            let normalized = Calendar.current.startOfDay(for: date)
            if !parent.selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: normalized) }) {
                parent.selectedDates.append(normalized)
                parent.selectedDates.sort()
            }
            parent.selectedDate = normalized
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            guard let date = Calendar.current.date(from: dateComponents) else { return }
            let normalized = Calendar.current.startOfDay(for: date)
            parent.selectedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: normalized) }
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, canDeselectDate dateComponents: DateComponents) -> Bool {
            true
        }

        func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let date = Calendar.current.date(from: dateComponents) else { return nil }
            let normalized = Calendar.current.startOfDay(for: date)
            let hasEntry = parent.entryDates.contains { Calendar.current.isDate($0, inSameDayAs: normalized) }
            guard hasEntry else { return nil }
            return .default(color: .systemOrange, size: .small)
        }
    }
}
