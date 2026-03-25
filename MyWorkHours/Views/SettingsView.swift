import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settings: SettingsViewModel

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Theme")) {
                    Picker("App Theme", selection: $settings.appTheme) {
                        Text("Light").tag(SettingsViewModel.AppTheme.light)
                        Text("Dark").tag(SettingsViewModel.AppTheme.dark)
                        Text("System").tag(SettingsViewModel.AppTheme.system)
                    }.pickerStyle(SegmentedPickerStyle())
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
            }
            .navigationTitle("Settings")
        }
    }
}