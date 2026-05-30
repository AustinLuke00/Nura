// CareStage.swift
// Nura — Stage-aware feature configuration

import Foundation
import SwiftUI

enum CareStage: String {
    case pregnancy
    case infant
    case child

    var title: String {
        switch self {
        case .pregnancy: return "孕期"
        case .infant: return "婴儿"
        case .child: return "儿童"
        }
    }

    var subtitle: String {
        switch self {
        case .pregnancy: return "产检、体征与用药更重要"
        case .infant: return "喂养、睡眠与基础健康记录"
        case .child: return "成长、作息与健康追踪"
        }
    }

    var icon: String {
        switch self {
        case .pregnancy: return "heart.circle.fill"
        case .infant: return "figure.child.circle.fill"
        case .child: return "figure.and.child.holdinghands"
        }
    }

    var color: Color {
        switch self {
        case .pregnancy: return Color(hex: "EC4899")
        case .infant: return .nuraPrimary
        case .child: return Color(hex: "0EA5E9")
        }
    }

    var primaryLogType: NuraLogType {
        switch self {
        case .pregnancy: return .fetalMovement
        case .infant: return .feeding
        case .child: return .growth
        }
    }

    var logTypes: [NuraLogType] {
        switch self {
        case .pregnancy:
            return [.fetalMovement, .bloodPressure, .bloodSugar, .pregnancyWeight, .temperature, .medicine]
        case .infant:
            return [.feeding, .diaper, .sleep, .jaundice, .growth, .vaccine, .medicine, .temperature, .breathing]
        case .child:
            return [.growth, .sleep, .vaccine, .medicine, .temperature, .breathing]
        }
    }
}

enum NuraLogType: String, Identifiable {
    case feeding = "喂奶"
    case diaper = "换尿布"
    case sleep = "睡眠"
    case jaundice = "黄疸"
    case growth = "生长记录"
    case medicine = "用药记录"
    case vaccine = "疫苗记录"
    case temperature = "体温记录"
    case breathing = "呼吸记录"
    case fetalMovement = "胎动记录"
    case bloodPressure = "血压记录"
    case bloodSugar = "血糖记录"
    case pregnancyWeight = "孕期体重"

    var id: String { rawValue }

    var shortTitle: String {
        switch self {
        case .feeding: return "喂奶"
        case .diaper: return "尿布"
        case .sleep: return "睡眠"
        case .jaundice: return "黄疸"
        case .growth: return "生长"
        case .medicine: return "用药"
        case .vaccine: return "疫苗"
        case .temperature: return "体温"
        case .breathing: return "呼吸"
        case .fetalMovement: return "胎动"
        case .bloodPressure: return "血压"
        case .bloodSugar: return "血糖"
        case .pregnancyWeight: return "体重"
        }
    }

    var icon: String {
        switch self {
        case .feeding: return "drop.fill"
        case .diaper: return "sparkles"
        case .sleep: return "moon.fill"
        case .jaundice: return "sun.max.fill"
        case .growth: return "chart.line.uptrend.xyaxis"
        case .medicine: return "pills.fill"
        case .vaccine: return "syringe.fill"
        case .temperature: return "thermometer.medium"
        case .breathing: return "lungs.fill"
        case .fetalMovement: return "hand.tap.fill"
        case .bloodPressure: return "heart.text.square.fill"
        case .bloodSugar: return "drop.degreesign.fill"
        case .pregnancyWeight: return "scalemass.fill"
        }
    }

    var color: Color {
        switch self {
        case .feeding: return .nuraPrimary
        case .diaper: return .nuraBlue
        case .sleep: return Color(hex: "818CF8")
        case .jaundice: return .nuraWarning
        case .growth: return .nuraSuccess
        case .medicine: return Color(hex: "F59E0B")
        case .vaccine: return Color(hex: "10B981")
        case .temperature: return Color(hex: "EF4444")
        case .breathing: return Color(hex: "14B8A6")
        case .fetalMovement: return Color(hex: "EC4899")
        case .bloodPressure: return Color(hex: "DC2626")
        case .bloodSugar: return Color(hex: "06B6D4")
        case .pregnancyWeight: return Color(hex: "8B5CF6")
        }
    }
}

struct PrenatalCheckupItem: Identifiable {
    let id = UUID()
    let week: Int
    let title: String
    let details: [String]

    static let schedule: [PrenatalCheckupItem] = [
        PrenatalCheckupItem(week: 6, title: "早孕确认", details: ["B超确认宫内妊娠", "基础血/尿检查"]),
        PrenatalCheckupItem(week: 12, title: "建档与NT", details: ["NT筛查", "血压、体重、基础化验"]),
        PrenatalCheckupItem(week: 16, title: "唐筛/无创", details: ["唐氏筛查或NIPT", "常规产检"]),
        PrenatalCheckupItem(week: 20, title: "大排畸预约", details: ["胎心、宫高腹围", "预约系统超声"]),
        PrenatalCheckupItem(week: 24, title: "糖耐检查", details: ["OGTT糖耐量筛查", "血常规、尿常规"]),
        PrenatalCheckupItem(week: 28, title: "晚孕评估", details: ["胎位、胎心", "贫血与血压评估"]),
        PrenatalCheckupItem(week: 32, title: "胎儿生长评估", details: ["B超评估生长", "胎心监护按需"]),
        PrenatalCheckupItem(week: 34, title: "胎心监护", details: ["NST胎心监护", "水肿、血压观察"]),
        PrenatalCheckupItem(week: 36, title: "分娩准备", details: ["GBS筛查按需", "确认胎位与入院准备"]),
        PrenatalCheckupItem(week: 37, title: "足月产检", details: ["每周产检", "留意宫缩、破水、胎动"]),
        PrenatalCheckupItem(week: 38, title: "足月复查", details: ["胎心监护", "评估分娩征兆"]),
        PrenatalCheckupItem(week: 39, title: "临产评估", details: ["胎心监护", "必要时评估羊水胎盘"]),
        PrenatalCheckupItem(week: 40, title: "预产期产检", details: ["胎心监护", "医生评估待产计划"])
    ]

    static func upcoming(for week: Int, within weeks: Int = 1) -> [PrenatalCheckupItem] {
        schedule.filter { $0.week >= week && $0.week <= week + weeks }
    }

    static func history(before week: Int) -> [PrenatalCheckupItem] {
        schedule.filter { $0.week < week }.reversed()
    }
}

extension Child {
    var careStage: CareStage {
        if profileType == .pregnancy { return .pregnancy }
        return ageInDays < 365 ? .infant : .child
    }

    var isPregnancy: Bool { careStage == .pregnancy }
    var hasDelivered: Bool { profileType == .pregnancy && deliveryDate != nil }
    var isInfant: Bool { careStage == .infant }
    var isChildStage: Bool { careStage == .child }

    var dateFieldTitle: String {
        isPregnancy ? "预产期" : "出生日期"
    }

    var stageDisplay: String {
        "\(careStage.title) · \(ageDisplay)"
    }

    var daysUntilDueDate: Int {
        if hasDelivered { return 0 }
        return max(Calendar.current.dateComponents([.day], from: Date(), to: birthDate).day ?? 0, 0)
    }

    var pregnancyWeekDisplay: String {
        if hasDelivered { return "已生产" }
        let dueToNow = Calendar.current.dateComponents([.day], from: Date(), to: birthDate).day ?? 0
        let gestationalDays = max(0, min(280, 280 - dueToNow))
        let week = max(1, gestationalDays / 7)
        let day = gestationalDays % 7
        return day > 0 ? "\(week)周\(day)天" : "\(week)周"
    }

    var gestationalWeek: Int {
        if hasDelivered { return 40 }
        let dueToNow = Calendar.current.dateComponents([.day], from: Date(), to: birthDate).day ?? 0
        let gestationalDays = max(0, min(280, 280 - dueToNow))
        return max(1, gestationalDays / 7)
    }

    var pregnancySizeInfo: PregnancySizeInfo {
        PregnancySizeInfo.info(for: gestationalWeek)
    }
}

struct PregnancySizeInfo {
    let weekRange: ClosedRange<Int>
    let sizeName: String
    let lengthText: String
    let weightText: String
    let situation: String
    let icon: String
    let color: Color

    static func info(for week: Int) -> PregnancySizeInfo {
        all.first { $0.weekRange.contains(week) } ?? all.last!
    }

    static let all: [PregnancySizeInfo] = [
        PregnancySizeInfo(
            weekRange: 1...8,
            sizeName: "小豆芽",
            lengthText: "< 2 cm",
            weightText: "很轻",
            situation: "神经管、心脏等基础结构正在快速形成。",
            icon: "leaf.fill",
            color: Color(hex: "22C55E")
        ),
        PregnancySizeInfo(
            weekRange: 9...12,
            sizeName: "小草莓",
            lengthText: "约 5-6 cm",
            weightText: "约 10-15 g",
            situation: "五官和四肢更清晰，开始有细小活动。",
            icon: "circle.hexagonpath.fill",
            color: Color(hex: "F43F5E")
        ),
        PregnancySizeInfo(
            weekRange: 13...16,
            sizeName: "牛油果",
            lengthText: "约 12 cm",
            weightText: "约 100 g",
            situation: "骨骼逐渐变硬，身体比例更接近宝宝模样。",
            icon: "oval.fill",
            color: Color(hex: "84CC16")
        ),
        PregnancySizeInfo(
            weekRange: 17...20,
            sizeName: "小香蕉",
            lengthText: "约 25 cm",
            weightText: "约 300 g",
            situation: "胎动更容易被感受到，听觉和触觉持续发展。",
            icon: "moon.fill",
            color: Color(hex: "EAB308")
        ),
        PregnancySizeInfo(
            weekRange: 21...24,
            sizeName: "玉米",
            lengthText: "约 30 cm",
            weightText: "约 600 g",
            situation: "肺部继续成熟，作息节律开始更明显。",
            icon: "capsule.portrait.fill",
            color: Color(hex: "F59E0B")
        ),
        PregnancySizeInfo(
            weekRange: 25...28,
            sizeName: "茄子",
            lengthText: "约 37 cm",
            weightText: "约 1 kg",
            situation: "大脑发育加速，眼睛开始有睁闭反应。",
            icon: "drop.fill",
            color: Color(hex: "8B5CF6")
        ),
        PregnancySizeInfo(
            weekRange: 29...32,
            sizeName: "南瓜",
            lengthText: "约 42 cm",
            weightText: "约 1.7 kg",
            situation: "脂肪储备增加，体温调节能力继续完善。",
            icon: "circle.fill",
            color: Color(hex: "F97316")
        ),
        PregnancySizeInfo(
            weekRange: 33...36,
            sizeName: "菠萝",
            lengthText: "约 47 cm",
            weightText: "约 2.6 kg",
            situation: "多数器官接近成熟，胎位和入盆情况值得关注。",
            icon: "seal.fill",
            color: Color(hex: "FACC15")
        ),
        PregnancySizeInfo(
            weekRange: 37...42,
            sizeName: "小西瓜",
            lengthText: "约 50 cm",
            weightText: "约 3.2 kg",
            situation: "已进入足月阶段，留意宫缩、破水和胎动变化。",
            icon: "circle.circle.fill",
            color: Color(hex: "10B981")
        )
    ]
}

// MARK: - Shared Stage UI

struct StageHeaderCard: View {
    var child: Child

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(child.careStage.color.opacity(0.15))
                    .frame(width: 46, height: 46)
                Image(systemName: child.careStage.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(child.careStage.color)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(child.careStage.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text(child.careStage.subtitle)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            NuraBadge(text: child.ageDisplay, color: child.careStage.color)
        }
        .nuraCard()
    }
}
