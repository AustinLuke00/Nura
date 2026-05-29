// TemperatureRecord.swift
// Nura — Temperature record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

enum TemperatureSite: String, CaseIterable, Identifiable, Codable {
    case armpit = "腋下"
    case forehead = "额头"
    case ear = "耳温"
    case rectal = "肛温"
    case oral = "口腔"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .armpit: return "figure.arms.open"
        case .forehead: return "face.smiling"
        case .ear: return "ear"
        case .rectal: return "thermometer"
        case .oral: return "mouth"
        }
    }
}

@Model
final class TemperatureRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var temperatureCelsius: Double
    var siteRaw: String
    var notes: String?
    
    var child: Child?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         temperatureCelsius: Double,
         site: TemperatureSite,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.temperatureCelsius = temperatureCelsius
        self.siteRaw = site.rawValue
        self.notes = notes
        self.child = child
    }
    
    var site: TemperatureSite {
        get { TemperatureSite(rawValue: siteRaw) ?? .armpit }
        set { siteRaw = newValue.rawValue }
    }
    
    var temperatureDisplay: String {
        String(format: "%.1f°C", temperatureCelsius)
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
    
    // 体温状态
    var status: TemperatureStatus {
        if temperatureCelsius < 36.0 { return .low }
        if temperatureCelsius <= 37.3 { return .normal }
        if temperatureCelsius <= 38.0 { return .elevated }
        if temperatureCelsius <= 39.0 { return .fever }
        return .highFever
    }
}

enum TemperatureStatus {
    case low
    case normal
    case elevated
    case fever
    case highFever
    
    var label: String {
        switch self {
        case .low: return "偏低"
        case .normal: return "正常"
        case .elevated: return "略高"
        case .fever: return "发热"
        case .highFever: return "高热"
        }
    }
    
    var color: Color {
        switch self {
        case .low: return .nuraBlue
        case .normal: return .nuraSuccess
        case .elevated: return .nuraWarning
        case .fever: return Color(hex: "F59E0B")
        case .highFever: return .nuraDanger
        }
    }
}
