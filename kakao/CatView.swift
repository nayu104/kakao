//
//  CatView.swift
//  kakao
//

import SwiftUI

/// 状態に応じた画像を表示するだけのシンプルな猫View
/// 画像が用意できたら Assets に cat_high / cat_mid / cat_low / cat_empty を追加するだけでOK
struct CatView: View {
    let level: CaffeineLevel

    var body: some View {
        // TODO: 画像が用意できたら Text(...) を以下に差し替える
        // Image(level.imageName)
        //     .resizable()
        //     .scaledToFit()
        //     .frame(height: 200)

        // ---- 暫定テキストプレースホルダー ----
        VStack(spacing: 8) {
            Text(level.catEmoji)
                .font(.system(size: 80))
            Text(level.placeholderLabel)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

#Preview {
    VStack(spacing: 20) {
        CatView(level: .high)
        CatView(level: .mid)
        CatView(level: .low)
        CatView(level: .empty)
    }
    .padding()
}
