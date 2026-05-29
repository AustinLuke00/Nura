// GrowthRecord.swift
// Nura — Growth record model with SwiftData

import Foundation
import SwiftData

@Model
final class GrowthRecord {
    @Attribute(.unique) var id: UUID
    var date: Date
    var dayAge: Int
    var weightKg: Double?
    var heightCm: Double?
    var headCircCm: Double?

    var child: Child?

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
    
    var fullDateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }

    init(id: UUID = UUID(),
         date: Date = Date(),
         dayAge: Int = 0,
         weightKg: Double? = nil,
         heightCm: Double? = nil,
         headCircCm: Double? = nil,
         child: Child? = nil) {
        self.id = id
        self.date = date
        self.dayAge = dayAge
        self.weightKg = weightKg
        self.heightCm = heightCm
        self.headCircCm = headCircCm
        self.child = child
    }
}
