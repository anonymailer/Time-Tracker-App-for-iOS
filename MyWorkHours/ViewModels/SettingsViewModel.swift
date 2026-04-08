import Foundation
import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Codable {
    case light, dark, system

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

class SettingsViewModel: ObservableObject {
    var onChange: (() -> Void)?

    @Published var appTheme: AppTheme = .system {
        didSet {
            onChange?()
        }
    }
    @Published var currencyCode: String = "$" {
        didSet {
            onChange?()
        }
    }
    @Published var timeFormat: TimeFormat = .hour24 {
        didSet {
            DateFormatterHelper.currentTimeFormat = timeFormat
            onChange?()
        }
    }
    @Published var languageCode: String = "en" {
        didSet {
            onChange?()
        }
    }
    @Published var autoBackupEnabled: Bool = false {
        didSet {
            onChange?()
        }
    }
    @Published var autoBackupFolderName: String? {
        didSet {
            onChange?()
        }
    }
    @Published var autoBackupFolderBookmark: Data? {
        didSet {
            onChange?()
        }
    }
    @Published var lastAutoBackupAt: Date? {
        didSet {
            onChange?()
        }
    }
    @Published var autoBackupConfiguredAt: Date? {
        didSet {
            onChange?()
        }
    }
    @Published var installationDate: Date {
        didSet {
            onChange?()
        }
    }
    @Published var installationBuildIdentifier: String? {
        didSet {
            onChange?()
        }
    }

    init(state: SettingsState = .init()) {
        let resolvedInstallationDate = state.installationDate ?? Date()
        appTheme = state.appTheme
        currencyCode = state.currencyCode
        timeFormat = state.timeFormat
        languageCode = state.languageCode
        autoBackupEnabled = state.autoBackupEnabled
        autoBackupFolderName = state.autoBackupFolderName
        autoBackupFolderBookmark = state.autoBackupFolderBookmark
        lastAutoBackupAt = state.lastAutoBackupAt
        autoBackupConfiguredAt = state.autoBackupConfiguredAt
        installationDate = resolvedInstallationDate
        installationBuildIdentifier = state.installationBuildIdentifier
        DateFormatterHelper.currentTimeFormat = timeFormat
    }

    func apply(state: SettingsState) {
        let resolvedInstallationDate = state.installationDate ?? installationDate
        appTheme = state.appTheme
        currencyCode = state.currencyCode
        timeFormat = state.timeFormat
        languageCode = state.languageCode
        autoBackupEnabled = state.autoBackupEnabled
        autoBackupFolderName = state.autoBackupFolderName
        autoBackupFolderBookmark = state.autoBackupFolderBookmark
        lastAutoBackupAt = state.lastAutoBackupAt
        autoBackupConfiguredAt = state.autoBackupConfiguredAt
        installationDate = resolvedInstallationDate
        installationBuildIdentifier = state.installationBuildIdentifier
    }

    var state: SettingsState {
        SettingsState(
            appTheme: appTheme,
            currencyCode: currencyCode,
            timeFormat: timeFormat,
            languageCode: languageCode,
            autoBackupEnabled: autoBackupEnabled,
            autoBackupFolderName: autoBackupFolderName,
            autoBackupFolderBookmark: autoBackupFolderBookmark,
            lastAutoBackupAt: lastAutoBackupAt,
            autoBackupConfiguredAt: autoBackupConfiguredAt,
            installationDate: installationDate,
            installationBuildIdentifier: installationBuildIdentifier
        )
    }

    func resetInstallationTimer(buildIdentifier: String, date: Date = Date()) {
        installationDate = date
        installationBuildIdentifier = buildIdentifier
    }
}

struct SettingsState: Codable {
    var appTheme: AppTheme = .system
    var currencyCode: String = "$"
    var timeFormat: TimeFormat = .hour24
    var languageCode: String = "en"
    var autoBackupEnabled: Bool = false
    var autoBackupFolderName: String? = nil
    var autoBackupFolderBookmark: Data? = nil
    var lastAutoBackupAt: Date? = nil
    var autoBackupConfiguredAt: Date? = nil
    var installationDate: Date? = nil
    var installationBuildIdentifier: String? = nil
}
