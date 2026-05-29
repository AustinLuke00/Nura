// JaundiceRecord.swift
// Nura — Jaundice (黄疸) record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

@Model
final class JaundiceRecord: @unchecked Sendable {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var bilirubinLevel: Double  // 胆红素水平 (mg/dL 或 μmol/L)
    var measurementSite: String // 测量部位: 额头、胸部、经皮等
    var notes: String?
    
    var child: Child?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         bilirubinLevel: Double,
         measurementSite: MeasurementSite = .forehead,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.bilirubinLevel = bilirubinLevel
        self.measurementSite = measurementSite.rawValue
        self.notes = notes
        self.child = child
    }
    
    enum MeasurementSite: String, CaseIterable, Identifiable, Codable {
        case forehead = "额头"
        case chest = "胸部"
        case transcutaneous = "经皮测量"
        case blood = "血液检测"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .forehead: return "face.smiling"
            case .chest: return "heart.fill"
            case .transcutaneous: return "waveform.path.ecg"
            case .blood: return "drop.fill"
            }
        }
    }
    
    var site: MeasurementSite {
        get { MeasurementSite(rawValue: measurementSite) ?? .forehead }
        set { measurementSite = newValue.rawValue }
    }
    
    var timeDisplay: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: timestamp)
    }
    
    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: timestamp)
    }
    
    var levelDisplay: String {
        String(format: "%.1f", bilirubinLevel)
    }
    
    var riskLevel: RiskLevel {
        // 根据新生儿黄疸标准判断风险等级
        // 注意：这是简化的评估，实际需要考虑出生天数等因素
        if bilirubinLevel < 5 { return .low }
        if bilirubinLevel < 12 { return .normal }
        if bilirubinLevel < 15 { return .moderate }
        return .high
    }
    
    enum RiskLevel {
        case low, normal, moderate, high
        
        var color: Color {
            switch self {
            case .low: return .nuraSuccess
            case .normal: return Color(hex: "10B981")
            case .moderate: return .nuraWarning
            case .high: return .nuraDanger
            }
        }
        
        var label: String {
            switch self {
            case .low: return "偏低"
            case .normal: return "正常"
            case .moderate: return "偏高"
            case .high: return "较高"
            }
        }
    }
}
