import SwiftUI

struct DayEntrySheetView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @Environment(\.dismiss) private var dismiss

    let dates: [Date]

    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var breakHours: Int = 0
    @State private var breakMinutes: Int = 0
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @State private var selectedTemplateID: WorkTemplate.ID?
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
                    }
                    HStack {
                        Text("To")
                        Spacer()
                        DatePicker("", selection: $toTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
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

                        Button("Apply Selected Template") {
                            guard let selectedTemplate else { return }
                            focusedField = nil
                            calendarVM.applyTemplate(selectedTemplate, for: dates)
                            dismiss()
                        }
                        .disabled(selectedTemplate == nil)
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
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
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
            }
        }
    }

    private var selectedTemplate: WorkTemplate? {
        guard let selectedTemplateID else { return nil }
        return templatesVM.templates.first { $0.id == selectedTemplateID }
    }
}
