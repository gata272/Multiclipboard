# MultiClip for LiveContainer

LiveContainer上で動作するiOS向けマルチクリップボード管理アプリ（SwiftUI製）のGitHubリポジトリ構成一式です。
GitHub Actionsを用いてMac環境なしで未署名 `.ipa` を自動ビルドできます。

## 主な機能
- **クリップボード自動取得**: アプリを開いた際（フォアグラウンド復帰時）に最新のクリップボードを自動保存
- **バックグラウンド監視モード（オプション）**: 無音オーディオセッション（`UIBackgroundModes: audio`）を用いたバックグラウンド監視トグル搭載
- **ワンタップコピー**: リストの項目をタップするだけで即座にクリップボードへ再コピー
- **ピン留め・編集・検索・カテゴリフィルタ**: よく使う定型文のピン留め固定、内容の編集、キーワード検索、`すべて / ピン留め / URL / テキスト` フィルタに対応
- **LiveContainer完全対応**: App Extensionや特殊なEntitlementsを使わない単一ターゲット構成のため、LiveContainerのコンテナ内で安定動作

## GitHub Actionsでの `.ipa` ビルド手順
1. GitHubで新しいリポジトリを作成し、このフォルダの中身をすべてプッシュします。
2. リポジトリの **Actions** タブを開くと、`Build Unsigned IPA for LiveContainer` ワークフローが自動実行されます（手動実行も可能）。
3. ビルド完了後、ワークフロー結果画面の **Artifacts** から `MultiClipboard-IPA` をダウンロードして解凍すると `MultiClipboard.ipa` が取得できます。
4. iPhoneの **LiveContainer** に `MultiClipboard.ipa` をインポートして起動してください。
