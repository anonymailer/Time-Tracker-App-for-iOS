//
//  MyWorkHoursApp.swift
//  MyWorkHours
//
//  Created by Sino Thomas on 25/03/2026.
//

import SwiftUI
import CoreData

@main
struct MyWorkHoursApp: App {
    @Environment(\.scenePhase) private var scenePhase

    let persistenceController = PersistenceController.shared
    @StateObject private var settings: SettingsViewModel
    @StateObject private var calendarVM: CalendarViewModel
    @StateObject private var templatesVM: TemplatesViewModel
    @StateObject private var exportProfilesVM: ExportProfilesViewModel
    @State private var showLaunchAnimation = true
    @State private var autoBackupTimer: Timer?

    init() {
        let savedState = AppDataStore.load()
        let settingsViewModel = SettingsViewModel(state: savedState.settings)
        let calendarViewModel = CalendarViewModel(entries: savedState.entries)
        let templatesViewModel = TemplatesViewModel(templates: savedState.templates)
        let exportProfilesViewModel = ExportProfilesViewModel(exportSettings: savedState.exportSettings)
        let currentBuildIdentifier = Self.currentInstallationFingerprint

        if settingsViewModel.installationBuildIdentifier != currentBuildIdentifier {
            settingsViewModel.resetInstallationTimer(buildIdentifier: currentBuildIdentifier)
        }

        let persistState = {
            AppDataStore.save(
                AppDataSnapshot(
                    settings: settingsViewModel.state,
                    entries: calendarViewModel.entries,
                    templates: templatesViewModel.templates,
                    exportSettings: exportProfilesViewModel.exportSettings
                )
            )
        }

        settingsViewModel.onChange = persistState
        calendarViewModel.onChange = persistState
        templatesViewModel.onChange = persistState
        exportProfilesViewModel.onChange = persistState

        _settings = StateObject(wrappedValue: settingsViewModel)
        _calendarVM = StateObject(wrappedValue: calendarViewModel)
        _templatesVM = StateObject(wrappedValue: templatesViewModel)
        _exportProfilesVM = StateObject(wrappedValue: exportProfilesViewModel)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .id(settings.timeFormat)
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(settings)
                    .environmentObject(calendarVM)
                    .environmentObject(templatesVM)
                    .environmentObject(exportProfilesVM)

                if showLaunchAnimation {
                    AppLaunchAnimationView()
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                        .zIndex(1)
                }
            }
            .preferredColorScheme(settings.appTheme.colorScheme)
            .onAppear {
                configureAutoBackupTimer()
                performAutoBackupIfNeeded()
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    configureAutoBackupTimer()
                    performAutoBackupIfNeeded()
                }
            }
            .onChange(of: settings.autoBackupEnabled) { _, _ in
                configureAutoBackupTimer()
            }
            .onChange(of: settings.autoBackupFolderBookmark) { _, _ in
                configureAutoBackupTimer()
            }
            .task {
                guard showLaunchAnimation else { return }
                try? await Task.sleep(for: .seconds(3.0))
                withAnimation(.easeInOut(duration: 0.45)) {
                    showLaunchAnimation = false
                }
            }
        }
    }

    private static var currentInstallationFingerprint: String {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        let shortVersion = (infoDictionary["CFBundleShortVersionString"] as? String) ?? "0"
        let buildNumber = (infoDictionary["CFBundleVersion"] as? String) ?? "0"
        let resourceValues = try? Bundle.main.bundleURL.resourceValues(forKeys: [.contentModificationDateKey])
        let modificationDate = resourceValues?.contentModificationDate?.timeIntervalSince1970 ?? 0
        return "\(shortVersion)-\(buildNumber)-\(Int(modificationDate))"
    }

    private var currentSnapshot: AppDataSnapshot {
        AppDataSnapshot(
            settings: settings.state,
            entries: calendarVM.entries,
            templates: templatesVM.templates,
            exportSettings: exportProfilesVM.exportSettings
        )
    }

    private func configureAutoBackupTimer() {
        autoBackupTimer?.invalidate()
        autoBackupTimer = nil

        let nextDate = AppDataStore.nextAutoBackupDate()
        let interval = max(nextDate.timeIntervalSinceNow, 1)

        autoBackupTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in
            performAutoBackupIfNeeded()
            configureAutoBackupTimer()
        }
    }

    private func performAutoBackupIfNeeded() {
        let now = Date()
        let scheduledBackupDate = AppDataStore.latestScheduledAutoBackupDate(before: now)

        if let lastAutoBackupAt = settings.lastAutoBackupAt,
           lastAutoBackupAt >= scheduledBackupDate {
            return
        }

        do {
            _ = try AppDataStore.autoBackup(snapshot: currentSnapshot)
            settings.lastAutoBackupAt = scheduledBackupDate
        } catch {
            assertionFailure("Auto backup failed: \(error)")
        }
    }
}
