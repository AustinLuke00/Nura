// DiaperRecord.swift
// Nura — Diaper record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

enum DiaperType: String, CaseIterable, Identifiable, Codable {
    case wet = "小便"
    case dirty = "大便"
    case both = "混合"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .wet: return "💧"
        case .dirty: return "💩"
        case .both: return "🌊"
        }
    }
    
    var iconName: String {
        switch self {
        case .wet: return "drop.fill"
        case .dirty: return "circle.fill"
        case .both: return "drop.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .wet: return .nuraBlue
        case .dirty: return .nuraWarning
        case .both: return Color(hex: "8B5CF6")
        }
    }
}

@Model
final class DiaperRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var typeRaw: String

    var child: Child?

    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         type: DiaperType,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.typeRaw = type.rawValue
        self.child = child
    }

    var type: DiaperType {
        get { DiaperType(rawValue: typeRaw) ?? .wet }
        set { typeRaw = newValue.rawValue }
    }

    var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }
}
