import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var calendarVM: CalendarViewModel
    @EnvironmentObject var templatesVM: TemplatesViewModel
    @EnvironmentObject var exportProfilesVM: ExportProfilesViewModel

    @State private var showingBackupExporter = false
    @State private var showingBackupImporter = false
    @State private var showingBackupFolderPicker = false
    @State private var backupDocument = AppDataStore.backupDocument(from: .empty)
    @State private var backupFileName = AppDataStore.fileName()
    @State private var alertMessage = ""
    @State private var showingAlert = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Theme")) {
                    Picker("App Theme", selection: $settings.appTheme) {
                        Text("Light").tag(AppTheme.light)
                        Text("Dark").tag(AppTheme.dark)
                        Text("System").tag(AppTheme.system)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Time Format")) {
                    Picker("Time Format", selection: $settings.timeFormat) {
                        Text("12-hour").tag(TimeFormat.hour12)
                        Text("24-hour").tag(TimeFormat.hour24)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }

                Section(header: Text("Currency")) {
                    TextField("Currency symbol/code", text: $settings.currencyCode)
                }

                Section(header: Text("Language")) {
                    TextField("Language code (e.g., en, es)", text: $settings.languageCode)
                }

                Section(header: Text("Backup & Restore")) {
                    Toggle("Auto Backup", isOn: autoBackupBinding)

                    if settings.autoBackupEnabled {
                        Text(settings.autoBackupFolderName ?? "No backup folder selected")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

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

                    if settings.autoBackupEnabled {
                        Text("Auto backup runs daily at 10:00 PM and saves into the selected folder.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
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
            .sheet(isPresented: $showingBackupFolderPicker) {
                BackupFolderPicker(
                    onPick: saveBackupFolder,
                    onCancel: handleFolderPickerCancellation
                )
            }
        }
    }

    private var autoBackupBinding: Binding<Bool> {
        Binding(
            get: {
                settings.autoBackupEnabled
            },
            set: { isEnabled in
                if isEnabled {
                    if settings.autoBackupFolderBookmark == nil {
                        showingBackupFolderPicker = true
                    } else {
                        settings.autoBackupConfiguredAt = Date()
                        settings.autoBackupEnabled = true
                    }
                } else {
                    settings.autoBackupEnabled = false
                    settings.autoBackupFolderName = nil
                    settings.autoBackupFolderBookmark = nil
                    settings.lastAutoBackupAt = nil
                    settings.autoBackupConfiguredAt = nil
                }
            }
        )
    }

    private var currentSnapshot: AppDataSnapshot {
        AppDataSnapshot(
            settings: settings.state,
            entries: calendarVM.entries,
            templates: templatesVM.templates,
            exportSettings: exportProfilesVM.exportSettings
        )
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

    private func saveBackupFolder(_ url: URL) {
        showingBackupFolderPicker = false

        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw CocoaError(.fileReadNoPermission)
            }
            defer {
                url.stopAccessingSecurityScopedResource()
            }

            let bookmarkData = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            settings.autoBackupFolderBookmark = bookmarkData
            settings.autoBackupFolderName = url.lastPathComponent
            settings.autoBackupConfiguredAt = Date()
            settings.autoBackupEnabled = true
        } catch {
            settings.autoBackupEnabled = false
            settings.autoBackupFolderName = nil
            settings.autoBackupFolderBookmark = nil
            settings.autoBackupConfiguredAt = nil
            showAlert(message: "Could not save backup folder: \(error.localizedDescription)")
        }
    }

    private func handleFolderPickerCancellation() {
        showingBackupFolderPicker = false
        settings.autoBackupEnabled = false
    }

    private func showAlert(message: String) {
        alertMessage = message
        showingAlert = true
    }
}
