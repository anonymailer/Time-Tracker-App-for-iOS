import SwiftUI

struct ExportProfileEditView: View {
    enum Mode {
        case profile
        case exportSettings
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var exportVM: ExportProfilesViewModel

    @Binding var profile: ExportProfile?
    let mode: Mode

    @State private var name: String = ""
    @State private var selectedColumns: [ExportColumn] = ExportColumn.allCases
    @State private var includeMonthlyTotal: Bool = true
    @State private var dateRangeSelection: ExportRangeSelection = .currentMonth
    @State private var customStartDate: Date = Date()
    @State private var customEndDate: Date = Date()
    @State private var timeFormatOverride: TimeFormat = .hour24

    var body: some View {
        NavigationView {
            Form {
                if mode == .profile {
                    Section(header: Text("Profile Name")) {
                        TextField("Name", text: $name)
                    }
                }

                Section(header: Text("Columns")) {
                    ForEach(ExportColumn.allCases, id: \.self) { column in
                        Toggle(column.rawValue.capitalized, isOn: columnBinding(for: column))
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
                        let savedProfile = ExportProfile(
                            id: profile?.id ?? UUID(),
                            name: mode == .exportSettings ? "Export Settings" : name,
                            selectedColumns: selectedColumns,
                            includeMonthlyTotal: includeMonthlyTotal,
                            dateRange: resolvedDateRange,
                            formats: mode == .exportSettings ? ExportFormat.allCases : (profile?.formats ?? [.pdf]),
                            timeFormatOverride: timeFormatOverride,
                            currencyOverride: nil
                        )

                        if mode == .exportSettings {
                            exportVM.saveExportSettings(savedProfile)
                        } else {
                            exportVM.saveProfile(savedProfile)
                            profile = nil
                        }
                        dismiss()
                    }
                    .disabled(mode == .profile && name.isEmpty)
                }
            }
            .navigationTitle(mode == .exportSettings ? "Export Settings" : (profile == nil ? "New Profile" : "Edit Profile"))
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
        let sourceProfile: ExportProfile
        switch mode {
        case .profile:
            sourceProfile = profile ?? ExportProfile(name: "")
        case .exportSettings:
            sourceProfile = exportVM.exportSettings
        }

        name = sourceProfile.name == "Export Settings" ? "" : sourceProfile.name
        selectedColumns = sourceProfile.selectedColumns
        includeMonthlyTotal = sourceProfile.includeMonthlyTotal
        timeFormatOverride = sourceProfile.timeFormatOverride ?? .hour24

        switch sourceProfile.dateRange {
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
                if isSelected {
                    if !selectedColumns.contains(column) {
                        selectedColumns.append(column)
                    }
                } else {
                    selectedColumns.removeAll { $0 == column }
                }
            }
        )
    }
}

private enum ExportRangeSelection: Hashable {
    case currentMonth
    case previousMonth
    case nextMonth
    case custom
}
