import Foundation
import SwiftUI
import Combine

class ExportProfilesViewModel: ObservableObject {
    var onChange: (() -> Void)?

    @Published var exportSettings: ExportProfile {
        didSet {
            onChange?()
        }
    }

    init(exportSettings: ExportProfile = ExportProfile(
        name: "Export Settings",
        personName: "",
        firmName: "",
        reportPeriodTitle: nil,
        selectedColumns: [.day, .timings, .hours, .payout, .notes],
        includeMonthlyTotal: true,
        dateRange: .currentMonth,
        formats: ExportFormat.allCases,
        timeFormatOverride: .hour24,
        currencyOverride: nil
    )) {
        self.exportSettings = exportSettings
    }

    func apply(exportSettings: ExportProfile) {
        self.exportSettings = exportSettings
    }

    func saveExportSettings(_ settings: ExportProfile) {
        exportSettings = settings
    }

    func profileUsingSettings(format: ExportFormat) -> ExportProfile {
        var profile = exportSettings
        profile.name = "Quick \(format.rawValue.uppercased())"
        profile.formats = [format]
        return profile
    }

    var copyProfileUsingSettings: ExportProfile {
        var profile = exportSettings
        profile.name = "Quick Copy"
        profile.formats = [.txt]
        return profile
    }
}
