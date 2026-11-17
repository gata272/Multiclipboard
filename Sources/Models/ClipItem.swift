import Foundation

enum ClipCategory: String, Codable, CaseIterable, Identifiable {
    case all = "すべて"
    case pinned = "ピン留め"
    case url = "URL"
    case text = "テキスト"

    var id: String { rawValue }
}

struct ClipItem: Identifiable, Codable, Equatable {
    let id: UUID
    var content: String
    var createdAt: Date
    var isPinned: Bool
    var isURL: Bool

    init(id: UUID = UUID(), content: String, createdAt: Date = Date(), isPinned: Bool = false) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.isURL = ClipItem.detectURL(in: content)
    }

    static func detectURL(in text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              (scheme == "http" || scheme == "https"),
              url.host != nil else {
            return false
        }
        return true
    }

    var previewText: String {
        content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
