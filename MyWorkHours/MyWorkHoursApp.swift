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
    let persistenceController = PersistenceController.shared
    @StateObject private var settings = SettingsViewModel()
    @StateObject private var calendarVM = CalendarViewModel()
    @StateObject private var templatesVM = TemplatesViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(settings)
                .environmentObject(calendarVM)
                .environmentObject(templatesVM)
        }
    }
}
