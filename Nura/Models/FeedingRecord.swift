// FeedingRecord.swift
// Nura — Feeding record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

enum FeedingType: String, CaseIterable, Identifiable, Codable {
    case breastLeft  = "母乳·左侧"
    case breastRight = "母乳·右侧"
    case bottleFormula = "奶瓶·配方奶"
    case bottleExpressed = "奶瓶·母乳"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .breastLeft, .breastRight: return "🤱"
        case .bottleFormula, .bottleExpressed: return "🍼"
        }
    }
    
    var iconName: String {
        switch self {
        case .breastLeft, .breastRight: return "drop.fill"
        case .bottleFormula, .bottleExpressed: return "bottle.fill"
        }
    }

    var isBreast: Bool {
        self == .breastLeft || self == .breastRight
    }

    var color: Color {
        switch self {
        case .breastLeft, .breastRight: return .nuraPrimary
        case .bottleFormula: return .nuraBlue
        case .bottleExpressed: return .nuraSuccess
        }
    }
}

@Model
final class FeedingRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var typeRaw: String
    var durationMinutes: Int?
    var amountMl: Double?
    var notes: String?

    var child: Child?

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         type: FeedingType,
         durationMinutes: Int? = nil,
         amountMl: Double? = nil,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.durationMinutes = durationMinutes
        self.amountMl = amountMl
        self.notes = notes
        self.child = child
    }

    var type: FeedingType {
        get { FeedingType(rawValue: typeRaw) ?? .breastLeft }
        set { typeRaw = newValue.rawValue }
    }

    var detailDisplay: String {
        if let d = durationMinutes { return "\(d) 分钟" }
        if let a = amountMl { return "\(Int(a)) ml" }
        return ""
    }

    var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }
    
    var fullDateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日 HH:mm"
        return formatter.string(from: timestamp)
    }
    
    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: timestamp)
    }
}
