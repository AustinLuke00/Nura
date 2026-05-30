// VaccineRecord.swift
// Nura — Vaccine schedule and SwiftData record model

import Foundation
import SwiftUI
import SwiftData

struct VaccineScheduleItem: Identifiable, Hashable {
    let key: String
    let name: String
    let dose: String
    let ageMonths: Int
    let note: String

    var id: String { key }

    func dueDate(for child: Child) -> Date {
        Calendar.current.date(byAdding: .month, value: ageMonths, to: child.birthDate) ?? child.birthDate
    }

    var dueAgeDisplay: String {
        ageMonths == 0 ? "出生后" : "\(ageMonths)月龄"
    }

    static let standard: [VaccineScheduleItem] = [
        VaccineScheduleItem(key: "hepb-1", name: "乙肝疫苗", dose: "第1剂", ageMonths: 0, note: "出生后尽早接种"),
        VaccineScheduleItem(key: "bcg-1", name: "卡介苗", dose: "1剂", ageMonths: 0, note: "通常出生后接种"),
        VaccineScheduleItem(key: "hepb-2", name: "乙肝疫苗", dose: "第2剂", ageMonths: 1, note: "满1月龄"),
        VaccineScheduleItem(key: "ipv-1", name: "脊灰灭活疫苗", dose: "第1剂", ageMonths: 2, note: "满2月龄"),
        VaccineScheduleItem(key: "ipv-2", name: "脊灰灭活疫苗", dose: "第2剂", ageMonths: 3, note: "满3月龄"),
        VaccineScheduleItem(key: "dtap-1", name: "百白破疫苗", dose: "第1剂", ageMonths: 3, note: "满3月龄"),
        VaccineScheduleItem(key: "opv-1", name: "脊灰减毒活疫苗", dose: "第1剂", ageMonths: 4, note: "满4月龄"),
        VaccineScheduleItem(key: "dtap-2", name: "百白破疫苗", dose: "第2剂", ageMonths: 4, note: "满4月龄"),
        VaccineScheduleItem(key: "dtap-3", name: "百白破疫苗", dose: "第3剂", ageMonths: 5, note: "满5月龄"),
        VaccineScheduleItem(key: "hepb-3", name: "乙肝疫苗", dose: "第3剂", ageMonths: 6, note: "满6月龄"),
        VaccineScheduleItem(key: "menac-1", name: "A群流脑疫苗", dose: "第1剂", ageMonths: 6, note: "满6月龄"),
        VaccineScheduleItem(key: "mmr-1", name: "麻腮风疫苗", dose: "第1剂", ageMonths: 8, note: "满8月龄"),
        VaccineScheduleItem(key: "je-1", name: "乙脑减毒活疫苗", dose: "第1剂", ageMonths: 8, note: "满8月龄"),
        VaccineScheduleItem(key: "menac-2", name: "A群流脑疫苗", dose: "第2剂", ageMonths: 9, note: "满9月龄"),
        VaccineScheduleItem(key: "hepa-1", name: "甲肝减毒活疫苗", dose: "1剂", ageMonths: 18, note: "满18月龄"),
        VaccineScheduleItem(key: "dtap-4", name: "百白破疫苗", dose: "第4剂", ageMonths: 18, note: "18-24月龄"),
        VaccineScheduleItem(key: "mmr-2", name: "麻腮风疫苗", dose: "第2剂", ageMonths: 18, note: "满18月龄"),
        VaccineScheduleItem(key: "je-2", name: "乙脑减毒活疫苗", dose: "第2剂", ageMonths: 24, note: "满2岁"),
        VaccineScheduleItem(key: "menacwy-1", name: "A+C群流脑疫苗", dose: "第1剂", ageMonths: 36, note: "满3岁"),
        VaccineScheduleItem(key: "dtap-ipv-1", name: "白破疫苗", dose: "1剂", ageMonths: 72, note: "满6岁"),
        VaccineScheduleItem(key: "menacwy-2", name: "A+C群流脑疫苗", dose: "第2剂", ageMonths: 72, note: "满6岁")
    ]
}

@Model
final class VaccineRecord {
    @Attribute(.unique) var id: UUID
    var scheduleKey: String
    var vaccineName: String
    var dose: String
    var scheduledDate: Date
    var completedDate: Date?
    var notes: String?

    var child: Child?

    init(
        id: UUID = UUID(),
        scheduleKey: String,
        vaccineName: String,
        dose: String,
        scheduledDate: Date,
        completedDate: Date? = nil,
        notes: String? = nil,
        child: Child? = nil
    ) {
        self.id = id
        self.scheduleKey = scheduleKey
        self.vaccineName = vaccineName
        self.dose = dose
        self.scheduledDate = scheduledDate
        self.completedDate = completedDate
        self.notes = notes
        self.child = child
    }

    var isCompleted: Bool { completedDate != nil }

    var status: Status {
        if isCompleted { return .done }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: scheduledDate).day ?? 0
        if days < 0 { return .overdue }
        if days <= 14 { return .soon }
        return .upcoming
    }

    var dateDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: completedDate ?? scheduledDate)
    }

    enum Status {
        case done, overdue, soon, upcoming

        var label: String {
            switch self {
            case .done: return "已接种"
            case .overdue: return "已逾期"
            case .soon: return "即将接种"
            case .upcoming: return "待接种"
            }
        }

        var color: Color {
            switch self {
            case .done: return .nuraSuccess
            case .overdue: return .nuraDanger
            case .soon: return .nuraWarning
            case .upcoming: return .secondary
            }
        }

        var iconName: String {
            switch self {
            case .done: return "checkmark.circle.fill"
            case .overdue: return "exclamationmark.triangle.fill"
            case .soon: return "clock.fill"
            case .upcoming: return "circle"
            }
        }
    }
}

struct VaccineReminderItem: Identifiable {
    let schedule: VaccineScheduleItem
    let record: VaccineRecord?
    let dueDate: Date

    var id: String { schedule.key }
    var isCompleted: Bool { record?.isCompleted == true }

    var daysUntilDue: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
    }

    var status: VaccineRecord.Status {
        if isCompleted { return .done }
        if daysUntilDue < 0 { return .overdue }
        if daysUntilDue <= 14 { return .soon }
        return .upcoming
    }

    var dueText: String {
        if isCompleted, let completedDate = record?.completedDate {
            return "已于 \(completedDate.nuraDateShortDisplay) 接种"
        }
        if daysUntilDue < 0 { return "已逾期 \(abs(daysUntilDue)) 天" }
        if daysUntilDue == 0 { return "今天到期" }
        return "\(daysUntilDue) 天后"
    }
}

extension Date {
    var nuraDateShortDisplay: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: self)
    }
}
