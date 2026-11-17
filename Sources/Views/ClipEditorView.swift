import SwiftUI

struct ClipEditorView: View {
    enum Mode {
        case add
        case edit(ClipItem)
    }

    let mode: Mode
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    init(mode: Mode, onSave: @escaping (String) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .add:
            _text = State(initialValue: "")
        case .edit(let item):
            _text = State(initialValue: item.content)
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextEditor(text: $text)
                    .padding(8)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding()
            }
            .navigationTitle(isEditing ? "クリップを編集" : "新規クリップを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }
}
