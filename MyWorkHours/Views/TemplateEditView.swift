import SwiftUI

struct TemplateEditView: View {
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var template: WorkTemplate?

    @State private var name: String = ""
    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var breakHours: Int = 0
    @State private var breakMinutes: Int = 0
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case hourlyRate
        case notes
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Details")) {
                    TextField("Template Name", text: $name)
                        .focused($focusedField, equals: .name)
                    HStack {
                        Text("From")
                        Spacer()
                        DatePicker("", selection: $fromTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .environment(\.locale, timePickerLocale)
                            .id("template-from-\(timePickerLocale.identifier)")
                    }
                    HStack {
                        Text("To")
                        Spacer()
                        DatePicker("", selection: $toTime, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .datePickerStyle(.compact)
                            .environment(\.locale, timePickerLocale)
                            .id("template-to-\(timePickerLocale.identifier)")
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

                Section {
                    Button("Save") {
                        focusedField = nil
                        let newTemplate = WorkTemplate(
                            id: template?.id ?? UUID(),
                            name: name,
                            fromTime: fromTime,
                            toTime: toTime,
                            breakMinutes: (breakHours * 60) + breakMinutes,
                            hourlyRate: Double(hourlyRate) ?? 0,
                            notes: notes,
                            isDefault: template?.isDefault ?? false
                        )
                        templatesVM.saveTemplate(newTemplate)
                        template = nil
                        dismiss()
                    }
                    .disabled(name.isEmpty || hourlyRate.isEmpty)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
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
                populateForm()
            }
        }
    }

    private func populateForm() {
        guard let template else {
            name = ""
            fromTime = Date()
            toTime = Date()
            let components = BreakDurationFormatter.components(for: 0)
            breakHours = components.hours
            breakMinutes = components.minutes
            hourlyRate = ""
            notes = ""
            return
        }

        name = template.name
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
