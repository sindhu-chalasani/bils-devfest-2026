import Foundation

struct Preset: Identifiable, Codable {
    let id: UUID
    var name: String
    var phone: String

    init(id: UUID = UUID(), name: String, phone: String) {
        self.id = id
        self.name = name
        self.phone = phone
    }
}

class PresetStore: ObservableObject {
    static let shared = PresetStore()

    @Published var presets: [Preset] = [
        Preset(name: "Alex", phone: "555-111-2222"),
        Preset(name: "Sam", phone: "555-333-4444"),
    ]

    func add(_ preset: Preset) {
        DispatchQueue.main.async {
            self.presets.append(preset)
        }
    }

    func remove(at offsets: IndexSet) {
        DispatchQueue.main.async {
            self.presets.remove(atOffsets: offsets)
        }
    }
}
