// DataManager.swift
// Nura — SwiftData 数据管理工具

import Foundation
import SwiftData

/// 用于管理 SwiftData 数据的工具类
@MainActor
struct DataManager {
    
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
        try modelContext.delete(model: TemperatureRecord.self)
        try modelContext.delete(model: BreathingRecord.self)
        
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
}
