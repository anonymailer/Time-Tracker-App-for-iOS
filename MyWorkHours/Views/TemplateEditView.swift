import SwiftUI

struct TemplateEditView: View {
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @Environment(\.dismiss) private var dismiss
    @Binding var template: WorkTemplate?

    @State private var name: String = ""
    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @State private var isDefault: Bool = false
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
                    DatePicker("From", selection: $fromTime, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $toTime, displayedComponents: .hourAndMinute)
                    TextField("Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .hourlyRate)
                    TextEditor(text: $notes)
                        .frame(height: 80)
                        .focused($focusedField, equals: .notes)
                    Toggle("Default Template", isOn: $isDefault)
                }

                Section {
                    Button("Save") {
                        focusedField = nil
                        let newTemplate = WorkTemplate(
                            id: template?.id ?? UUID(),
                            name: name,
                            fromTime: fromTime,
                            toTime: toTime,
                            hourlyRate: Double(hourlyRate) ?? 0,
                            notes: notes,
                            isDefault: isDefault
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
            hourlyRate = ""
            notes = ""
            isDefault = false
            return
        }

        name = template.name
        fromTime = template.fromTime
        toTime = template.toTime
        hourlyRate = String(format: "%.2f", template.hourlyRate)
        notes = template.notes
        isDefault = template.isDefault
    }
}
