// PregnancyRecords.swift
// Nura — Pregnancy-specific records

import Foundation
import SwiftData

@Model
final class FetalMovementRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var count: Int
    var durationMinutes: Int
    var actualSeconds: Int
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), count: Int, durationMinutes: Int, actualSeconds: Int, child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.count = count
        self.durationMinutes = durationMinutes
        self.actualSeconds = actualSeconds
        self.child = child
    }

    var dateDisplay: String { timestamp.nuraDateTimeDisplay }
    var durationDisplay: String { "\(max(actualSeconds / 60, 1))分钟" }
}

@Model
final class BloodPressureRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var systolic: Int
    var diastolic: Int
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), systolic: Int, diastolic: Int, child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.systolic = systolic
        self.diastolic = diastolic
        self.child = child
    }

    var valueDisplay: String { "\(systolic)/\(diastolic)" }
    var status: String {
        if systolic >= 140 || diastolic >= 90 { return "偏高" }
        if systolic < 90 || diastolic < 60 { return "偏低" }
        return "正常"
    }
    var dateDisplay: String { timestamp.nuraDateTimeDisplay }
}

@Model
final class BloodSugarRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var glucose: Double
    var timingRaw: String
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), glucose: Double, timing: BloodSugarTiming, child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.glucose = glucose
        self.timingRaw = timing.rawValue
        self.child = child
    }

    var timing: BloodSugarTiming {
        get { BloodSugarTiming(rawValue: timingRaw) ?? .fasting }
        set { timingRaw = newValue.rawValue }
    }
    var valueDisplay: String { String(format: "%.1f mmol/L", glucose) }
    var dateDisplay: String { timestamp.nuraDateTimeDisplay }
}

enum BloodSugarTiming: String, CaseIterable, Identifiable, Codable {
    case fasting = "空腹"
    case afterMeal1h = "餐后1小时"
    case afterMeal2h = "餐后2小时"
    var id: String { rawValue }
}

@Model
final class PregnancyWeightRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var weightKg: Double
    var child: Child?

    init(id: UUID = UUID(), timestamp: Date = Date(), weightKg: Double, child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.weightKg = weightKg
        self.child = child
    }

    var valueDisplay: String { String(format: "%.1f kg", weightKg) }
    var dateDisplay: String { timestamp.nuraDateTimeDisplay }
}

extension Date {
    var nuraDateTimeDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: self)
    }
}
