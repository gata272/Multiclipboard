import SwiftUI

struct ContentView: View {
    @EnvironmentObject var manager: ClipboardManager
    @State private var isShowingAddSheet = false
    @State private var editingItem: ClipItem? = nil
    @State private var isShowingSettings = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    categoryPicker
                    clipList
                }

                if let toast = manager.toastMessage {
                    toastBanner(message: toast)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 16)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: manager.toastMessage)
            .navigationTitle("MultiClip")
            .searchable(text: $manager.searchText, prompt: "履歴を検索...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        manager.importShortcutInbox()
                        manager.captureCurrentPasteboard(force: true, showFeedback: true)
                    } label: {
                        Image(systemName: "doc.on.clipboard")
                    }
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                ClipEditorView(mode: .add) { text in
                    manager.addClip(text, showFeedback: true)
                }
            }
            .sheet(item: $editingItem) { item in
                ClipEditorView(mode: .edit(item)) { updatedText in
                    manager.updateClip(item, newContent: updatedText)
                }
            }
            .sheet(isPresented: $isShowingSettings) {
                SettingsView()
            }
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ClipCategory.allCases) { category in
                    Button {
                        manager.selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                manager.selectedCategory == category
                                    ? Color.accentColor
                                    : Color(.secondarySystemBackground)
                            )
                            .foregroundColor(
                                manager.selectedCategory == category
                                    ? .white
                                    : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
    }

    private var clipList: some View {
        Group {
            if manager.filteredItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clipboard")
                        .font(.system(size: 44))
                        .foregroundColor(.secondary)
                    Text("クリップ履歴がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("他のアプリでテキストをコピーして戻るか、\niOSショートカットから保存できます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                List {
                    ForEach(manager.filteredItems) { item in
                        ClipRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                manager.copyToPasteboard(item)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    manager.togglePin(item)
                                } label: {
                                    Label(
                                        item.isPinned ? "解除" : "ピン留め",
                                        systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill"
                                    )
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    manager.deleteClip(item)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                                Button {
                                    editingItem = item
                                } label: {
                                    Label("編集", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func toastBanner(message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }
}

struct ClipRowView: View {
    let item: ClipItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 6) {
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
                if item.isURL {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 2)
                }
                Text(item.content)
                    .font(.body)
                    .lineLimit(4)
                    .foregroundColor(.primary)
            }

            HStack {
                Text(item.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(item.content.count)文字")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
