//
//  CaffeineEntry.swift
//  kakao
//

import Foundation

struct CaffeineEntry: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let doseMg: Double

    init(id: UUID = UUID(), timestamp: Date = Date(), doseMg: Double = 95.0) {
        self.id = id
        self.timestamp = timestamp
        self.doseMg = doseMg
    }
}
