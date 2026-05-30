// Child.swift
// Nura — Child model with SwiftData

import Foundation
import SwiftUI
import SwiftData

@Model
final class Child {
    @Attribute(.unique) var id: UUID
    var name: String
    var birthDate: Date
    var genderRaw: String
    var colorRaw: String
    var profileTypeRaw: String = ProfileType.baby.rawValue
    var emergencyContactName: String?
    var emergencyContactPhone: String?
    var deliveryDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \FeedingRecord.child)
    var feedings: [FeedingRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \DiaperRecord.child)
    var diapers: [DiaperRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \SleepRecord.child)
    var sleeps: [SleepRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \GrowthRecord.child)
    var growthRecords: [GrowthRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \Milestone.child)
    var milestones: [Milestone] = []

    @Relationship(deleteRule: .cascade, inverse: \JaundiceRecord.child)
    var jaundiceRecords: [JaundiceRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \TemperatureRecord.child)
    var temperatureRecords: [TemperatureRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \BreathingRecord.child)
    var breathingRecords: [BreathingRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \MedicineRecord.child)
    var medicineRecords: [MedicineRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \VaccineRecord.child)
    var vaccineRecords: [VaccineRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \FetalMovementRecord.child)
    var fetalMovementRecords: [FetalMovementRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \BloodPressureRecord.child)
    var bloodPressureRecords: [BloodPressureRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \BloodSugarRecord.child)
    var bloodSugarRecords: [BloodSugarRecord] = []

    @Relationship(deleteRule: .cascade, inverse: \PregnancyWeightRecord.child)
    var pregnancyWeightRecords: [PregnancyWeightRecord] = []

    init(
        id: UUID = UUID(),
        name: String,
        birthDate: Date,
        gender: Gender,
        color: ChildColor,
        profileType: ProfileType = .baby,
        emergencyContactName: String? = nil,
        emergencyContactPhone: String? = nil,
        deliveryDate: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.genderRaw = gender.rawValue
        self.colorRaw = color.rawValue
        self.profileTypeRaw = profileType.rawValue
        self.emergencyContactName = emergencyContactName
        self.emergencyContactPhone = emergencyContactPhone
        self.deliveryDate = deliveryDate
    }

    // MARK: - Enums

    enum Gender: String, Codable {
        case male, female
    }

    enum ProfileType: String, Codable {
        case pregnancy, baby
    }

    enum ChildColor: String, CaseIterable, Codable {
        case purple, pink, blue, teal, amber

        var swatch: Color {
            switch self {
            case .purple: return Color(hex: "A78BFA")
            case .pink:   return Color(hex: "F9A8D4")
            case .blue:   return Color(hex: "93C5FD")
            case .teal:   return Color(hex: "5EEAD4")
            case .amber:  return Color(hex: "FCD34D")
            }
        }

        var lightBg: Color { swatch.opacity(0.15) }
    }

    // MARK: - Computed Properties

    var gender: Gender {
        get { Gender(rawValue: genderRaw) ?? .female }
        set { genderRaw = newValue.rawValue }
    }

    var color: ChildColor {
        get { ChildColor(rawValue: colorRaw) ?? .purple }
        set { colorRaw = newValue.rawValue }
    }

    var profileType: ProfileType {
        get { ProfileType(rawValue: profileTypeRaw) ?? (birthDate > Date() ? .pregnancy : .baby) }
        set { profileTypeRaw = newValue.rawValue }
    }

    var ageInDays: Int {
        Calendar.current.dateComponents([.day], from: birthDate, to: .now).day ?? 0
    }

    var isNewborn: Bool { ageInDays >= 0 && ageInDays < 365 }

    var ageDisplay: String {
        if profileType == .pregnancy {
            if let deliveryDate {
                return "已生产 · \(deliveryDate.nuraDateShortDisplay)"
            }
            return "孕\(pregnancyWeekDisplay) · 距预产期\(daysUntilDueDate)天"
        }

        let d = ageInDays
        if d < 30 { return "\(d)天" }
        if d < 365 {
            let m = d / 30; let r = d % 30
            return r > 0 ? "\(m)月\(r)天" : "\(m)个月"
        }
        let y = d / 365; let m = (d % 365) / 30
        return m > 0 ? "\(y)岁\(m)月" : "\(y)岁"
    }

    var initial: String { String(name.prefix(1)) }
}
