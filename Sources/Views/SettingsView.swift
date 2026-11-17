import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var manager: ClipboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("バックグラウンド監視（実験的）", isOn: $manager.isBackgroundMonitorEnabled)
                } header: {
                    Text("バックグラウンド動作")
                } footer: {
                    Text("無音オーディオ再生を利用してバックグラウンドでのクリップボード自動取得を維持します。バッテリー消費がわずかに増える場合があります。iOS 16以降の仕様により、他アプリからの自動読み取り時にシステム許可ダイアログが表示されることがあります。")
                }

                Section {
                    Picker("最大保存件数", selection: $manager.maxHistoryCount) {
                        Text("50件").tag(50)
                        Text("100件").tag(100)
                        Text("300件").tag(300)
                        Text("500件").tag(500)
                    }
                } header: {
                    Text("履歴管理")
                } footer: {
                    Text("ピン留めされたアイテムは上限件数のカウント対象外となり、自動削除されません。")
                }

                Section {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Text("ピン留め以外の履歴をすべて削除")
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "ピン留めされていない履歴をすべて削除しますか？",
                isPresented: $showClearConfirm,
                titleVisibility: .visible
            ) {
                Button("削除する", role: .destructive) {
                    manager.clearUnpinned()
                }
                Button("キャンセル", role: .cancel) {}
            }
        }
    }
}
