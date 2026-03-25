import SwiftUI

struct DayEntrySheetView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @Environment(\.dismiss) var dismiss

    var date: Date

    @State private var fromTime: Date = Date()
    @State private var toTime: Date = Date()
    @State private var hourlyRate: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Times")) {
                    DatePicker("From", selection: $fromTime, displayedComponents: .hourAndMinute)
                    DatePicker("To", selection: $toTime, displayedComponents: .hourAndMinute)
                    TextField("Hourly Rate", text: $hourlyRate)
                        .keyboardType(.decimalPad)
                }

                Section(header: Text("Notes")) {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }

                Section {
                    Button("Apply Default Template") {
                        calendarVM.applyDefaultTemplate(for: date, templatesVM: templatesVM)
                        dismiss()
                    }
                    Button("Save") {
                        calendarVM.saveEntry(for: date, from: fromTime, to: toTime, hourlyRate: hourlyRate, notes: notes)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Day")
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