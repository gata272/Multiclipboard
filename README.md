# MultiClip for LiveContainer

LiveContainer上で動作するiOS向けマルチクリップボード管理アプリ（SwiftUI製）のGitHubリポジトリ構成一式です。
iOSの「ショートカット」アプリと連携し、**背面タップ**や**アクションボタン**から任意のタイミングでクリップボードを保存できます。

## 主な機能
- **iOSショートカット完全連携（2通りの保存方式に対応）**:
  1. **ファイル追記方式（画面切り替えなし・完全バックグラウンド保存）**:
     ショートカットの「テキストファイルに追加」で `Documents/shortcut_inbox.txt` に書き込むだけで、他のアプリを閉じずに裏側で何件でもストック可能。MultiClipを開いた瞬間に自動取り込みされます。
  2. **URLスキーム方式（ワンタップ即保存）**:
     `livecontainer://open-url?url=multiclip%3A%2F%2Fsave`（または `multiclip://save`）をショートカットから開くと、アプリ起動と同時に現在のクリップボードを保存します。
- **クリップボード自動取得**: アプリ復帰時に最新のクリップボードを自動保存
- **バックグラウンド監視モード（オプション）**: 無音オーディオセッション（`UIBackgroundModes: audio`）を用いた自動監視トグル搭載
- **ワンタップコピー・ピン留め・編集・検索・カテゴリフィルタ**: よく使う定型文のピン留め固定、内容の編集、キーワード検索、`すべて / ピン留め / URL / テキスト` フィルタに対応

## GitHub Actionsでの `.ipa` ビルド手順
1. GitHubで新しいリポジトリを作成し、このフォルダの中身をすべてプッシュします。
2. リポジトリの **Actions** タブを開くと、`Build Unsigned IPA for LiveContainer` ワークフローが自動実行されます。
3. 完了後、**Artifacts** から `MultiClipboard-IPA` をダウンロードして解凍すると `MultiClipboard.ipa` が取得できます。
4. iPhoneの **LiveContainer** に `MultiClipboard.ipa` をインポートして起動してください。
