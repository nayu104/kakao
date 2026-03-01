//
//  HomeView.swift
//  kakao
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = CaffeineViewModel()
    @State private var showDebug = false
    @State private var buttonPressed = false

    var body: some View {
        ZStack {
            // 背景
            backgroundView

            VStack(spacing: 0) {
                // タイトル
                titleBar

                Spacer(minLength: 8)

                // 猫
                CatView(level: vm.level)
                    .padding(.horizontal, 24)

                Spacer(minLength: 16)

                // ステータスカード
                statusCard

                Spacer(minLength: 24)

                // コーヒーボタン
                coffeeButton

                Spacer(minLength: 16)

                // デバッグパネル（トグル）
                debugSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
    }

    // MARK: - 背景
    private var backgroundView: some View {
        LinearGradient(
            colors: [backgroundColor.opacity(0.15), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var backgroundColor: Color {
        switch vm.level {
        case .high:  return .orange
        case .mid:   return .blue
        case .low:   return .purple
        case .empty: return .indigo
        }
    }

    // MARK: - タイトル
    private var titleBar: some View {
        HStack {
            Text("kakao")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
            Button {
                withAnimation { showDebug.toggle() }
            } label: {
                Image(systemName: "wrench.and.screwdriver")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
        }
    }

    // MARK: - ステータスカード
    private var statusCard: some View {
        VStack(spacing: 12) {
            // 状態ラベル
            HStack(spacing: 8) {
                Circle()
                    .fill(levelColor)
                    .frame(width: 12, height: 12)
                Text(vm.level.label)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(levelColor)
            }

            // mg表示
            Text(String(format: "%.0f mg", vm.currentMg))
                .font(.system(size: 16, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)

            Divider()

            // 落ちるまでの時間
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)
                if vm.hoursUntilEmpty > 0 {
                    Text("落ちるまで目安：\(formatHours(vm.hoursUntilEmpty))")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Text("カフェインはほぼ抜けています")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }

    private var levelColor: Color {
        switch vm.level {
        case .high:  return .red
        case .mid:   return .orange
        case .low:   return .yellow
        case .empty: return .gray
        }
    }

    // MARK: - コーヒーボタン
    private var coffeeButton: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                buttonPressed = true
            }
            vm.addCoffee()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation { buttonPressed = false }
            }
        } label: {
            HStack(spacing: 12) {
                Text("☕️")
                    .font(.system(size: 28))
                Text("コーヒー1杯")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.5, green: 0.3, blue: 0.1),
                                     Color(red: 0.35, green: 0.2, blue: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .brown.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(buttonPressed ? 0.94 : 1.0)
        }
    }

    // MARK: - デバッグセクション
    private var debugSection: some View {
        Group {
            if showDebug {
                VStack(spacing: 10) {
                    Text("🛠 デバッグ（時刻操作）")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        debugButton("+1h") { vm.advanceTime(hours: 1) }
                        debugButton("+3h") { vm.advanceTime(hours: 3) }
                        debugButton("+6h") { vm.advanceTime(hours: 6) }
                        debugButton("リセット") { vm.resetDebugOffset() }
                    }

                    if vm.debugOffsetSeconds != 0 {
                        Text("現在オフセット: +\(Int(vm.debugOffsetSeconds / 3600))h \(Int((vm.debugOffsetSeconds.truncatingRemainder(dividingBy: 3600)) / 60))m")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func debugButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color(.tertiarySystemBackground)))
                .overlay(Capsule().stroke(Color.secondary.opacity(0.3)))
        }
        .foregroundColor(.primary)
    }

    // MARK: - ユーティリティ
    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        if h == 0 {
            return "\(m)分"
        } else if m == 0 {
            return "\(h)時間"
        } else {
            return "\(h)時間\(m)分"
        }
    }
}

#Preview {
    HomeView()
}
