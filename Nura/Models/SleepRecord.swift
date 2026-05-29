// SleepRecord.swift
// Nura — Sleep record model with SwiftData

import Foundation
import SwiftUI
import SwiftData

@Model
final class SleepRecord {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?

    var child: Child?

    init(id: UUID = UUID(),
         startTime: Date = Date(),
         endTime: Date? = nil,
         child: Child? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.child = child
    }

    var isOngoing: Bool { endTime == nil }

    var durationHours: Double? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime) / 3600
    }

    var durationDisplay: String {
        guard let end = endTime else { return "进行中" }
        let mins = Int(end.timeIntervalSince(startTime) / 60)
        if mins < 60 { return "\(mins) 分钟" }
        let h = mins / 60; let m = mins % 60
        return m > 0 ? "\(h)h \(m)min" : "\(h)h"
    }

    var startFraction: CGFloat {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: startTime)
        return CGFloat((comps.hour ?? 0) * 60 + (comps.minute ?? 0)) / 1440
    }

    var durationFraction: CGFloat {
        guard let hrs = durationHours else { return 0.02 }
        return CGFloat(hrs / 24)
    }
}
