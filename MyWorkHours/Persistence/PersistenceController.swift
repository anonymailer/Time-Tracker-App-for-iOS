import CoreData
import Foundation
import SwiftUI
import UniformTypeIdentifiers

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MyWorkHours")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Save context convenience
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

struct AppDataSnapshot: Codable {
    var settings: SettingsState
    var entries: [WorkDay]
    var templates: [WorkTemplate]
    var exportSettings: ExportProfile

    static let empty = AppDataSnapshot(
        settings: SettingsState(),
        entries: [],
        templates: [],
        exportSettings: ExportProfilesViewModel().exportSettings
    )
}

enum AppDataStore {
    private static let userDefaultsKey = "app_data_snapshot"
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    static func load() -> AppDataSnapshot {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return .empty
        }

        do {
            return try decoder.decode(AppDataSnapshot.self, from: data)
        } catch {
            print("DECODE ERROR:", error)
            return .empty
            }
    }

    static func save(_ snapshot: AppDataSnapshot) {
        do {
            let data = try encoder.encode(snapshot)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            assertionFailure("Failed to save app data: \(error)")
        }
    }

    static func importBackup(from url: URL) throws -> AppDataSnapshot {
        let shouldStopAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let data = try Data(contentsOf: url)
        return try decoder.decode(AppDataSnapshot.self, from: data)
    }

    static func backupDocument(from snapshot: AppDataSnapshot) -> AppBackupDocument {
        let data = (try? encoder.encode(backupSnapshot(from: snapshot))) ?? Data()
        return AppBackupDocument(data: data)
    }

    static func autoBackup(snapshot: AppDataSnapshot) throws -> URL {
        let directoryURL = try autoBackupDirectoryURL()
        let data = try encoder.encode(backupSnapshot(from: snapshot))
        let fileURL = directoryURL
            .appendingPathComponent(autoBackupFileName, isDirectory: false)
            .appendingPathExtension("json")

        var coordinationError: NSError?
        var writeError: Error?

        NSFileCoordinator().coordinate(writingItemAt: directoryURL, error: &coordinationError) { coordinatedDirectoryURL in
            do {
                let coordinatedFileURL = coordinatedDirectoryURL
                    .appendingPathComponent(autoBackupFileName, isDirectory: false)
                    .appendingPathExtension("json")
                try data.write(to: coordinatedFileURL, options: .atomic)
            } catch {
                writeError = error
            }
        }

        if let coordinationError {
            throw coordinationError
        }

        if let writeError {
            throw writeError
        }

        return fileURL
    }

    static func autoBackupDirectoryURL() throws -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let directoryURL = documentsDirectory.appendingPathComponent("AutoBackups", isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        return directoryURL
    }

    static func fileName(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return "MyWorkHours-Backup-\(formatter.string(from: date))"
    }

    private static let autoBackupFileName = "MyWorkHours-AutoBackup"

    static func nextAutoBackupDate(after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let todayAtTen = calendar.date(
            bySettingHour: 22,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        if date < todayAtTen {
            return todayAtTen
        }

        return calendar.date(byAdding: .day, value: 1, to: todayAtTen) ?? todayAtTen
    }

    static func latestScheduledAutoBackupDate(before date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let todayAtTen = calendar.date(
            bySettingHour: 22,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        if date >= todayAtTen {
            return todayAtTen
        }

        return calendar.date(byAdding: .day, value: -1, to: todayAtTen) ?? todayAtTen
    }

    private static func backupSnapshot(from snapshot: AppDataSnapshot) -> AppDataSnapshot {
        var backupSnapshot = snapshot
        backupSnapshot.settings.installationDate = nil
        backupSnapshot.settings.installationBuildIdentifier = nil
        return backupSnapshot
    }
}

struct AppBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    private let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        self.data = data
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}
