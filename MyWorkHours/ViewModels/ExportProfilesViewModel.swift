import Foundation
import SwiftUI
import Combine

class ExportProfilesViewModel: ObservableObject {
    @Published var exportSettings = ExportProfile(
        name: "Export Settings",
        selectedColumns: [.day, .timings, .hours, .payout, .notes],
        includeMonthlyTotal: true,
        dateRange: .currentMonth,
        formats: ExportFormat.allCases,
        timeFormatOverride: .hour24,
        currencyOverride: nil
    )

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
