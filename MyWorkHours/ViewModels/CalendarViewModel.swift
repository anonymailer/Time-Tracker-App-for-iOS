import Foundation
import SwiftUI
import Combine

class CalendarViewModel: ObservableObject {
    var onChange: (() -> Void)?

    @Published var entries: [WorkDay] = [] {
        didSet {
            onChange?()
        }
    }

    init(entries: [WorkDay] = []) {
        self.entries = entries
    }

    func apply(entries: [WorkDay]) {
        self.entries = entries
    }

    func entry(for date: Date) -> WorkDay? {
        entries.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
    }

    func saveEntry(for date: Date, from: Date, to: Date, hourlyRate: String, notes: String, breakMinutes: Int? = nil, templateID: UUID? = nil) {
        let rate = HourlyRateParser.value(from: hourlyRate)
        if let index = entries.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
            entries[index].fromTime = from
            entries[index].toTime = to
            if let breakMinutes {
                entries[index].breakMinutes = breakMinutes
            }
            entries[index].hourlyRate = rate
            entries[index].notes = notes
            if let templateID {
                entries[index].templateID = templateID
            }
        } else {
            let newEntry = WorkDay(date: date, fromTime: from, toTime: to, breakMinutes: breakMinutes ?? 0, hourlyRate: rate, notes: notes, templateID: templateID)
            entries.append(newEntry)
        }
    }

    func saveEntries(for dates: [Date], from: Date, to: Date, hourlyRate: String, notes: String, breakMinutes: Int? = nil, templateID: UUID? = nil) {
        dates.forEach { date in
            saveEntry(for: date, from: from, to: to, hourlyRate: hourlyRate, notes: notes, breakMinutes: breakMinutes, templateID: templateID)
        }
    }

    func deleteEntries(for dates: [Date]) {
        entries.removeAll { entry in
            dates.contains { date in
                Calendar.current.isDate(entry.date, inSameDayAs: date)
            }
        }
    }

    func updateAllExistingEntriesHourlyRate(to hourlyRate: Double) {
        for index in entries.indices {
            entries[index].hourlyRate = hourlyRate
        }
    }

    func applyDefaultTemplate(for date: Date, templatesVM: TemplatesViewModel) {
        guard let template = templatesVM.defaultTemplate else { return }
        saveEntry(for: date,
                  from: template.fromTime,
                  to: template.toTime,
                  hourlyRate: String(template.hourlyRate),
                  notes: template.notes,
                  breakMinutes: template.breakMinutes,
                  templateID: template.id)
    }

    func applyDefaultTemplate(for dates: [Date], templatesVM: TemplatesViewModel) {
        guard let template = templatesVM.defaultTemplate else { return }
        saveEntries(
            for: dates,
            from: template.fromTime,
            to: template.toTime,
            hourlyRate: String(template.hourlyRate),
            notes: template.notes,
            breakMinutes: template.breakMinutes,
            templateID: template.id
        )
    }

    func applyTemplate(_ template: WorkTemplate, for dates: [Date]) {
        saveEntries(
            for: dates,
            from: template.fromTime,
            to: template.toTime,
            hourlyRate: String(template.hourlyRate),
            notes: template.notes,
            breakMinutes: template.breakMinutes,
            templateID: template.id
        )
    }

    func countEntries(usingTemplateID templateID: UUID) -> Int {
        entries.filter { $0.templateID == templateID }.count
    }

    func countEntries(matching template: WorkTemplate) -> Int {
        entries.filter { entryMatchesTemplate($0, template: template) }.count
    }

    func updateEntries(usingTemplate template: WorkTemplate, previousTemplate: WorkTemplate? = nil) {
        for index in entries.indices {
            let shouldUpdate: Bool

            if entries[index].templateID == template.id {
                shouldUpdate = true
            } else if let previousTemplate {
                shouldUpdate = entryMatchesTemplate(entries[index], template: previousTemplate)
            } else {
                shouldUpdate = false
            }

            guard shouldUpdate else { continue }

            entries[index].fromTime = template.fromTime
            entries[index].toTime = template.toTime
            entries[index].breakMinutes = template.breakMinutes
            entries[index].hourlyRate = template.hourlyRate
            entries[index].notes = template.notes
            entries[index].templateID = template.id
        }
    }

    private func entryMatchesTemplate(_ entry: WorkDay, template: WorkTemplate) -> Bool {
        matchesTimeOfDay(entry.fromTime, template.fromTime) &&
        matchesTimeOfDay(entry.toTime, template.toTime) &&
        entry.breakMinutes == template.breakMinutes &&
        abs(entry.hourlyRate - template.hourlyRate) < 0.0001 &&
        entry.notes == template.notes
    }

    private func matchesTimeOfDay(_ lhs: Date, _ rhs: Date) -> Bool {
        let calendar = Calendar.current
        let lhsComponents = calendar.dateComponents([.hour, .minute], from: lhs)
        let rhsComponents = calendar.dateComponents([.hour, .minute], from: rhs)
        return lhsComponents.hour == rhsComponents.hour && lhsComponents.minute == rhsComponents.minute
    }
}
