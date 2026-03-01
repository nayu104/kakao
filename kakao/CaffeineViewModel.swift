//
//  CaffeineViewModel.swift
//  kakao
//

import Foundation
import Combine

// カフェイン状態の4段階
enum CaffeineLevel {
    case high, mid, low, empty

    var label: String {
        switch self {
        case .high:  return "HIGH"
        case .mid:   return "MID"
        case .low:   return "LOW"
        case .empty: return "EMPTY"
        }
    }

    var color: String {
        switch self {
        case .high:  return "red"
        case .mid:   return "orange"
        case .low:   return "yellow"
        case .empty: return "gray"
        }
    }

    // 画像が用意できたら Assets に同名で追加する
    // 例: "cat_high.png", "cat_mid.png", "cat_low.png", "cat_empty.png"
    var imageName: String {
        switch self {
        case .high:  return "cat_high"
        case .mid:   return "cat_mid"
        case .low:   return "cat_low"
        case .empty: return "cat_empty"
        }
    }

    // 画像の代わりに表示する暫定テキスト（絵文字）
    var catEmoji: String {
        switch self {
        case .high:  return "🐱💨"   // 走る猫
        case .mid:   return "🐱"     // 歩く猫
        case .low:   return "🐾"     // のろのろ
        case .empty: return "😴"     // 眠る猫
        }
    }

    // 状態の説明テキスト（暫定ラベル）
    var placeholderLabel: String {
        switch self {
        case .high:  return "🖼 cat_high.png"
        case .mid:   return "🖼 cat_mid.png"
        case .low:   return "🖼 cat_low.png"
        case .empty: return "🖼 cat_empty.png"
        }
    }
}

class CaffeineViewModel: ObservableObject {
    // MARK: - Published
    @Published private(set) var entries: [CaffeineEntry] = []
    @Published private(set) var currentMg: Double = 0
    @Published private(set) var level: CaffeineLevel = .empty
    @Published private(set) var hoursUntilEmpty: Double = 0

    // MARK: - Constants
    private let halfLifeHours: Double = 5.0
    private let dosePerCup: Double = 95.0
    /// この mg 以上なら HIGH と判定する基準（1杯分）
    private let referenceDose: Double = 95.0

    // MARK: - Debug用 時刻オフセット（秒）
    @Published var debugOffsetSeconds: Double = 0

    // MARK: - Timer
    private var timer: AnyCancellable?

    // MARK: - UserDefaults key
    private let storageKey = "caffeine_entries"

    init() {
        load()
        startTimer()
    }

    // MARK: - 現在時刻（デバッグオフセット込み）
    var now: Date {
        Date().addingTimeInterval(debugOffsetSeconds)
    }

    // MARK: - コーヒー1杯を記録
    func addCoffee() {
        let entry = CaffeineEntry(timestamp: now)
        entries.append(entry)
        save()
        recalculate()
    }

    // MARK: - デバッグ: 時刻を進める
    func advanceTime(hours: Double) {
        debugOffsetSeconds += hours * 3600
        recalculate()
    }

    func resetDebugOffset() {
        debugOffsetSeconds = 0
        recalculate()
    }

    // MARK: - 計算
    func recalculate() {
        let t = now
        // C(t) = Σ dose_i * 0.5^((t - time_i) / T_half)
        let totalMg = entries.reduce(0.0) { sum, entry in
            let elapsedHours = t.timeIntervalSince(entry.timestamp) / 3600.0
            let remaining = entry.doseMg * pow(0.5, elapsedHours / halfLifeHours)
            return sum + remaining
        }
        currentMg = max(totalMg, 0)

        // 正規化 S(t): 1杯(95mg)を1.0として相対化
        let s = currentMg / referenceDose

        // 4段階分類
        if s >= 0.8 {
            level = .high
        } else if s >= 0.4 {
            level = .mid
        } else if s >= 0.1 {
            level = .low
        } else {
            level = .empty
        }

        // EMPTY になるまでの残り時間
        // C(t) = currentMg * 0.5^(h/5) = threshold (9.5mg = 0.1 * 95)
        let threshold = referenceDose * 0.1
        if currentMg > threshold {
            // h = T_half * log2(currentMg / threshold)
            hoursUntilEmpty = halfLifeHours * log2(currentMg / threshold)
        } else {
            hoursUntilEmpty = 0
        }
    }

    // MARK: - Timer (1分ごとに再計算)
    private func startTimer() {
        timer = Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recalculate()
            }
    }

    // MARK: - 永続化
    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([CaffeineEntry].self, from: data) {
            entries = decoded
        }
        recalculate()
    }
}
