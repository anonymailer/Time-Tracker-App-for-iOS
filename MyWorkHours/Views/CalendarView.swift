import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @State private var selectedDate: Date = Date()
    @State private var showEntrySheet = false

    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()

                if let entry = calendarVM.entry(for: selectedDate) {
                    VStack(alignment: .leading) {
                        Text("From: \(entry.fromTimeString)")
                        Text("To: \(entry.toTimeString)")
                        Text("Hours: \(entry.totalHoursString)")
                        Text("Payout: \(String(format: "%.2f", entry.totalPayout))")
                        Text("Notes: \(entry.notes)")
                    }
                    .padding()
                } else {
                    Text("No entry for this day")
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add/Edit") {
                        showEntrySheet = true
                    }
                }
            }
            .sheet(isPresented: $showEntrySheet) {
                DayEntrySheetView(date: selectedDate)
            }
        }
    }
}