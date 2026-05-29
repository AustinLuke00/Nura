// VaccineRecord.swift
// Nura — Vaccine record (value type, not persisted via SwiftData)

import Foundation
import SwiftUI

struct VaccineRecord: Identifiable {
    let id = UUID()
    var name: String
    var dueAgeDisplay: String
    var completedDate: Date?
    var daysUntilDue: Int?

    var status: Status {
        if completedDate != nil { return .done }
        if let d = daysUntilDue, d <= 7 { return .soon }
        return .upcoming
    }

    enum Status {
        case done, soon, upcoming

        var label: String {
            switch self {
            case .done: return "已完成"
            case .soon: return "即将到期"
            case .upcoming: return "待接种"
            }
        }

        var color: Color {
            switch self {
            case .done: return .nuraSuccess
            case .soon: return .nuraWarning
            case .upcoming: return .secondary
            }
        }

        var iconName: String {
            switch self {
            case .done: return "checkmark.circle.fill"
            case .soon: return "clock.fill"
            case .upcoming: return "circle"
            }
        }
    }
}
