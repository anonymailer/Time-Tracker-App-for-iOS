import SwiftUI

struct ContentView: View {
    @EnvironmentObject var settings: SettingsViewModel
    @EnvironmentObject var calendarVM: CalendarViewModel

    var body: some View {
        TabView {
            CalendarView()
                .tabItem { Label("Calendar", systemImage: "calendar") }

            OverviewView()
                .tabItem { Label("Overview", systemImage: "chart.bar.doc.horizontal") }

            ReportsView()
                .tabItem { Label("Reports", systemImage: "doc.plaintext") }

            TemplatesView()
                .tabItem { Label("Templates", systemImage: "square.grid.2x2") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .id("\(settings.timeFormat.rawValue)-\(settings.weekStartDay.rawValue)")
    }
}
