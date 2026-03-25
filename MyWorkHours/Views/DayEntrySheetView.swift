import SwiftUI

struct DayEntrySheetView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @Environment(\.dismiss) private var dismiss

    var date: Date

    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case hourlyRate
        case notes
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Times")) {
                    DatePicker("From", selection: $fromTime, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $toTime, displayedComponents: .hourAndMinute)
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
                    Button("Apply Default Template") {
                        focusedField = nil
                        calendarVM.applyDefaultTemplate(for: date, templatesVM: templatesVM)
                        dismiss()
                    }
                    Button("Save") {
                        focusedField = nil
                        calendarVM.saveEntry(for: date, from: fromTime, to: toTime, hourlyRate: hourlyRate, notes: notes)
                        dismiss()
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Day")
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
                if let entry = calendarVM.entry(for: date) {
                    fromTime = entry.fromTime
                    toTime = entry.toTime
                    hourlyRate = String(format: "%.2f", entry.hourlyRate)
                    notes = entry.notes
                }
            }
        }
    }
}
