// MedicineRecord.swift
// Nura — Medicine record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

@Model
final class MedicineRecord {
    @Attribute(.unique) var id: UUID
    var timestamp: Date
    var medicineName: String
    var dosage: String  // 剂量（如 "5ml", "1片"）
    var unit: String    // 单位（ml, 片, 粒等）
    var reason: String? // 用药原因
    var notes: String?  // 备注
    
    var child: Child?
    
    init(id: UUID = UUID(),
         timestamp: Date = Date(),
         medicineName: String,
         dosage: String,
         unit: String = "ml",
         reason: String? = nil,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.timestamp = timestamp
        self.medicineName = medicineName
        self.dosage = dosage
        self.unit = unit
        self.reason = reason
        self.notes = notes
        self.child = child
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
    
    var timeDisplay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: timestamp)
    }
    
    var dosageDisplay: String {
        "\(dosage) \(unit)"
    }
}
