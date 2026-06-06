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

enum WeekStartDay: String, CaseIterable, Codable {
    case sunday
    case monday

    var firstWeekday: Int {
        switch self {
        case .sunday:
            return 1
        case .monday:
            return 2
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
    @Published var currencyCode: String = "" {
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
    @Published var weekStartDay: WeekStartDay = .sunday {
        didSet {
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
    @Published var expectedDailyMinutes: Int = 8 * 60 {
        didSet {
            onChange?()
        }
    }
    @Published var expectedWeeklyMinutes: Int = 40 * 60 {
        didSet {
            onChange?()
        }
    }

    init(state: SettingsState = .init()) {
        let resolvedInstallationDate = state.installationDate ?? Date()
        appTheme = .system
        currencyCode = ""
        timeFormat = state.timeFormat
        weekStartDay = .sunday
        languageCode = "en"
        autoBackupEnabled = state.autoBackupEnabled
        autoBackupFolderName = state.autoBackupFolderName
        autoBackupFolderBookmark = state.autoBackupFolderBookmark
        lastAutoBackupAt = state.lastAutoBackupAt
        autoBackupConfiguredAt = state.autoBackupConfiguredAt
        installationDate = resolvedInstallationDate
        installationBuildIdentifier = state.installationBuildIdentifier
        expectedDailyMinutes = state.expectedDailyMinutes
        expectedWeeklyMinutes = state.expectedWeeklyMinutes
        DateFormatterHelper.currentTimeFormat = timeFormat
    }

    func apply(state: SettingsState) {
        let resolvedInstallationDate = state.installationDate ?? installationDate
        appTheme = .system
        currencyCode = ""
        timeFormat = state.timeFormat
        weekStartDay = .sunday
        languageCode = "en"
        autoBackupEnabled = state.autoBackupEnabled
        autoBackupFolderName = state.autoBackupFolderName
        autoBackupFolderBookmark = state.autoBackupFolderBookmark
        lastAutoBackupAt = state.lastAutoBackupAt
        autoBackupConfiguredAt = state.autoBackupConfiguredAt
        installationDate = resolvedInstallationDate
        installationBuildIdentifier = state.installationBuildIdentifier
        expectedDailyMinutes = state.expectedDailyMinutes
        expectedWeeklyMinutes = state.expectedWeeklyMinutes
    }

    var state: SettingsState {
        var state = SettingsState()
        state.appTheme = appTheme
        state.currencyCode = currencyCode
        state.timeFormat = timeFormat
        state.weekStartDay = weekStartDay
        state.languageCode = languageCode
        state.autoBackupEnabled = autoBackupEnabled
        state.autoBackupFolderName = autoBackupFolderName
        state.autoBackupFolderBookmark = autoBackupFolderBookmark
        state.lastAutoBackupAt = lastAutoBackupAt
        state.autoBackupConfiguredAt = autoBackupConfiguredAt
        state.installationDate = installationDate
        state.installationBuildIdentifier = installationBuildIdentifier
        state.expectedDailyMinutes = expectedDailyMinutes
        state.expectedWeeklyMinutes = expectedWeeklyMinutes
        return state
    }

    func resetInstallationTimer(buildIdentifier: String, date: Date = Date()) {
        installationDate = date
        installationBuildIdentifier = buildIdentifier
    }
}

struct SettingsState: Codable {
    var appTheme: AppTheme = .system
    var currencyCode: String = ""
    var timeFormat: TimeFormat = .hour24
    var weekStartDay: WeekStartDay = .sunday
    var languageCode: String = "en"
    var autoBackupEnabled: Bool = false
    var autoBackupFolderName: String? = nil
    var autoBackupFolderBookmark: Data? = nil
    var lastAutoBackupAt: Date? = nil
    var autoBackupConfiguredAt: Date? = nil
    var installationDate: Date? = nil
    var installationBuildIdentifier: String? = nil
    var expectedDailyMinutes: Int = 8 * 60
    var expectedWeeklyMinutes: Int = 40 * 60

    private enum CodingKeys: String, CodingKey {
        case appTheme
        case currencyCode
        case timeFormat
        case weekStartDay
        case languageCode
        case autoBackupEnabled
        case autoBackupFolderName
        case autoBackupFolderBookmark
        case lastAutoBackupAt
        case autoBackupConfiguredAt
        case installationDate
        case installationBuildIdentifier
        case expectedDailyMinutes
        case expectedWeeklyMinutes
    }

    init() { }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appTheme = .system
        currencyCode = ""
        timeFormat = try container.decodeIfPresent(TimeFormat.self, forKey: .timeFormat) ?? .hour24
        weekStartDay = .sunday
        languageCode = "en"
        autoBackupEnabled = try container.decodeIfPresent(Bool.self, forKey: .autoBackupEnabled) ?? false
        autoBackupFolderName = try container.decodeIfPresent(String.self, forKey: .autoBackupFolderName)
        autoBackupFolderBookmark = try container.decodeIfPresent(Data.self, forKey: .autoBackupFolderBookmark)
        lastAutoBackupAt = try container.decodeIfPresent(Date.self, forKey: .lastAutoBackupAt)
        autoBackupConfiguredAt = try container.decodeIfPresent(Date.self, forKey: .autoBackupConfiguredAt)
        installationDate = try container.decodeIfPresent(Date.self, forKey: .installationDate)
        installationBuildIdentifier = try container.decodeIfPresent(String.self, forKey: .installationBuildIdentifier)
        expectedDailyMinutes = try container.decodeIfPresent(Int.self, forKey: .expectedDailyMinutes) ?? 8 * 60
        expectedWeeklyMinutes = try container.decodeIfPresent(Int.self, forKey: .expectedWeeklyMinutes) ?? 40 * 60
    }
}
