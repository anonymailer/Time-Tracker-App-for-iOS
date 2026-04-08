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
    @State private var personName: String = ""
    @State private var firmName: String = ""

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
                        Text("Current Report").tag(ExportRangeSelection.currentMonth)
                        Text("Custom").tag(ExportRangeSelection.custom)
                    }

                    if dateRangeSelection == .custom {
                        DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                    }
                }

                Section(header: Text("Report Headings")) {
                    TextField("Your Name", text: $personName)
                    TextField("Firm Name", text: $firmName)
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
                                personName: personName,
                                firmName: firmName,
                                reportPeriodTitle: nil,
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
        case .custom:
            return .custom(start: customStartDate, end: customEndDate)
        }
    }

    private func populateForm() {
        let settings = exportVM.exportSettings
        personName = settings.personName
        firmName = settings.firmName
        selectedColumns = normalizedColumns(from: settings.selectedColumns)
        includeMonthlyTotal = settings.includeMonthlyTotal
        timeFormatOverride = settings.timeFormatOverride ?? .hour24

        switch settings.dateRange {
        case .currentMonth:
            dateRangeSelection = .currentMonth
        case .previousMonth:
            dateRangeSelection = .currentMonth
        case .nextMonth:
            dateRangeSelection = .currentMonth
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
    case custom
}
