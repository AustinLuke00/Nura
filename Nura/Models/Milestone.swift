// Milestone.swift
// Nura — Milestone model with SwiftData

import Foundation
import SwiftData

@Model
final class Milestone {
    @Attribute(.unique) var id: UUID
    var emoji: String
    var title: String
    var date: Date
    var notes: String?

    var child: Child?

    init(id: UUID = UUID(),
         emoji: String,
         title: String,
         date: Date,
         notes: String? = nil,
         child: Child? = nil) {
        self.id = id
        self.emoji = emoji
        self.title = title
        self.date = date
        self.notes = notes
        self.child = child
    }
}
