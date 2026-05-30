// Theme.swift
// Nura — Design tokens, colors, and shared modifiers

import SwiftUI

// MARK: - Color Palette

extension Color {
    static let nuraPrimary      = Color(hex: "A78BFA")
    static let nuraPrimaryMid   = Color(hex: "7C3AED")
    static let nuraPrimaryLight = Color(hex: "EDE9FE")
    static let nuraPrimaryDim   = Color(hex: "DDD6FE")

    static let nuraSuccess = Color(hex: "10B981")
    static let nuraWarning = Color(hex: "F59E0B")
    static let nuraDanger  = Color(hex: "EF4444")
    static let nuraBlue    = Color(hex: "3B82F6")
    
    // Activity-specific colors
    static let nuraFeeding = Color(hex: "10B981")  // Green for feeding
    static let nuraSleep   = Color(hex: "8B5CF6")  // Purple for sleep
    static let nuraDiaper  = Color(hex: "F59E0B")  // Amber for diaper

    static let childPurple = Color(hex: "A78BFA")
    static let childPink   = Color(hex: "F9A8D4")
    static let childBlue   = Color(hex: "93C5FD")
    static let childTeal   = Color(hex: "5EEAD4")
    static let childAmber  = Color(hex: "FCD34D")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - ShapeStyle Extension

extension ShapeStyle where Self == Color {
    static var nuraPrimary: Color { Color.nuraPrimary }
    static var nuraPrimaryMid: Color { Color.nuraPrimaryMid }
    static var nuraPrimaryLight: Color { Color.nuraPrimaryLight }
    static var nuraPrimaryDim: Color { Color.nuraPrimaryDim }

    static var nuraSuccess: Color { Color.nuraSuccess }
    static var nuraWarning: Color { Color.nuraWarning }
    static var nuraDanger: Color { Color.nuraDanger }
    static var nuraBlue: Color { Color.nuraBlue }
    
    static var nuraFeeding: Color { Color.nuraFeeding }
    static var nuraSleep: Color { Color.nuraSleep }
    static var nuraDiaper: Color { Color.nuraDiaper }

    static var childPurple: Color { Color.childPurple }
    static var childPink: Color { Color.childPink }
    static var childBlue: Color { Color.childBlue }
    static var childTeal: Color { Color.childTeal }
    static var childAmber: Color { Color.childAmber }
}

// MARK: - Typography

extension Font {
    static func nuraTitle() -> Font    { .system(size: 22, weight: .semibold, design: .rounded) }
    static func nuraHeadline() -> Font { .system(size: 15, weight: .semibold, design: .rounded) }
    static func nuraBody() -> Font     { .system(size: 14, weight: .regular,  design: .rounded) }
    static func nuraCaption() -> Font  { .system(size: 12, weight: .medium,   design: .rounded) }
    static func nuraMono() -> Font     { .system(size: 13, weight: .medium,   design: .monospaced) }
    static func nuraStat() -> Font     { .system(size: 24, weight: .bold,     design: .rounded) }
}

// MARK: - View Modifiers

struct NuraCard: ViewModifier {
    var padding: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(16)
    }
}

struct NuraSectionHeader: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.nuraCaption())
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}

extension View {
    func nuraCard(padding: CGFloat = 14) -> some View { modifier(NuraCard(padding: padding)) }
    func nuraSectionHeader() -> some View { modifier(NuraSectionHeader()) }
}

extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

// MARK: - Shared Components

struct StatBox: View {
    var label: String
    var value: String
    var unit: String
    var color: Color = .nuraPrimary
    var icon: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(color.opacity(0.7))
                }
                Text(label)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.nuraStat())
                    .foregroundStyle(.primary)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.nuraCaption())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

struct NuraBadge: View {
    var text: String
    var color: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .foregroundStyle(color)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.12))
            .cornerRadius(20)
    }
}

struct SectionLabel: View {
    var icon: String
    var title: String
    var iconColor: Color = .nuraPrimary

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(iconColor)
            Text(title)
                .nuraSectionHeader()
        }
    }
}
struct EmptyStateRow: View {
    var text: String
    
    var body: some View {
        HStack {
            Spacer()
            Text(text)
                .font(.nuraCaption())
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
