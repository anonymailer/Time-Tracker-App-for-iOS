import SwiftUI

struct TemplateEditView: View {
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @Binding var template: WorkTemplate?

    @State private var name: String = ""
    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @State private var isDefault: Bool = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Template Details")) {
                    TextField("Template Name", text: $name)
                    DatePicker("From", selection: $fromTime, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $toTime, displayedComponents: .hourAndMinute)
                    TextField("Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                    TextEditor(text: $notes)
                        .frame(height: 80)
                    Toggle("Default Template", isOn: $isDefault)
                }

                Section {
                    Button("Save") {
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
                    }
                    .disabled(name.isEmpty || hourlyRate.isEmpty)
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .onAppear {
                if let t = template {
                    name = t.name
                    fromTime = t.fromTime
                    toTime = t.toTime
                    hourlyRate = String(format: "%.2f", t.hourlyRate)
                    notes = t.notes
                    isDefault = t.isDefault
                }
            }
        }
    }
}