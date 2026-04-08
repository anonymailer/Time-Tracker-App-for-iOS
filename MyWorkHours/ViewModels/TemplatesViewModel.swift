import Foundation
import SwiftUI
import Combine

class TemplatesViewModel: ObservableObject {
    var onChange: (() -> Void)?

    @Published var templates: [WorkTemplate] = [] {
        didSet {
            onChange?()
        }
    }

    init(templates: [WorkTemplate] = []) {
        self.templates = templates
    }

    func apply(templates: [WorkTemplate]) {
        self.templates = templates
    }

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
