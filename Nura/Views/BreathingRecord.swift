// BreathingRecord.swift
// Nura — Breathing record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

@Model
final class BreathingRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var breathsPerMinute: Int
    var breathCount: Int?
    var durationSeconds: Int?
    var notes: String?
    
    var child: Child?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         breathsPerMinute: Int,
         breathCount: Int? = nil,
         durationSeconds: Int = 60,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.breathsPerMinute = breathsPerMinute
        self.breathCount = breathCount ?? breathsPerMinute
        self.durationSeconds = durationSeconds
        self.notes = notes
        self.child = child
    }
    
    var rateDisplay: String {
        "\(breathsPerMinute) 次/分"
    }

    var countDisplay: String {
        "\(resolvedBreathCount) 次 / \(durationDisplay)"
    }

    var durationDisplay: String {
        let secondsValue = resolvedDurationSeconds
        if secondsValue < 60 { return "\(secondsValue)秒" }
        let minutes = secondsValue / 60
        let seconds = secondsValue % 60
        return seconds > 0 ? "\(minutes)分\(seconds)秒" : "\(minutes)分钟"
    }

    private var resolvedBreathCount: Int {
        breathCount ?? breathsPerMinute
    }

    private var resolvedDurationSeconds: Int {
        max(durationSeconds ?? 60, 1)
    }
    
    var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }
    
    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: timestamp)
    }
    
    var fullDateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter.string(from: timestamp)
    }
    
    // 呼吸频率状态（根据年龄判断）
    func status(for child: Child?) -> BreathingStatus {
        guard let child = child else { return .normal }
        
        let ageInMonths = Calendar.current.dateComponents([.month], from: child.birthDate, to: Date()).month ?? 0
        
        // 新生儿-2个月：30-60次/分
        if ageInMonths < 2 {
            if breathsPerMinute < 25 { return .low }
            if breathsPerMinute <= 60 { return .normal }
            return .high
        }
        // 2-12个月：25-40次/分
        else if ageInMonths < 12 {
            if breathsPerMinute < 20 { return .low }
            if breathsPerMinute <= 45 { return .normal }
            return .high
        }
        // 1-3岁：20-30次/分
        else {
            if breathsPerMinute < 15 { return .low }
            if breathsPerMinute <= 35 { return .normal }
            return .high
        }
    }
}

enum BreathingStatus {
    case low
    case normal
    case high
    
    var label: String {
        switch self {
        case .low: return "偏慢"
        case .normal: return "正常"
        case .high: return "偏快"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .nuraBlue
        case .normal: return .nuraSuccess
        case .high: return .nuraWarning
        }
    }
}
