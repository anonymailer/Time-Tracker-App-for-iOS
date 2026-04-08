import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @State private var showEditSheet = false
    @State private var editingTemplate: WorkTemplate? = nil

    var body: some View {
        NavigationView {
            List {
                ForEach(templatesVM.templates) { template in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(template.name)
                                .font(.headline)
                            Text(templateSummary(template))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            if !template.notes.isEmpty {
                                Text(template.notes)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        Spacer()
                        if template.isDefault {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingTemplate = template
                        showEditSheet = true
                    }
                }
                .onDelete { indexSet in
                    templatesVM.deleteTemplates(at: indexSet)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingTemplate = nil
                        showEditSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                TemplateEditView(template: $editingTemplate)
                    .environmentObject(templatesVM)
            }
        }
    }

    private func templateSummary(_ template: WorkTemplate) -> String {
        let breakSummary = template.breakMinutes > 0 ? " | Break \(template.breakMinutes)m" : ""
        return "\(timeString(template.fromTime)) - \(timeString(template.displayedToTime))\(breakSummary) | \(template.hourlyRateString)/hr"
    }

    private func timeString(_ date: Date) -> String {
        DateFormatterHelper.timeFormatter(for: settings.timeFormat).string(from: date)
    }
}
