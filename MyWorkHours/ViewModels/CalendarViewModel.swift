import Foundation
import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    @Published var entries: [WorkDay] = []

    func entry(for date: Date) -> WorkDay? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func saveEntry(for date: Date, from: Date, to: Date, hourlyRate: String, notes: String, breakMinutes: Int? = nil) {
        let rate = Double(hourlyRate) ?? 0
        if let index = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            entries[index].fromTime = from
            entries[index].toTime = to
            if let breakMinutes {
                entries[index].breakMinutes = breakMinutes
            }
            entries[index].hourlyRate = rate
            entries[index].notes = notes
        } else {
            let newEntry = WorkDay(date: date, fromTime: from, toTime: to, breakMinutes: breakMinutes ?? 0, hourlyRate: rate, notes: notes)
            entries.append(newEntry)
        }
    }

    func saveEntries(for dates: [Date], from: Date, to: Date, hourlyRate: String, notes: String, breakMinutes: Int? = nil) {
        dates.forEach { date in
            saveEntry(for: date, from: from, to: to, hourlyRate: hourlyRate, notes: notes, breakMinutes: breakMinutes)
        }
    }

    func applyDefaultTemplate(for date: Date, templatesVM: TemplatesViewModel) {
        guard let template = templatesVM.defaultTemplate else { return }
        saveEntry(for: date,
                  from: template.fromTime,
                  to: template.toTime,
                  hourlyRate: String(template.hourlyRate),
                  notes: template.notes)
    }

    func applyDefaultTemplate(for dates: [Date], templatesVM: TemplatesViewModel) {
        guard let template = templatesVM.defaultTemplate else { return }
        saveEntries(
            for: dates,
            from: template.fromTime,
            to: template.toTime,
            hourlyRate: String(template.hourlyRate),
            notes: template.notes
        )
    }

    func applyTemplate(_ template: WorkTemplate, for dates: [Date]) {
        saveEntries(
            for: dates,
            from: template.fromTime,
            to: template.toTime,
            hourlyRate: String(template.hourlyRate),
            notes: template.notes,
            breakMinutes: template.breakMinutes
        )
    }
}
