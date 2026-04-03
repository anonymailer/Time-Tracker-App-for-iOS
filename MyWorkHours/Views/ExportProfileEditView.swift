import SwiftUI

struct ExportProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var exportVM: ExportProfilesViewModel

    @State private var selectedColumns: [ExportColumn] = ExportColumn.allCases
    @State private var includeMonthlyTotal: Bool = true
    @State private var dateRangeSelection: ExportRangeSelection = .currentMonth
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var timeFormatOverride: TimeFormat = .hour24

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Columns")) {
                    ForEach(ExportColumn.allCases, id: \.self) { column in
                        Toggle(column.rawValue.capitalized, isOn: columnBinding(for: column))
                            .disabled(column == .day)
                    }
                }

                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $dateRangeSelection) {
                        Text("Current Month").tag(ExportRangeSelection.currentMonth)
                        Text("Previous Month").tag(ExportRangeSelection.previousMonth)
                        Text("Next Month").tag(ExportRangeSelection.nextMonth)
                        Text("Custom").tag(ExportRangeSelection.custom)
                    }

                    if dateRangeSelection == .custom {
                        DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                    }
                }

                Section {
                    Toggle("Include Monthly Total", isOn: $includeMonthlyTotal)
                }

                Section(header: Text("Time Format")) {
                    Picker("Time Format", selection: $timeFormatOverride) {
                        Text("12-hour").tag(TimeFormat.hour12)
                        Text("24-hour").tag(TimeFormat.hour24)
                    }
                }

                Section {
                    Button("Save") {
                        exportVM.saveExportSettings(
                            ExportProfile(
                                name: "Export Settings",
                                selectedColumns: selectedColumns,
                                includeMonthlyTotal: includeMonthlyTotal,
                                dateRange: resolvedDateRange,
                                formats: ExportFormat.allCases,
                                timeFormatOverride: timeFormatOverride,
                                currencyOverride: nil
                            )
                        )
                        dismiss()
                    }
                }
            }
            .navigationTitle("Export Settings")
            .onAppear {
                populateForm()
            }
        }
    }

    private var resolvedDateRange: ExportDateRange {
        switch dateRangeSelection {
        case .currentMonth:
            return .currentMonth
        case .previousMonth:
            return .previousMonth
        case .nextMonth:
            return .nextMonth
        case .custom:
            return .custom(start: customStartDate, end: customEndDate)
        }
    }

    private func populateForm() {
        let settings = exportVM.exportSettings
        selectedColumns = normalizedColumns(from: settings.selectedColumns)
        includeMonthlyTotal = settings.includeMonthlyTotal
        timeFormatOverride = settings.timeFormatOverride ?? .hour24

        switch settings.dateRange {
        case .currentMonth:
            dateRangeSelection = .currentMonth
        case .previousMonth:
            dateRangeSelection = .previousMonth
        case .nextMonth:
            dateRangeSelection = .nextMonth
        case let .custom(start, end):
            dateRangeSelection = .custom
            customStartDate = start
            customEndDate = end
        }
    }

    private func columnBinding(for column: ExportColumn) -> Binding<Bool> {
        Binding(
            get: { selectedColumns.contains(column) },
            set: { isSelected in
                if column == .day {
                    selectedColumns = normalizedColumns(from: selectedColumns + [.day])
                    return
                }

                if isSelected {
                    if !selectedColumns.contains(column) {
                        selectedColumns = normalizedColumns(from: selectedColumns + [column])
                    }
                } else {
                    selectedColumns = normalizedColumns(from: selectedColumns.filter { $0 != column })
                }
            }
        )
    }

    private func normalizedColumns(from columns: [ExportColumn]) -> [ExportColumn] {
        ExportColumn.allCases.filter { column in
            column == .day || columns.contains(column)
        }
    }
}

private enum ExportRangeSelection: Hashable {
    case currentMonth
    case previousMonth
    case nextMonth
    case custom
}
