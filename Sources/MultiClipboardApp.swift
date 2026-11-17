import SwiftUI

@main
struct MultiClipboardApp: App {
    @StateObject private var clipboardManager = ClipboardManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(clipboardManager)
                .onChange(of: scenePhase) { newPhase in
                    if newPhase == .active {
                        clipboardManager.captureCurrentPasteboard()
                    }
                }
        }
    }
}
