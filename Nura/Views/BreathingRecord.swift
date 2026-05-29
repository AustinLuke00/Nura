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
    var notes: String?
    
    var child: Child?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         breathsPerMinute: Int,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.breathsPerMinute = breathsPerMinute
        self.notes = notes
        self.child = child
    }
    
    var rateDisplay: String {
        "\(breathsPerMinute) 次/分"
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
