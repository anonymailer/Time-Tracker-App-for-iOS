import Foundation
import SwiftUI
import Combine

class TemplatesViewModel: ObservableObject {
    @Published var templates: [WorkTemplate] = []

    func saveTemplate(_ template: WorkTemplate) {
        templates.removeAll { $0.id == template.id }
        if template.isDefault {
            templates.indices.forEach { templates[$0].isDefault = false }
        }
        templates.append(template)
    }

    func deleteTemplates(at offsets: IndexSet) {
        templates.remove(atOffsets: offsets)
    }

    var defaultTemplate: WorkTemplate? {
        templates.first(where: { $0.isDefault })
    }
}
