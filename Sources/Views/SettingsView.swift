import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var manager: ClipboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var showClearConfirm = false

    private let directURLScheme = "multiclip://save"
    private let liveContainerURLScheme = "livecontainer://open-url?url=multiclip%3A%2F%2Fsave"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Button {
                        UIPasteboard.general.string = ClipboardManager.shortcutDelimiter
                        manager.showToast("区切り文字をコピーしました")
                    } label: {
                        HStack {
                            Text("区切り文字をコピー")
                            Spacer()
                            Text(ClipboardManager.shortcutDelimiter)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        UIPasteboard.general.string = liveContainerURLScheme
                        manager.showToast("LiveContainer用URLをコピーしました")
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("LiveContainer起動URLをコピー")
                            Text(liveContainerURLScheme)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        UIPasteboard.general.string = directURLScheme
                        manager.showToast("URLスキームをコピーしました")
                    } label: {
                        HStack {
                            Text("URLスキームをコピー")
                            Spacer()
                            Text(directURLScheme)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("iOSショートカット連携")
                } footer: {
                    Text("【おすすめ：画面を切り替えずに裏で保存】\nショートカットアプリで「クリップボードを取得」→「テキストファイルに追加」を選び、保存先に『このiPhone内 > LiveContainer > Data > Application > (本アプリ) > Documents > shortcut_inbox.txt』を指定してください。改行を含む文章もそのまま保存したい場合は、クリップボードの後に上の区切り文字を追加して書き込むと完璧に分割取り込みできます。\n\n【URLスキームで即保存】\n「URLを開く」アクションで上のURLを開くと、起動と同時にクリップボードを保存します。")
                }

                Section {
                    Toggle("バックグラウンド監視（実験的）", isOn: $manager.isBackgroundMonitorEnabled)
                } header: {
                    Text("バックグラウンド動作")
                } footer: {
                    Text("無音オーディオ再生を利用してバックグラウンドでのクリップボード自動取得を維持します。")
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
