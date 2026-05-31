// DataManager.swift
// Nura — SwiftData 数据管理工具

import Foundation
import SwiftData

/// 用于管理 SwiftData 数据的工具类
@MainActor
struct DataManager {
    struct ImportSummary {
        let insertedChildren: Int
        let mergedChildren: Int
        let insertedRecords: Int
        let skippedRecords: Int

        var message: String {
            "新增 \(insertedChildren) 个宝宝,合并 \(mergedChildren) 个宝宝,新增 \(insertedRecords) 条记录,跳过 \(skippedRecords) 条重复记录"
        }
    }

    private struct Backup: Codable {
        var schemaVersion: Int
        var exportedAt: Date
        var children: [ChildBackup]
    }

    private struct ChildBackup: Codable {
        var id: UUID
        var name: String
        var birthDate: Date
        var genderRaw: String
        var colorRaw: String
        var profileTypeRaw: String
        var emergencyContactName: String?
        var emergencyContactPhone: String?
        var deliveryDate: Date?
        var feedings: [FeedingBackup]
        var diapers: [DiaperBackup]
        var sleeps: [SleepBackup]
        var growthRecords: [GrowthBackup]
        var milestones: [MilestoneBackup]
        var jaundiceRecords: [JaundiceBackup]
        var temperatureRecords: [TemperatureBackup]
        var breathingRecords: [BreathingBackup]
        var medicineRecords: [MedicineBackup]
        var vaccineRecords: [VaccineBackup]
        var fetalMovementRecords: [FetalMovementBackup]
        var bloodPressureRecords: [BloodPressureBackup]
        var bloodSugarRecords: [BloodSugarBackup]
        var pregnancyWeightRecords: [PregnancyWeightBackup]
    }

    private struct FeedingBackup: Codable {
        var id: UUID
        var timestamp: Date
        var typeRaw: String
        var durationMinutes: Int?
        var amountMl: Double?
        var notes: String?
    }

    private struct DiaperBackup: Codable {
        var id: UUID
        var timestamp: Date
        var typeRaw: String
    }

    private struct SleepBackup: Codable {
        var id: UUID
        var startTime: Date
        var endTime: Date?
    }

    private struct GrowthBackup: Codable {
        var id: UUID
        var date: Date
        var dayAge: Int
        var weightKg: Double?
        var heightCm: Double?
        var headCircCm: Double?
    }

    private struct MilestoneBackup: Codable {
        var id: UUID
        var emoji: String
        var title: String
        var date: Date
        var notes: String?
    }

    private struct JaundiceBackup: Codable {
        var id: UUID
        var timestamp: Date
        var bilirubinLevel: Double
        var measurementSite: String
        var notes: String?
    }

    private struct TemperatureBackup: Codable {
        var id: UUID
        var timestamp: Date
        var temperatureCelsius: Double
        var siteRaw: String
        var notes: String?
    }

    private struct BreathingBackup: Codable {
        var id: UUID
        var timestamp: Date
        var breathsPerMinute: Int
        var breathCount: Int?
        var durationSeconds: Int?
        var notes: String?
    }

    private struct MedicineBackup: Codable {
        var id: UUID
        var timestamp: Date
        var medicineName: String
        var dosage: String
        var unit: String
        var reason: String?
        var notes: String?
    }

    private struct VaccineBackup: Codable {
        var id: UUID
        var scheduleKey: String
        var vaccineName: String
        var dose: String
        var scheduledDate: Date
        var completedDate: Date?
        var notes: String?
    }

    private struct FetalMovementBackup: Codable {
        var id: UUID
        var timestamp: Date
        var count: Int
        var durationMinutes: Int
        var actualSeconds: Int
    }

    private struct BloodPressureBackup: Codable {
        var id: UUID
        var timestamp: Date
        var systolic: Int
        var diastolic: Int
    }

    private struct BloodSugarBackup: Codable {
        var id: UUID
        var timestamp: Date
        var glucose: Double
        var timingRaw: String
    }

    private struct PregnancyWeightBackup: Codable {
        var id: UUID
        var timestamp: Date
        var weightKg: Double
    }

    /// 导出所有 SwiftData 数据为 JSON 备份
    /// - Parameter modelContext: SwiftData 模型上下文
    /// - Returns: JSON 数据
    static func exportData(from modelContext: ModelContext) throws -> Data {
        let children = try modelContext.fetch(FetchDescriptor<Child>())
        let backup = Backup(
            schemaVersion: 1,
            exportedAt: Date(),
            children: children
                .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
                .map(makeChildBackup)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(backup)
    }

    /// 导入 JSON 备份。已有宝宝会追加缺失记录,不存在的宝宝会新增。
    /// - Parameters:
    ///   - data: JSON 备份数据
    ///   - modelContext: SwiftData 模型上下文
    /// - Returns: 导入结果统计
    @discardableResult
    static func importData(_ data: Data, into modelContext: ModelContext) throws -> ImportSummary {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(Backup.self, from: data)

        var existingChildren = Dictionary(uniqueKeysWithValues: try modelContext.fetch(FetchDescriptor<Child>()).map { ($0.id, $0) })
        var existingFeedingIds = Set(try modelContext.fetch(FetchDescriptor<FeedingRecord>()).map(\.id))
        var existingDiaperIds = Set(try modelContext.fetch(FetchDescriptor<DiaperRecord>()).map(\.id))
        var existingSleepIds = Set(try modelContext.fetch(FetchDescriptor<SleepRecord>()).map(\.id))
        var existingGrowthIds = Set(try modelContext.fetch(FetchDescriptor<GrowthRecord>()).map(\.id))
        var existingMilestoneIds = Set(try modelContext.fetch(FetchDescriptor<Milestone>()).map(\.id))
        var existingJaundiceIds = Set(try modelContext.fetch(FetchDescriptor<JaundiceRecord>()).map(\.id))
        var existingTemperatureIds = Set(try modelContext.fetch(FetchDescriptor<TemperatureRecord>()).map(\.id))
        var existingBreathingIds = Set(try modelContext.fetch(FetchDescriptor<BreathingRecord>()).map(\.id))
        var existingMedicineIds = Set(try modelContext.fetch(FetchDescriptor<MedicineRecord>()).map(\.id))
        var existingVaccineIds = Set(try modelContext.fetch(FetchDescriptor<VaccineRecord>()).map(\.id))
        var existingFetalMovementIds = Set(try modelContext.fetch(FetchDescriptor<FetalMovementRecord>()).map(\.id))
        var existingBloodPressureIds = Set(try modelContext.fetch(FetchDescriptor<BloodPressureRecord>()).map(\.id))
        var existingBloodSugarIds = Set(try modelContext.fetch(FetchDescriptor<BloodSugarRecord>()).map(\.id))
        var existingPregnancyWeightIds = Set(try modelContext.fetch(FetchDescriptor<PregnancyWeightRecord>()).map(\.id))

        var insertedChildren = 0
        var mergedChildren = 0
        var insertedRecords = 0
        var skippedRecords = 0

        for childBackup in backup.children {
            let child: Child
            if let existingChild = existingChildren[childBackup.id] {
                child = existingChild
                mergedChildren += 1
            } else {
                child = makeChild(from: childBackup)
                modelContext.insert(child)
                existingChildren[child.id] = child
                insertedChildren += 1
            }

            for record in childBackup.feedings {
                insertIfNeeded(id: record.id, existingIds: &existingFeedingIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    FeedingRecord(id: record.id, timestamp: record.timestamp, type: FeedingType(rawValue: record.typeRaw) ?? .breastLeft, durationMinutes: record.durationMinutes, amountMl: record.amountMl, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.diapers {
                insertIfNeeded(id: record.id, existingIds: &existingDiaperIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    DiaperRecord(id: record.id, timestamp: record.timestamp, type: DiaperType(rawValue: record.typeRaw) ?? .wet, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.sleeps {
                insertIfNeeded(id: record.id, existingIds: &existingSleepIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    SleepRecord(id: record.id, startTime: record.startTime, endTime: record.endTime, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.growthRecords {
                insertIfNeeded(id: record.id, existingIds: &existingGrowthIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    GrowthRecord(id: record.id, date: record.date, dayAge: record.dayAge, weightKg: record.weightKg, heightCm: record.heightCm, headCircCm: record.headCircCm, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.milestones {
                insertIfNeeded(id: record.id, existingIds: &existingMilestoneIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    Milestone(id: record.id, emoji: record.emoji, title: record.title, date: record.date, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.jaundiceRecords {
                insertIfNeeded(id: record.id, existingIds: &existingJaundiceIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    JaundiceRecord(id: record.id, timestamp: record.timestamp, bilirubinLevel: record.bilirubinLevel, measurementSite: JaundiceRecord.MeasurementSite(rawValue: record.measurementSite) ?? .forehead, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.temperatureRecords {
                insertIfNeeded(id: record.id, existingIds: &existingTemperatureIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    TemperatureRecord(id: record.id, timestamp: record.timestamp, temperatureCelsius: record.temperatureCelsius, site: TemperatureSite(rawValue: record.siteRaw) ?? .armpit, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.breathingRecords {
                insertIfNeeded(id: record.id, existingIds: &existingBreathingIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    BreathingRecord(id: record.id, timestamp: record.timestamp, breathsPerMinute: record.breathsPerMinute, breathCount: record.breathCount, durationSeconds: record.durationSeconds ?? 60, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.medicineRecords {
                insertIfNeeded(id: record.id, existingIds: &existingMedicineIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    MedicineRecord(id: record.id, timestamp: record.timestamp, medicineName: record.medicineName, dosage: record.dosage, unit: record.unit, reason: record.reason, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.vaccineRecords {
                insertIfNeeded(id: record.id, existingIds: &existingVaccineIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    VaccineRecord(id: record.id, scheduleKey: record.scheduleKey, vaccineName: record.vaccineName, dose: record.dose, scheduledDate: record.scheduledDate, completedDate: record.completedDate, notes: record.notes, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.fetalMovementRecords {
                insertIfNeeded(id: record.id, existingIds: &existingFetalMovementIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    FetalMovementRecord(id: record.id, timestamp: record.timestamp, count: record.count, durationMinutes: record.durationMinutes, actualSeconds: record.actualSeconds, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.bloodPressureRecords {
                insertIfNeeded(id: record.id, existingIds: &existingBloodPressureIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    BloodPressureRecord(id: record.id, timestamp: record.timestamp, systolic: record.systolic, diastolic: record.diastolic, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.bloodSugarRecords {
                insertIfNeeded(id: record.id, existingIds: &existingBloodSugarIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    BloodSugarRecord(id: record.id, timestamp: record.timestamp, glucose: record.glucose, timing: BloodSugarTiming(rawValue: record.timingRaw) ?? .fasting, child: child)
                } into: { modelContext.insert($0) }
            }

            for record in childBackup.pregnancyWeightRecords {
                insertIfNeeded(id: record.id, existingIds: &existingPregnancyWeightIds, insertedRecords: &insertedRecords, skippedRecords: &skippedRecords) {
                    PregnancyWeightRecord(id: record.id, timestamp: record.timestamp, weightKg: record.weightKg, child: child)
                } into: { modelContext.insert($0) }
            }
        }

        try modelContext.save()
        return ImportSummary(insertedChildren: insertedChildren, mergedChildren: mergedChildren, insertedRecords: insertedRecords, skippedRecords: skippedRecords)
    }
    
    /// 清除所有 SwiftData 数据
    /// - Parameter modelContext: SwiftData 模型上下文
    static func clearAllData(from modelContext: ModelContext) throws {
        // 删除所有子记录(会自动级联删除相关记录)
        try modelContext.delete(model: Child.self)
        
        // 删除其他独立的记录(如果有孤立的记录)
        try modelContext.delete(model: FeedingRecord.self)
        try modelContext.delete(model: SleepRecord.self)
        try modelContext.delete(model: DiaperRecord.self)
        try modelContext.delete(model: GrowthRecord.self)
        try modelContext.delete(model: Milestone.self)
        try modelContext.delete(model: JaundiceRecord.self)
        try modelContext.delete(model: MedicineRecord.self)
        try modelContext.delete(model: VaccineRecord.self)
        try modelContext.delete(model: TemperatureRecord.self)
        try modelContext.delete(model: BreathingRecord.self)
        try modelContext.delete(model: FetalMovementRecord.self)
        try modelContext.delete(model: BloodPressureRecord.self)
        try modelContext.delete(model: BloodSugarRecord.self)
        try modelContext.delete(model: PregnancyWeightRecord.self)
        
        // 保存更改
        try modelContext.save()
    }
    
    /// 清除特定宝宝的所有数据
    /// - Parameters:
    ///   - child: 要删除的宝宝对象
    ///   - modelContext: SwiftData 模型上下文
    static func clearChild(_ child: Child, from modelContext: ModelContext) throws {
        modelContext.delete(child)
        try modelContext.save()
    }
    
    /// 重置应用到初始状态(仅用于开发/测试)
    /// - Parameter modelContext: SwiftData 模型上下文
    static func resetToInitialState(from modelContext: ModelContext) throws {
        try clearAllData(from: modelContext)
        print("✅ 所有数据已清除,应用已重置到初始状态")
    }

    private static func insertIfNeeded<T>(
        id: UUID,
        existingIds: inout Set<UUID>,
        insertedRecords: inout Int,
        skippedRecords: inout Int,
        makeRecord: () -> T,
        into insert: (T) -> Void
    ) {
        guard !existingIds.contains(id) else {
            skippedRecords += 1
            return
        }

        existingIds.insert(id)
        insert(makeRecord())
        insertedRecords += 1
    }

    private static func makeChildBackup(from child: Child) -> ChildBackup {
        ChildBackup(
            id: child.id,
            name: child.name,
            birthDate: child.birthDate,
            genderRaw: child.genderRaw,
            colorRaw: child.colorRaw,
            profileTypeRaw: child.profileTypeRaw,
            emergencyContactName: child.emergencyContactName,
            emergencyContactPhone: child.emergencyContactPhone,
            deliveryDate: child.deliveryDate,
            feedings: child.feedings.sorted { $0.timestamp < $1.timestamp }.map {
                FeedingBackup(id: $0.id, timestamp: $0.timestamp, typeRaw: $0.typeRaw, durationMinutes: $0.durationMinutes, amountMl: $0.amountMl, notes: $0.notes)
            },
            diapers: child.diapers.sorted { $0.timestamp < $1.timestamp }.map {
                DiaperBackup(id: $0.id, timestamp: $0.timestamp, typeRaw: $0.typeRaw)
            },
            sleeps: child.sleeps.sorted { $0.startTime < $1.startTime }.map {
                SleepBackup(id: $0.id, startTime: $0.startTime, endTime: $0.endTime)
            },
            growthRecords: child.growthRecords.sorted { $0.date < $1.date }.map {
                GrowthBackup(id: $0.id, date: $0.date, dayAge: $0.dayAge, weightKg: $0.weightKg, heightCm: $0.heightCm, headCircCm: $0.headCircCm)
            },
            milestones: child.milestones.sorted { $0.date < $1.date }.map {
                MilestoneBackup(id: $0.id, emoji: $0.emoji, title: $0.title, date: $0.date, notes: $0.notes)
            },
            jaundiceRecords: child.jaundiceRecords.sorted { $0.timestamp < $1.timestamp }.map {
                JaundiceBackup(id: $0.id, timestamp: $0.timestamp, bilirubinLevel: $0.bilirubinLevel, measurementSite: $0.measurementSite, notes: $0.notes)
            },
            temperatureRecords: child.temperatureRecords.sorted { $0.timestamp < $1.timestamp }.map {
                TemperatureBackup(id: $0.id, timestamp: $0.timestamp, temperatureCelsius: $0.temperatureCelsius, siteRaw: $0.siteRaw, notes: $0.notes)
            },
            breathingRecords: child.breathingRecords.sorted { $0.timestamp < $1.timestamp }.map {
                BreathingBackup(id: $0.id, timestamp: $0.timestamp, breathsPerMinute: $0.breathsPerMinute, breathCount: $0.breathCount, durationSeconds: $0.durationSeconds, notes: $0.notes)
            },
            medicineRecords: child.medicineRecords.sorted { $0.timestamp < $1.timestamp }.map {
                MedicineBackup(id: $0.id, timestamp: $0.timestamp, medicineName: $0.medicineName, dosage: $0.dosage, unit: $0.unit, reason: $0.reason, notes: $0.notes)
            },
            vaccineRecords: child.vaccineRecords.sorted { $0.scheduledDate < $1.scheduledDate }.map {
                VaccineBackup(id: $0.id, scheduleKey: $0.scheduleKey, vaccineName: $0.vaccineName, dose: $0.dose, scheduledDate: $0.scheduledDate, completedDate: $0.completedDate, notes: $0.notes)
            },
            fetalMovementRecords: child.fetalMovementRecords.sorted { $0.timestamp < $1.timestamp }.map {
                FetalMovementBackup(id: $0.id, timestamp: $0.timestamp, count: $0.count, durationMinutes: $0.durationMinutes, actualSeconds: $0.actualSeconds)
            },
            bloodPressureRecords: child.bloodPressureRecords.sorted { $0.timestamp < $1.timestamp }.map {
                BloodPressureBackup(id: $0.id, timestamp: $0.timestamp, systolic: $0.systolic, diastolic: $0.diastolic)
            },
            bloodSugarRecords: child.bloodSugarRecords.sorted { $0.timestamp < $1.timestamp }.map {
                BloodSugarBackup(id: $0.id, timestamp: $0.timestamp, glucose: $0.glucose, timingRaw: $0.timingRaw)
            },
            pregnancyWeightRecords: child.pregnancyWeightRecords.sorted { $0.timestamp < $1.timestamp }.map {
                PregnancyWeightBackup(id: $0.id, timestamp: $0.timestamp, weightKg: $0.weightKg)
            }
        )
    }

    private static func makeChild(from backup: ChildBackup) -> Child {
        Child(
            id: backup.id,
            name: backup.name,
            birthDate: backup.birthDate,
            gender: Child.Gender(rawValue: backup.genderRaw) ?? .female,
            color: Child.ChildColor(rawValue: backup.colorRaw) ?? .purple,
            profileType: Child.ProfileType(rawValue: backup.profileTypeRaw) ?? .baby,
            emergencyContactName: backup.emergencyContactName,
            emergencyContactPhone: backup.emergencyContactPhone,
            deliveryDate: backup.deliveryDate
        )
    }
}
