import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var exportProfilesVM: ExportProfilesViewModel

    @State private var showingBackupExporter = false
    @State private var showingBackupImporter = false
    @State private var backupDocument = AppDataStore.backupDocument(from: .empty)
    @State private var backupFileName = AppDataStore.fileName()
    @State private var alertMessage = ""
    @State private var showingAlert = false
    @State private var bulkHourlyRate = ""
    @State private var showingBulkRateConfirmation = false
    @FocusState private var isBulkHourlyRateFocused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Time Format")) {
                    Picker("Time Format", selection: $settings.timeFormat) {
                        Text("12-hour").tag(TimeFormat.hour12)
                        Text("24-hour").tag(TimeFormat.hour24)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Backup & Restore")) {
                    Text("Automatic backup runs every day at 10:00 PM and saves inside the app backup folder.")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text(autoBackupPathText)
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Button("Create Backup") {
                        backupDocument = AppDataStore.backupDocument(from: currentSnapshot)
                        backupFileName = AppDataStore.fileName()
                        showingBackupExporter = true
                    }

                    Button("Import Backup") {
                        showingBackupImporter = true
                    }

                    Text("Importing a backup replaces all saved work entries, templates, export settings, and app settings.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Data Management")) {
                    TextField("Update all existing entries hourly rate", text: $bulkHourlyRate)
                        .keyboardType(.decimalPad)
                        .focused($isBulkHourlyRateFocused)

                    Button("Apply to Existing Entries") {
                        isBulkHourlyRateFocused = false
                        showingBulkRateConfirmation = true
                    }
                    .disabled(bulkHourlyRate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || calendarVM.entries.isEmpty)

                    Text("This updates hourly rate for all existing saved entries only. Future entries and templates are not changed.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .fileExporter(
                isPresented: $showingBackupExporter,
                document: backupDocument,
                contentType: .json,
                defaultFilename: backupFileName
            ) { result in
                switch result {
                case .success:
                    showAlert(message: "Backup saved successfully.")
                case let .failure(error):
                    showAlert(message: "Backup failed: \(error.localizedDescription)")
                }
            }
            .fileImporter(
                isPresented: $showingBackupImporter,
                allowedContentTypes: [.json]
            ) { result in
                switch result {
                case let .success(url):
                    importBackup(from: url)
                case let .failure(error):
                    showAlert(message: "Import failed: \(error.localizedDescription)")
                }
            }
            .alert("Backup & Restore", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Update Existing Entries?", isPresented: $showingBulkRateConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Apply") {
                    applyBulkHourlyRate()
                }
            } message: {
                Text("This will update the hourly rate for all existing saved entries.")
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isBulkHourlyRateFocused = false
                    }
                }
            }
        }
    }

    private var currentSnapshot: AppDataSnapshot {
        AppDataSnapshot(
            settings: settings.state,
            entries: calendarVM.entries,
            templates: templatesVM.templates,
            exportSettings: exportProfilesVM.exportSettings
        )
    }

    private var autoBackupPathText: String {
        let path = (try? AppDataStore.autoBackupDirectoryURL().path()) ?? "Unavailable"
        return "Path: \(path)"
    }

    private func importBackup(from url: URL) {
        do {
            let snapshot = try AppDataStore.importBackup(from: url)
            apply(snapshot: snapshot)
            showAlert(message: "Backup imported successfully.")
        } catch {
            showAlert(message: "Import failed: \(error.localizedDescription)")
        }
    }

    private func apply(snapshot: AppDataSnapshot) {
        settings.apply(state: snapshot.settings)
        calendarVM.apply(entries: snapshot.entries)
        templatesVM.apply(templates: snapshot.templates)
        exportProfilesVM.apply(exportSettings: snapshot.exportSettings)
        AppDataStore.save(snapshot)
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }

    private func applyBulkHourlyRate() {
        let parsedRate = HourlyRateParser.value(from: bulkHourlyRate)
        calendarVM.updateAllExistingEntriesHourlyRate(to: parsedRate)
        bulkHourlyRate = String(format: "%.2f", parsedRate)
        showAlert(message: "Updated hourly rate for all existing entries.")
    }
}
