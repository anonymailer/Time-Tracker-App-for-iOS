import SwiftUI

struct ExportProfilesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var exportVM: ExportProfilesViewModel

    let onExportProfile: (ExportProfile) -> Void
    let onCopyProfile: (ExportProfile) -> Void

    @State private var showEditSheet = false

    var body: some View {
        NavigationView {
            List {
                Section("Quick Export") {
                    Button {
                        onExportProfile(exportVM.profileUsingSettings(format: .pdf))
                        dismiss()
                    } label: {
                        quickActionRow(title: "Export PDF", systemImage: "doc.richtext")
                    }

                    Button {
                        onExportProfile(exportVM.profileUsingSettings(format: .txt))
                        dismiss()
                    } label: {
                        quickActionRow(title: "Export TXT", systemImage: "doc.text")
                    }

                    Button {
                        onExportProfile(exportVM.profileUsingSettings(format: .csv))
                        dismiss()
                    } label: {
                        quickActionRow(title: "Export CSV", systemImage: "tablecells")
                    }

                    Button {
                        onCopyProfile(exportVM.copyProfileUsingSettings)
                        dismiss()
                    } label: {
                        quickActionRow(title: "Copy Report", systemImage: "doc.on.doc")
                    }
                }
            }
            .navigationTitle("Export Report")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                ExportProfileEditView()
                    .environmentObject(exportVM)
            }
        }
    }

    @ViewBuilder
    private func quickActionRow(title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
    }
}
