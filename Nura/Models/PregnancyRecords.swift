// PregnancyRecords.swift
// Nura — Pregnancy-specific records

import Foundation
import SwiftData

@Model
final class ConceptionRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var basalTemperature: Double?
    var ovulationTestRaw: String
    var hadIntercourse: Bool
    var intercourseTime: Date?
    var periodFlowRaw: String
    var notes: String?
    var child: Child?

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        basalTemperature: Double? = nil,
        ovulationTest: OvulationTestResult = .notTested,
        hadIntercourse: Bool = false,
        intercourseTime: Date? = nil,
        periodFlow: PeriodFlow = .none,
        notes: String? = nil,
        child: Child? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.basalTemperature = basalTemperature
        self.ovulationTestRaw = ovulationTest.rawValue
        self.hadIntercourse = hadIntercourse
        self.intercourseTime = intercourseTime
        self.periodFlowRaw = periodFlow.rawValue
        self.notes = notes
        self.child = child
    }

    var ovulationTest: OvulationTestResult {
        get { OvulationTestResult(rawValue: ovulationTestRaw) ?? .notTested }
        set { ovulationTestRaw = newValue.rawValue }
    }

    var periodFlow: PeriodFlow {
        get { PeriodFlow(rawValue: periodFlowRaw) ?? .none }
        set { periodFlowRaw = newValue.rawValue }
    }

    var temperatureDisplay: String {
        basalTemperature.map { String(format: "%.2f°C", $0) } ?? "--"
    }

    var dateDisplay: String { timestamp.nuraDateTimeDisplay }
}

enum OvulationTestResult: String, CaseIterable, Identifiable, Codable {
    case notTested = "未测"
    case negative = "阴性"
    case weakPositive = "弱阳"
    case positive = "阳性"
    case peak = "强阳"

    var id: String { rawValue }

    var score: Double {
        switch self {
        case .notTested: return 0
        case .negative: return 1
        case .weakPositive: return 2
        case .positive: return 3
        case .peak: return 4
        }
    }
}

enum PeriodFlow: String, CaseIterable, Identifiable, Codable {
    case none = "无"
    case spotting = "少量"
    case light = "偏少"
    case medium = "正常"
    case heavy = "偏多"

    var id: String { rawValue }
    var isPeriod: Bool { self != .none }
}

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
