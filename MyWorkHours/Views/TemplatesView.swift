import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject var templatesVM: TemplatesViewModel
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
                            Text("\(template.fromTimeString) - \(template.toTimeString) | \(template.hourlyRateString)/hr")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
}