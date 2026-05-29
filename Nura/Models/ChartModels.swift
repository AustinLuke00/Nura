// ChartModels.swift
// Nura — Data models for charts and visualizations

import Foundation

// MARK: - GrowthPoint

/// 表示成长记录中的一个数据点
struct GrowthPoint: Identifiable {
    let id = UUID()
    let dayAge: Int
    let weight: Double
}

// MARK: - WeeklyFeedPoint

/// 表示每周喂养统计的一个数据点
struct WeeklyFeedPoint: Identifiable {
    let id = UUID()
    let day: String
    let count: Double
    let totalMl: Double
    let date: Date
    
    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - WeeklyDiaperPoint

/// 表示每周尿布更换统计的一个数据点
struct WeeklyDiaperPoint: Identifiable {
    let id = UUID()
    let day: String
    let wetCount: Double
    let dirtyCount: Double
    let bothCount: Double
    let date: Date
    
    var totalCount: Double {
        wetCount + dirtyCount + bothCount
    }
    
    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}
