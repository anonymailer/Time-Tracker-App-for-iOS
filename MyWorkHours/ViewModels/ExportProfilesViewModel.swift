import Foundation
import SwiftUI
import Combine

class ExportProfilesViewModel: ObservableObject {
    @Published var profiles: [ExportProfile] = []

    var defaultProfile: ExportProfile? {
        profiles.first
    }

    func saveProfile(_ profile: ExportProfile) {
        profiles.removeAll { $0.id == profile.id }
        profiles.append(profile)
    }

    func deleteProfiles(at offsets: IndexSet) {
        profiles.remove(atOffsets: offsets)
    }
}
