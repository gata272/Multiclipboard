import Foundation
import UIKit
import AVFoundation
import Combine

@MainActor
final class ClipboardManager: ObservableObject {
    @Published var items: [ClipItem] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: ClipCategory = .all
    @Published var toastMessage: String? = nil
    @Published var isBackgroundMonitorEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isBackgroundMonitorEnabled, forKey: bgMonitorKey)
            updateBackgroundMonitoring()
        }
    }
    @Published var maxHistoryCount: Int = 100 {
        didSet {
            UserDefaults.standard.set(maxHistoryCount, forKey: maxCountKey)
            enforceHistoryLimit()
            saveItems()
        }
    }

    private let storageFileName = "clipboard_history.json"
    private let bgMonitorKey = "bg_monitor_enabled"
    private let maxCountKey = "max_history_count"
    private var lastCapturedChangeCount: Int = -1
    private var lastCapturedString: String = ""
    private var pollingTimer: Timer?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var toastTask: Task<Void, Never>?

    init() {
        let savedMax = UserDefaults.standard.integer(forKey: maxCountKey)
        if savedMax > 0 {
            self.maxHistoryCount = savedMax
        }
        self.isBackgroundMonitorEnabled = UserDefaults.standard.bool(forKey: bgMonitorKey)
        loadItems()
        setupNotifications()
        captureCurrentPasteboard()
        if isBackgroundMonitorEnabled {
            updateBackgroundMonitoring()
        }
    }

    var filteredItems: [ClipItem] {
        items
            .filter { item in
                switch selectedCategory {
                case .all:
                    return true
                case .pinned:
                    return item.isPinned
                case .url:
                    return item.isURL
                case .text:
                    return !item.isURL
                }
            }
            .filter { item in
                if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return true
                }
                return item.content.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned && !rhs.isPinned
                }
                return lhs.createdAt > rhs.createdAt
            }
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIPasteboard.changedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.captureCurrentPasteboard()
            }
        }
    }

    func captureCurrentPasteboard() {
        let pasteboard = UIPasteboard.general
        let currentCount = pasteboard.changeCount
        guard currentCount != lastCapturedChangeCount else { return }
        lastCapturedChangeCount = currentCount

        guard let str = pasteboard.string else { return }
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, str != lastCapturedString else { return }

        addClip(str, showFeedback: false)
    }

    func addClip(_ text: String, showFeedback: Bool = true) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let existingIndex = items.firstIndex(where: { $0.content == text }) {
            var existing = items.remove(at: existingIndex)
            existing.createdAt = Date()
            items.insert(existing, at: 0)
        } else {
            let newItem = ClipItem(content: text)
            items.insert(newItem, at: 0)
        }

        lastCapturedString = text
        enforceHistoryLimit()
        saveItems()

        if showFeedback {
            showToast("クリップを追加しました")
        }
    }

    func copyToPasteboard(_ item: ClipItem) {
        lastCapturedString = item.content
        UIPasteboard.general.string = item.content
        lastCapturedChangeCount = UIPasteboard.general.changeCount

        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].createdAt = Date()
            saveItems()
        }
        showToast("コピーしました")
    }

    func togglePin(_ item: ClipItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        saveItems()
        showToast(items[index].isPinned ? "ピン留めしました" : "ピン留めを解除しました")
    }

    func updateClip(_ item: ClipItem, newContent: String) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let trimmed = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        items[index].content = newContent
        items[index].isURL = ClipItem.detectURL(in: newContent)
        saveItems()
        showToast("更新しました")
    }

    func deleteClip(_ item: ClipItem) {
        items.removeAll { $0.id == item.id }
        saveItems()
    }

    func clearUnpinned() {
        items.removeAll { !$0.isPinned }
        saveItems()
        showToast("ピン留め以外を削除しました")
    }

    func showToast(_ message: String) {
        toastTask?.cancel()
        toastMessage = message
        toastTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if !Task.isCancelled {
                self.toastMessage = nil
            }
        }
    }

    // MARK: - Background Keep-Alive (for LiveContainer / Sideloaded Apps)
    private func updateBackgroundMonitoring() {
        if isBackgroundMonitorEnabled {
            startSilentAudioSession()
            pollingTimer?.invalidate()
            pollingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.captureCurrentPasteboard()
                }
            }
        } else {
            pollingTimer?.invalidate()
            pollingTimer = nil
            stopSilentAudioSession()
        }
    }

    private func startSilentAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            engine.attach(player)

            let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
            engine.connect(player, to: engine.mainMixerNode, format: format)

            let frameCount = AVAudioFrameCount(44100)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
            buffer.frameLength = frameCount
            // Buffer is zero-initialized (silent)

            try engine.start()
            player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            player.play()

            self.audioEngine = engine
            self.playerNode = player
        } catch {
            print("Silent audio session failed: \(error)")
        }
    }

    private func stopSilentAudioSession() {
        playerNode?.stop()
        audioEngine?.stop()
        playerNode = nil
        audioEngine = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Persistence (Documents directory works cleanly inside LiveContainer sandbox)
    private var storageURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent(storageFileName)
    }

    private func enforceHistoryLimit() {
        let pinned = items.filter { $0.isPinned }
        var unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxHistoryCount {
            unpinned = Array(unpinned.prefix(maxHistoryCount))
        }
        items = pinned + unpinned
    }

    private func saveItems() {
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to save clipboard items: \(error)")
        }
    }

    private func loadItems() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            items = try JSONDecoder().decode([ClipItem].self, from: data)
        } catch {
            print("Failed to load clipboard items: \(error)")
        }
    }
}
