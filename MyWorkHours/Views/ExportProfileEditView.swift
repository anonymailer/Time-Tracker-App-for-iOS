import SwiftUI

struct ExportProfileEditView: View {
    @EnvironmentObject var exportVM: ExportProfilesViewModel
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var settings: SettingsViewModel

    @Binding var profile: ExportProfile?

    @State private var name: String = ""
    @State private var selectedColumns: [ExportColumn] = ExportColumn.allCases
    @State private var includeMonthlyTotal: Bool = true
    @State private var formats: [ExportFormat] = [.pdf]
    @State private var dateRange: ExportDateRange = .currentMonth
    @State private var timeFormatOverride: TimeFormat? = nil
    @State private var currencyOverride: String? = nil

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Name")) {
                    TextField("Name", text: $name)
                }

                Section(header: Text("Columns")) {
                    ForEach(ExportColumn.allCases, id: \.self) { column in
                        Toggle(column.rawValue.capitalized, isOn: columnBinding(for: column))
                    }
                }

                Section(header: Text("Formats")) {
                    ForEach(ExportFormat.allCases, id: \.self) { format in
                        Toggle(format.rawValue.uppercased(), isOn: formatBinding(for: format))
                    }
                }

                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $dateRange) {
                        Text("Current Month").tag(ExportDateRange.currentMonth)
                    }
                }

                Section {
                    Toggle("Include Monthly Total", isOn: $includeMonthlyTotal)
                }

                Section(header: Text("Overrides")) {
                    Picker("Time Format", selection: timeFormatBinding) {
                        Text("12-hour").tag(TimeFormat.hour12)
                        Text("24-hour").tag(TimeFormat.hour24)
                    }
                    TextField("Currency Override", text: currencyBinding)
                }

                Section {
                    Button("Save") {
                        let newProfile = ExportProfile(
                            id: profile?.id ?? UUID(),
                            name: name,
                            selectedColumns: selectedColumns,
                            includeMonthlyTotal: includeMonthlyTotal,
                            dateRange: dateRange,
                            formats: formats,
                            timeFormatOverride: timeFormatOverride,
                            currencyOverride: currencyOverride
                        )
                        exportVM.saveProfile(newProfile)
                        profile = nil
                    }
                    .disabled(name.isEmpty || formats.isEmpty)
                }
            }
            .navigationTitle(profile == nil ? "New Profile" : "Edit Profile")
            .onAppear {
                if let p = profile {
                    name = p.name
                    selectedColumns = p.selectedColumns
                    includeMonthlyTotal = p.includeMonthlyTotal
                    formats = p.formats
                    dateRange = p.dateRange
                    timeFormatOverride = p.timeFormatOverride
                    currencyOverride = p.currencyOverride
                }
            }
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

    private func formatBinding(for format: ExportFormat) -> Binding<Bool> {
        Binding(
            get: { formats.contains(format) },
            set: { isSelected in
                if isSelected {
                    if !formats.contains(format) {
                        formats.append(format)
                    }
                } else {
                    formats.removeAll { $0 == format }
                }
            }
        )
    }

    private var timeFormatBinding: Binding<TimeFormat> {
        Binding(
            get: { timeFormatOverride ?? .hour24 },
            set: { timeFormatOverride = $0 }
        )
    }

    private var currencyBinding: Binding<String> {
        Binding(
            get: { currencyOverride ?? "" },
            set: { currencyOverride = $0.isEmpty ? nil : $0 }
        )
    }
}
