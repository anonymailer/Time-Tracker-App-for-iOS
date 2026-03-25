import SwiftUI

struct ExportProfilesView: View {
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var exportVM: ExportProfilesViewModel

    @State private var editingProfile: ExportProfile? = nil
    @State private var showEditSheet = false

    var body: some View {
        NavigationView {
            List {
                ForEach(exportVM.profiles) { profile in
                    HStack {
                        Text(profile.name)
                        Spacer()
                        if profile.id == exportVM.defaultProfile?.id {
                            Image(systemName: "star.fill").foregroundColor(.yellow)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingProfile = profile
                        showEditSheet = true
                    }
                }
                .onDelete { indexSet in
                    exportVM.deleteProfiles(at: indexSet)
                }
            }
            .navigationTitle("Export Profiles")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        editingProfile = nil
                        showEditSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                ExportProfileEditView(profile: $editingProfile)
                    .environmentObject(exportVM)
                    .environmentObject(calendarVM)
                    .environmentObject(settings)
            }
        }
    }
}