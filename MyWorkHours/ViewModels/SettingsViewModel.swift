import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var appTheme: AppTheme = .system
    @Published var currencyCode: String = "$"
    @Published var timeFormat: TimeFormat = .hour24
    @Published var languageCode: String = "en"

    enum AppTheme: String, CaseIterable {
        case light, dark, system

        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
}
