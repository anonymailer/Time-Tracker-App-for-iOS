import SwiftUI

struct DayEntrySheetView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    let dates: [Date]

    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var breakHours: Int = 0
    @State private var breakMinutes: Int = 0
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @State private var showingCustomEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var showingTemplateApplyConfirmation = false
    @State private var pendingTemplate: WorkTemplate?
    @FocusState private var focusedField: Field?

    private enum Field {
        case hourlyRate
        case notes
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Templates")) {
                    if !templatesVM.templates.isEmpty {
                        ForEach(templatesVM.templates) { template in
                            Button {
                                focusedField = nil
                                pendingTemplate = template
                                showingTemplateApplyConfirmation = true
                            } label: {
                                HStack {
                                    Text(template.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(templateTimingSummary(template))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
                        Text("No templates available")
                            .foregroundColor(.secondary)
                    }

                    Button {
                        showingCustomEditor.toggle()
                    } label: {
                        HStack {
                            Text("Custom")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: showingCustomEditor ? "chevron.up" : "chevron.down")
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if showingCustomEditor {
                    Section(header: Text("Custom")) {
                        HStack {
                            Text("From")
                            Spacer()
                            DatePicker("", selection: $fromTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.locale, timePickerLocale)
                                .id("from-\(timePickerLocale.identifier)")
                        }

                        HStack {
                            Text("To")
                            Spacer()
                            DatePicker("", selection: $toTime, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.locale, timePickerLocale)
                                .id("to-\(timePickerLocale.identifier)")
                        }

                        HStack {
                            Text("Break Time")
                            Spacer()
                            HStack(spacing: 0) {
                                Picker("Hours", selection: $breakHours) {
                                    ForEach(0..<24, id: \.self) { hour in
                                        Text(String(format: "%02d", hour)).tag(hour)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 72, height: 100)
                                .clipped()

                                Text(":")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 4)

                                Picker("Minutes", selection: $breakMinutes) {
                                    ForEach(0..<60, id: \.self) { minute in
                                        Text(String(format: "%02d", minute)).tag(minute)
                                    }
                                }
                                .labelsHidden()
                                .frame(width: 72, height: 100)
                                .clipped()
                            }
                        }

                        TextField("Hourly Rate", text: $hourlyRate)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .hourlyRate)

                        TextEditor(text: $notes)
                            .frame(height: 80)
                            .focused($focusedField, equals: .notes)
                    }

                    Section {
                        HStack {
                            Spacer()
                            Button("Save") {
                                focusedField = nil
                                calendarVM.saveEntries(
                                    for: dates,
                                    from: fromTime,
                                    to: toTime,
                                    hourlyRate: hourlyRate,
                                    notes: notes,
                                    breakMinutes: (breakHours * 60) + breakMinutes,
                                    templateID: nil
                                )
                                dismiss()
                            }
                            Spacer()
                        }
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(dates.count > 1 ? "Edit Selected Days" : "Edit Day")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        focusedField = nil
                        dismiss()
                    }
                }
                if hasExistingEntries {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Delete") {
                            focusedField = nil
                            showingDeleteConfirmation = true
                        }
                        .foregroundColor(.red)
                    }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert(deleteConfirmationTitle, isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Yes", role: .destructive) {
                    calendarVM.deleteEntries(for: dates)
                    dismiss()
                }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .alert(templateConfirmationTitle, isPresented: $showingTemplateApplyConfirmation) {
                Button("No", role: .cancel) {
                    pendingTemplate = nil
                }
                Button("Yes") {
                    if let pendingTemplate {
                        calendarVM.applyTemplate(pendingTemplate, for: dates)
                    }
                    pendingTemplate = nil
                    dismiss()
                }
            } message: {
                Text(templateConfirmationMessage)
            }
            .onAppear {
                if dates.count == 1, let date = dates.first, let entry = calendarVM.entry(for: date) {
                    fromTime = entry.fromTime
                    toTime = entry.toTime
                    let components = BreakDurationFormatter.components(for: entry.breakMinutes)
                    breakHours = components.hours
                    breakMinutes = components.minutes
                    hourlyRate = String(format: "%.2f", entry.hourlyRate)
                    notes = entry.notes
                } else {
                    let components = BreakDurationFormatter.components(for: 0)
                    breakHours = components.hours
                    breakMinutes = components.minutes
                }
            }
        }
    }

    private var hasExistingEntries: Bool {
        dates.contains { date in
            calendarVM.entry(for: date) != nil
        }
    }

    private var deleteConfirmationTitle: String {
        dates.count > 1 ? "Delete Selected Entries?" : "Delete Entry?"
    }

    private var deleteConfirmationMessage: String {
        dates.count > 1
            ? "This will delete entries for the selected days."
            : "This will delete the entry for this day."
    }

    private var templateConfirmationTitle: String {
        dates.count > 1 ? "Apply Template to Selected Dates?" : "Apply Template to This Date?"
    }

    private var templateConfirmationMessage: String {
        dates.count > 1
            ? "This will apply the selected template to all selected dates."
            : "This will apply the selected template to this date."
    }

    private func templateTimingSummary(_ template: WorkTemplate) -> String {
        "\(timeString(template.fromTime)) - \(timeString(template.toTime))"
    }

    private func timeString(_ date: Date) -> String {
        DateFormatterHelper.timeFormatter(for: settings.timeFormat).string(from: date)
    }

    private var timePickerLocale: Locale {
        switch settings.timeFormat {
        case .hour12:
            return Locale(identifier: "en_US")
        case .hour24:
            return Locale(identifier: "en_GB")
        }
    }
}
