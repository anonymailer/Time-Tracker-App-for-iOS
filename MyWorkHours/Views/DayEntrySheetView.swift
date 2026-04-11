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
    @State private var selectedTemplateID: WorkTemplate.ID?
    @State private var showingDeleteConfirmation = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case hourlyRate
        case notes
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Times")) {
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
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .focused($focusedField, equals: .notes)
                }

                Section(header: Text("Templates")) {
                    if !templatesVM.templates.isEmpty {
                        Picker("Select Template", selection: $selectedTemplateID) {
                            Text("Choose Template").tag(nil as WorkTemplate.ID?)
                            ForEach(templatesVM.templates) { template in
                                Text(template.name).tag(Optional(template.id))
                            }
                        }
                    } else {
                        Text("No templates available")
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    Button("Save") {
                        focusedField = nil
                        calendarVM.saveEntries(
                            for: dates,
                            from: fromTime,
                            to: toTime,
                            hourlyRate: hourlyRate,
                            notes: notes,
                            breakMinutes: (breakHours * 60) + breakMinutes
                        )
                        dismiss()
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
            .onChange(of: selectedTemplateID) { _, _ in
                guard let selectedTemplate else { return }
                applyTemplateToForm(selectedTemplate)
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

                selectedTemplateID = templatesVM.defaultTemplate?.id ?? templatesVM.templates.first?.id
                if !hasExistingEntries, let selectedTemplate {
                    applyTemplateToForm(selectedTemplate)
                }
            }
        }
    }

    private var selectedTemplate: WorkTemplate? {
        guard let selectedTemplateID else { return nil }
        return templatesVM.templates.first { $0.id == selectedTemplateID }
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

    private func applyTemplateToForm(_ template: WorkTemplate) {
        fromTime = template.fromTime
        toTime = template.toTime
        let components = BreakDurationFormatter.components(for: template.breakMinutes)
        breakHours = components.hours
        breakMinutes = components.minutes
        hourlyRate = String(format: "%.2f", template.hourlyRate)
        notes = template.notes
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
