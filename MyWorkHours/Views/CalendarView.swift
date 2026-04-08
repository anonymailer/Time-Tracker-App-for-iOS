import SwiftUI
import UIKit

struct CalendarView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @State private var selectedDate: Date = Date()
    @State private var selectedDates: [Date] = []
    @State private var isSelectingMultipleDates = false
    @State private var showEntrySheet = false
    @State private var countdownOpacity = 1.0

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Text(daysCompletedText)
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundColor(.red)
                        .opacity(shouldBlinkCountdown ? countdownOpacity : 1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, -10)

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
            .onAppear {
                updateCountdownBlinking()
            }
            .onChange(of: daysLeft) { _, _ in
                updateCountdownBlinking()
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
        DateFormatterHelper.timeFormatter(for: settings.timeFormat).string(from: date)
    }

    private var daysCompletedText: String {
        return "\(daysLeft) Days Left"
    }

    private var daysLeft: Int {
        let completedDays = Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: settings.installationDate),
            to: Calendar.current.startOfDay(for: Date())
        ).day ?? 0
        return max(6 - completedDays, 0)
    }

    private var shouldBlinkCountdown: Bool {
        daysLeft <= 1
    }

    private func updateCountdownBlinking() {
        if shouldBlinkCountdown {
            countdownOpacity = 1
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                countdownOpacity = 0.2
            }
        } else {
            countdownOpacity = 1
        }
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
        calendarView.tintColor = .systemBlue
        context.coordinator.configureSelectionBehavior(for: calendarView)
        context.coordinator.applyCalendarStyling(to: calendarView)
        return calendarView
    }

    func updateUIView(_ uiView: UICalendarView, context: Context) {
        context.coordinator.parent = self
        uiView.delegate = context.coordinator
        context.coordinator.configureSelectionBehavior(for: uiView)
        context.coordinator.applyCalendarStyling(to: uiView)

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
        weak var calendarView: UICalendarView?

        init(_ parent: CalendarPickerView) {
            self.parent = parent
        }

        func configureSelectionBehavior(for calendarView: UICalendarView) {
            self.calendarView = calendarView
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

        func applyCalendarStyling(to calendarView: UICalendarView) {
            updateSelectionAppearance(in: calendarView)
        }

        func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
            guard let dateComponents, let date = Calendar.current.date(from: dateComponents) else { return }
            parent.selectedDate = Calendar.current.startOfDay(for: date)
            if let calendarView {
                updateSelectionAppearance(in: calendarView)
            }
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didSelectDate dateComponents: DateComponents) {
            guard let date = Calendar.current.date(from: dateComponents) else { return }
            let normalized = Calendar.current.startOfDay(for: date)
            if !parent.selectedDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: normalized) }) {
                parent.selectedDates.append(normalized)
                parent.selectedDates.sort()
            }
            parent.selectedDate = normalized
            if let calendarView {
                updateSelectionAppearance(in: calendarView)
            }
        }

        func multiDateSelection(_ selection: UICalendarSelectionMultiDate, didDeselectDate dateComponents: DateComponents) {
            guard let date = Calendar.current.date(from: dateComponents) else { return }
            let normalized = Calendar.current.startOfDay(for: date)
            parent.selectedDates.removeAll { Calendar.current.isDate($0, inSameDayAs: normalized) }
            if let calendarView {
                updateSelectionAppearance(in: calendarView)
            }
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

        private func updateSelectionAppearance(in calendarView: UICalendarView) {
            DispatchQueue.main.async {
                self.hideMonthNavigationButtons(in: calendarView)
                self.applySelectionAppearanceRecursively(to: calendarView)
            }
        }

        private func hideMonthNavigationButtons(in view: UIView) {
            let className = String(describing: type(of: view))

            if className == "_UICalendarHeaderView" {
                let headerButtons = view.subviews.compactMap { $0 as? UIButton }
                for button in headerButtons where String(describing: type(of: button)) != "_UICalendarHeaderTitleButton" {
                    button.isHidden = true
                    button.isUserInteractionEnabled = false
                    button.alpha = 0
                }
            }

            for subview in view.subviews {
                hideMonthNavigationButtons(in: subview)
            }
        }

        private func applySelectionAppearanceRecursively(to view: UIView) {
            for subview in view.subviews {
                if let button = subview as? UIButton {
                    if button.isSelected {
                        button.backgroundColor = .systemBlue
                        button.tintColor = .white
                        button.setTitleColor(.white, for: .selected)
                        button.setTitleColor(.white, for: .normal)
                        button.layer.borderWidth = 0
                        button.layer.borderColor = nil
                    } else if button.currentImage == nil {
                        button.backgroundColor = .clear
                        button.tintColor = .systemBlue
                        button.setTitleColor(.systemBlue, for: .normal)
                    }
                }

                if let label = subview as? UILabel,
                   let superview = label.superview as? UIButton,
                   superview.isSelected {
                    label.textColor = .white
                }

                applySelectionAppearanceRecursively(to: subview)
            }
        }
    }
}
