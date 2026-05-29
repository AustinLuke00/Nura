// TodayView.swift
// Nura — Today tab: daily overview, records, and quick-log

import SwiftUI
import SwiftData

// MARK: - TodayView

struct TodayView: View {
    @Binding var selectedChildId: UUID?

    @Query private var children: [Child]
    @Query private var allFeedings: [FeedingRecord]
    @Query private var allDiapers: [DiaperRecord]
    @Query private var allSleeps: [SleepRecord]
    @Query private var allJaundice: [JaundiceRecord]
    @Query private var allTemperatures: [TemperatureRecord]
    @Query private var allBreathing: [BreathingRecord]

    @State private var logType: LogType?

    enum LogType: String, Identifiable {
        case feeding = "喂奶"
        case diaper = "换尿布"
        case sleep = "睡眠"
        case jaundice = "黄疸"
        case growth = "生长记录"
        case medicine = "用药记录"
        case temperature = "体温记录"
        case breathing = "呼吸记录"
        var id: String { rawValue }
    }

    var selectedChild: Child? {
        guard let id = selectedChildId else { return children.first }
        // Ensure the child still exists and hasn't been deleted
        return children.first(where: { $0.id == id }) ?? children.first
    }

    private var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    var todayFeedings: [FeedingRecord] {
        guard let child = selectedChild else { return [] }
        return allFeedings
            .filter { $0.child?.id == child.id && $0.timestamp >= todayStart }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var todayDiapers: [DiaperRecord] {
        guard let child = selectedChild else { return [] }
        return allDiapers
            .filter { $0.child?.id == child.id && $0.timestamp >= todayStart }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var todaySleeps: [SleepRecord] {
        guard let child = selectedChild else { return [] }
        return allSleeps
            .filter { $0.child?.id == child.id && $0.startTime >= todayStart }
            .sorted { $0.startTime > $1.startTime }
    }
    
    var recentJaundice: [JaundiceRecord] {
        guard let child = selectedChild else { return [] }
        // 显示最近7天的黄疸记录
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return allJaundice
            .filter { $0.child?.id == child.id && $0.timestamp >= sevenDaysAgo }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var todayTemperatures: [TemperatureRecord] {
        guard let child = selectedChild else { return [] }
        return allTemperatures
            .filter { $0.child?.id == child.id && $0.timestamp >= todayStart }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var todayBreathing: [BreathingRecord] {
        guard let child = selectedChild else { return [] }
        return allBreathing
            .filter { $0.child?.id == child.id && $0.timestamp >= todayStart }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var totalSleepHours: Double {
        todaySleeps.compactMap(\.durationHours).reduce(0, +)
    }
    
    var totalFeedingMl: Double {
        todayFeedings.compactMap(\.amountMl).reduce(0, +)
    }

    var sleepDisplay: String {
        guard totalSleepHours > 0 else { return "0h" }
        let h = Int(totalSleepHours)
        let m = Int((totalSleepHours - Double(h)) * 60)
        return m > 0 ? "\(h)h\(m)m" : "\(h)h"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    TodayOverviewCard(
                        feedCount: todayFeedings.count,
                        totalMl: totalFeedingMl,
                        diaperCount: todayDiapers.count,
                        sleepDisplay: sleepDisplay,
                        latestTemperature: todayTemperatures.first,
                        latestBreathing: todayBreathing.first
                    )
                    FeedingCard(records: todayFeedings)
                    SleepCard(records: todaySleeps, totalHours: totalSleepHours)
                    DiaperCard(records: todayDiapers)
                    TemperatureCard(records: todayTemperatures, onAddTap: { logType = .temperature })
                    BreathingCard(records: todayBreathing, child: selectedChild, onAddTap: { logType = .breathing })
                    
                    // 黄疸卡片 - 只在有新生儿时显示
                    if let child = selectedChild, child.isNewborn {
                        JaundiceCard(records: recentJaundice, onAddTap: { logType = .jaundice })
                    }
                    
                    QuickLogGrid { type in logType = type }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("NURA")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .tracking(2.5)
                            .foregroundStyle(.nuraPrimary)
                        Text(todayDateDisplay)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    ChildSwitcherView(selectedChildId: $selectedChildId)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { logType = .feeding } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 30, height: 30)
                            .background(.nuraPrimary)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .sheet(item: $logType) { type in
            QuickLogSheet(logType: type, selectedChild: selectedChild)
        }
    }

    var todayDateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }
}

// MARK: - TodayOverviewCard

struct TodayOverviewCard: View {
    var feedCount: Int
    var totalMl: Double
    var diaperCount: Int
    var sleepDisplay: String
    var latestTemperature: TemperatureRecord?
    var latestBreathing: BreathingRecord?
    
    var mlDisplay: String {
        totalMl > 0 ? "\(Int(totalMl))" : "--"
    }

    var temperatureDisplay: String {
        latestTemperature?.temperatureDisplay ?? "今日无体温数据"
    }

    var breathingDisplay: String {
        latestBreathing?.rateDisplay ?? "今日无呼吸记录"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.nuraWarning)
                Text("今日概览")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatBox(label: "喂奶次数",  value: "\(feedCount)",  unit: "次", color: .nuraPrimary, icon: "drop.fill")
                StatBox(label: "喂奶总量", value: mlDisplay, unit: "ml", color: .nuraBlue, icon: "waterbottle.fill")
                StatBox(label: "换尿布", value: "\(diaperCount)", unit: "次", color: Color(hex: "818CF8"), icon: "sparkles")
                StatBox(label: "睡眠",  value: sleepDisplay,    unit: "",   color: .nuraSuccess, icon: "moon.fill")
                OverviewTextBox(label: "最近体温", value: temperatureDisplay, color: Color(hex: "EF4444"), icon: "thermometer.medium")
                OverviewTextBox(label: "呼吸记录", value: breathingDisplay, color: Color(hex: "14B8A6"), icon: "lungs.fill")
            }
        }
        .nuraCard()
    }
}

struct OverviewTextBox: View {
    var label: String
    var value: String
    var color: Color
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color.opacity(0.7))
                Text(label)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
        .padding(12)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

// MARK: - FeedingCard

struct FeedingCard: View {
    var records: [FeedingRecord]
    @Environment(\.modelContext) private var modelContext
    @State private var showAllRecords = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.nuraPrimary)
                Text("喂奶记录")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            if records.isEmpty {
                EmptyStateRow(text: "今天还没有喂奶记录")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(records.prefix(4).enumerated()), id: \.element.id) { i, record in
                        FeedingRow(record: record, onDelete: {
                            deleteRecord(record)
                        })
                        if i < min(records.count, 4) - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                if records.count > 4 {
                    Button {
                        showAllRecords = true
                    } label: {
                        Text("查看全部 \(records.count) 条")
                            .font(.nuraCaption())
                            .foregroundStyle(.nuraPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)
                }
            }
        }
        .nuraCard()
        .sheet(isPresented: $showAllRecords) {
            AllFeedingRecordsView(records: records)
        }
    }
    
    private func deleteRecord(_ record: FeedingRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

struct FeedingRow: View {
    var record: FeedingRecord
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(record.type.color.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: record.type.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(record.type.color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Text(record.detailDisplay)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(record.timeDisplay)
                .font(.nuraMono())
                .foregroundStyle(.nuraPrimary)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .confirmationDialog("删除记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这条喂奶记录吗？")
        }
    }
}

// MARK: - SleepCard

struct SleepCard: View {
    var records: [SleepRecord]
    var totalHours: Double
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "818CF8"))
                    Text("今日睡眠")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                if totalHours > 0 {
                    Text(String(format: "共 %.1f h", totalHours))
                        .font(.nuraCaption())
                        .foregroundStyle(.secondary)
                }
            }

            SleepTimelineBar(records: records)

            HStack(spacing: 0) {
                Text("0时"); Spacer(); Text("6时"); Spacer()
                Text("12时"); Spacer(); Text("18时"); Spacer(); Text("24时")
            }
            .font(.system(size: 9, weight: .regular, design: .rounded))
            .foregroundStyle(Color(UIColor.tertiaryLabel))

            if records.isEmpty {
                EmptyStateRow(text: "今天还没有睡眠记录")
            } else {
                VStack(spacing: 6) {
                    ForEach(records) { record in
                        SleepRecordRow(record: record, onDelete: {
                            deleteRecord(record)
                        })
                    }
                }
                .padding(.top, 4)
            }
        }
        .nuraCard()
    }

    private func deleteRecord(_ record: SleepRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }

    func sleepTimeRange(_ r: SleepRecord) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let start = f.string(from: r.startTime)
        let end = r.endTime.map { f.string(from: $0) } ?? "进行中"
        return "\(start) – \(end)"
    }
}

// MARK: - SleepRecordRow

struct SleepRecordRow: View {
    var record: SleepRecord
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "818CF8").opacity(0.7))
            Text(sleepTimeRange(record))
                .font(.nuraCaption())
                .foregroundStyle(.secondary)
            Spacer()
            Text(record.durationDisplay)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: "818CF8"))
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .confirmationDialog("删除记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这条睡眠记录吗？")
        }
    }
    
    func sleepTimeRange(_ r: SleepRecord) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let start = f.string(from: r.startTime)
        let end = r.endTime.map { f.string(from: $0) } ?? "进行中"
        return "\(start) – \(end)"
    }
}

struct SleepTimelineBar: View {
    var records: [SleepRecord]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(UIColor.tertiarySystemFill))
                ForEach(records) { record in
                    let x = record.startFraction * geo.size.width
                    let w = max(record.durationFraction * geo.size.width, 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "818CF8"), Color(hex: "A78BFA")],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: w)
                        .offset(x: x)
                }
            }
        }
        .frame(height: 12)
    }
}

// MARK: - DiaperCard

struct DiaperCard: View {
    var records: [DiaperRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.nuraBlue)
                    Text("换尿布")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                Text("今日 \(records.count) 次")
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            if records.isEmpty {
                EmptyStateRow(text: "今天还没有记录")
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(records.prefix(5)) { record in
                            DiaperChip(record: record, onDelete: {
                                deleteRecord(record)
                            })
                        }
                    }
                }
            }
        }
        .nuraCard()
    }
    
    private func deleteRecord(_ record: DiaperRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - DiaperChip

struct DiaperChip: View {
    var record: DiaperRecord
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(record.type.emoji).font(.system(size: 14))
            Text(record.timeDisplay)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(record.type.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(record.type.color.opacity(0.08))
        .cornerRadius(8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .confirmationDialog("删除记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这条尿布记录吗？")
        }
    }
}

// MARK: - TemperatureCard

struct TemperatureCard: View {
    var records: [TemperatureRecord]
    var onAddTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showAllRecords = false

    var latestRecord: TemperatureRecord? { records.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "thermometer.medium")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "EF4444"))
                    Text("体温记录")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                if records.count > 1 {
                    Button("全部") { showAllRecords = true }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
                Button(action: onAddTap) {
                    Label("记录", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
            }

            if let latest = latestRecord {
                HealthMetricRow(
                    icon: latest.site.icon,
                    value: latest.temperatureDisplay,
                    label: latest.status.label,
                    detail: latest.fullDateDisplay + " · " + latest.site.rawValue,
                    color: latest.status.color,
                    onDelete: { deleteRecord(latest) }
                )
            } else {
                EmptyStateRow(text: "今天还没有体温记录")
            }
        }
        .nuraCard()
        .sheet(isPresented: $showAllRecords) {
            AllTemperatureRecordsView(records: records)
        }
    }

    private func deleteRecord(_ record: TemperatureRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - BreathingCard

struct BreathingCard: View {
    var records: [BreathingRecord]
    var child: Child?
    var onAddTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showAllRecords = false

    var latestRecord: BreathingRecord? { records.first }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "lungs.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "14B8A6"))
                    Text("呼吸记录")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                if records.count > 1 {
                    Button("全部") { showAllRecords = true }
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "14B8A6"))
                }
                Button(action: onAddTap) {
                    Label("记录", systemImage: "plus.circle.fill")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(Color(hex: "14B8A6"))
                }
            }

            if let latest = latestRecord {
                let status = latest.status(for: child)
                HealthMetricRow(
                    icon: "lungs.fill",
                    value: latest.rateDisplay,
                    label: status.label,
                    detail: latest.fullDateDisplay,
                    color: status.color,
                    onDelete: { deleteRecord(latest) }
                )
            } else {
                EmptyStateRow(text: "今天还没有呼吸记录")
            }
        }
        .nuraCard()
        .sheet(isPresented: $showAllRecords) {
            AllBreathingRecordsView(records: records, child: child)
        }
    }

    private func deleteRecord(_ record: BreathingRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

struct HealthMetricRow: View {
    var icon: String
    var value: String
    var label: String
    var detail: String
    var color: Color
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(color)
                    Text(label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(color)
                }
                Text(detail)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .confirmationDialog("删除记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这条记录吗？")
        }
    }
}

// MARK: - JaundiceCard

struct JaundiceCard: View {
    var records: [JaundiceRecord]
    var onAddTap: () -> Void
    @Environment(\.modelContext) private var modelContext
    @State private var showAllRecords = false
    
    var latestRecord: JaundiceRecord? { records.first }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.nuraWarning)
                    Text("黄疸监测")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                Spacer()
                HStack(spacing: 12) {
                    if records.count > 1 {
                        Button {
                            showAllRecords = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "list.bullet")
                                    .font(.system(size: 12))
                                Text("全部")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(.nuraWarning.opacity(0.8))
                        }
                    }
                    
                    Button(action: onAddTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 14))
                            Text("记录")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.nuraWarning)
                    }
                }
            }
            
            if let latest = latestRecord {
                // 最新记录概览
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("最近测量")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(latest.levelDisplay)
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(latest.riskLevel.color)
                            Text("mg/dL")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Text(latest.dateDisplay + " · " + latest.site.rawValue)
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.tertiary)
                    }
                    
                    Spacer()
                    
                    // 风险等级指示器
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(latest.riskLevel.color.opacity(0.15))
                                .frame(width: 50, height: 50)
                            Image(systemName: latest.riskLevel == .high || latest.riskLevel == .moderate ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(latest.riskLevel.color)
                        }
                        Text(latest.riskLevel.label)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(latest.riskLevel.color)
                    }
                }
                .padding(12)
                .background(latest.riskLevel.color.opacity(0.06))
                .cornerRadius(12)
                
                // 7天趋势
                if records.count > 1 {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("近7天趋势")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(records.prefix(7).reversed()) { record in
                                VStack(spacing: 3) {
                                    // 简单的柱状图
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            LinearGradient(
                                                colors: [record.riskLevel.color, record.riskLevel.color.opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 20, height: CGFloat(record.bilirubinLevel * 4))
                                    
                                    Text(String(format: "%.0f", record.bilirubinLevel))
                                        .font(.system(size: 8, weight: .medium, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 80)
                    }
                }
            } else {
                EmptyStateRow(text: "还没有黄疸记录")
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("💡 黄疸监测提示")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("新生儿黄疸是常见现象，建议定期监测胆红素水平。正常值通常在 5-12 mg/dL 之间。")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                }
                .padding(10)
                .background(Color.nuraWarning.opacity(0.08))
                .cornerRadius(10)
            }
        }
        .nuraCard()
        .sheet(isPresented: $showAllRecords) {
            AllJaundiceRecordsView(records: records)
        }
    }
    
    private func deleteRecord(_ record: JaundiceRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - QuickLogGrid

struct QuickLogGrid: View {
    var onTap: (TodayView.LogType) -> Void

    private let items: [(icon: String, title: String, color: Color, type: TodayView.LogType)] = [
        ("drop.fill", "喂奶",  .nuraPrimary,          .feeding),
        ("sparkles", "尿布",  .nuraBlue,              .diaper),
        ("moon.fill", "睡眠",  Color(hex: "818CF8"),   .sleep),
        ("sun.max.fill", "黄疸", .nuraWarning,          .jaundice),
        ("chart.line.uptrend.xyaxis", "生长", .nuraSuccess, .growth),
        ("pills.fill", "用药", Color(hex: "F59E0B"),   .medicine),
        ("thermometer.medium", "体温", Color(hex: "EF4444"), .temperature),
        ("lungs.fill", "呼吸", Color(hex: "14B8A6"), .breathing),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.nuraWarning)
                Text("快速记录")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                spacing: 10
            ) {
                ForEach(items, id: \.title) { item in
                    QuickLogButton(icon: item.icon, title: item.title, color: item.color) {
                        onTap(item.type)
                    }
                }
            }
        }
        .nuraCard()
    }
}

struct QuickLogButton: View {
    var icon: String
    var title: String
    var color: Color
    var action: () -> Void
    @State private var pressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(color.opacity(0.08))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(pressed ? 0.94 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents(onPress: { pressed = true }, onRelease: { pressed = false })
    }
}

// MARK: - QuickLogSheet

struct QuickLogSheet: View {
    var logType: TodayView.LogType
    var selectedChild: Child?

    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var feedingType: FeedingType = .breastLeft
    @State private var feedingDuration: Double = 10
    @State private var feedingAmount: Double = 80
    @State private var diaperType: DiaperType = .wet
    @State private var sleepStart: Date = Date().addingTimeInterval(-3600)
    @State private var sleepEnd: Date = Date()
    @State private var sleepOngoing: Bool = false
    @State private var jaundiceLevel: Double = 8.0
    @State private var jaundiceSite: JaundiceRecord.MeasurementSite = .forehead
    @State private var temperature: Double = 36.8
    @State private var temperatureSite: TemperatureSite = .armpit
    @State private var breathingRate: Double = 30
    @State private var time: Date = Date()
    @State private var date: Date = Date()
    
    // 生长记录
    @State private var weightKg: String = ""
    @State private var heightCm: String = ""
    @State private var headCircCm: String = ""
    
    // 用药记录
    @State private var medicineName: String = ""
    @State private var dosage: String = ""
    @State private var medicineUnit: String = "ml"
    @State private var reason: String = ""
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        switch logType {
                        case .feeding:
                            FeedingLogForm(
                                type: $feedingType,
                                duration: $feedingDuration,
                                amount: $feedingAmount,
                                time: $time
                            )
                        case .diaper:
                            DiaperLogForm(type: $diaperType, time: $time)
                        case .sleep:
                            SleepLogForm(
                                startTime: $sleepStart,
                                endTime: $sleepEnd,
                                isOngoing: $sleepOngoing
                            )
                        case .jaundice:
                            JaundiceLogForm(
                                level: $jaundiceLevel,
                                site: $jaundiceSite,
                                time: $time
                            )
                        case .temperature:
                            TemperatureLogForm(
                                temperature: $temperature,
                                site: $temperatureSite,
                                time: $time
                            )
                        case .breathing:
                            BreathingLogForm(
                                rate: $breathingRate,
                                time: $time
                            )
                        case .growth:
                            GrowthLogForm(
                                weightKg: $weightKg,
                                heightCm: $heightCm,
                                headCircCm: $headCircCm,
                                date: $date
                            )
                        case .medicine:
                            MedicineLogForm(
                                medicineName: $medicineName,
                                dosage: $dosage,
                                unit: $medicineUnit,
                                reason: $reason,
                                notes: $notes,
                                time: $time
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle(logType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { saveRecord() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .tint(.nuraPrimary)
    }

    func saveRecord() {
        guard let child = selectedChild else { dismiss(); return }
        switch logType {
        case .feeding:
            let record = FeedingRecord(
                timestamp: time,
                type: feedingType,
                durationMinutes: feedingType.isBreast ? Int(feedingDuration) : nil,
                amountMl: feedingType.isBreast ? nil : feedingAmount,
                child: child
            )
            modelContext.insert(record)
        case .diaper:
            modelContext.insert(DiaperRecord(timestamp: time, type: diaperType, child: child))
        case .sleep:
            modelContext.insert(SleepRecord(
                startTime: sleepStart,
                endTime: sleepOngoing ? nil : sleepEnd,
                child: child
            ))
        case .jaundice:
            modelContext.insert(JaundiceRecord(
                timestamp: time,
                bilirubinLevel: jaundiceLevel,
                measurementSite: jaundiceSite,
                child: child
            ))
        case .temperature:
            modelContext.insert(TemperatureRecord(
                timestamp: time,
                temperatureCelsius: temperature,
                site: temperatureSite,
                child: child
            ))
        case .breathing:
            modelContext.insert(BreathingRecord(
                timestamp: time,
                breathsPerMinute: Int(breathingRate),
                child: child
            ))
        case .growth:
            // 计算宝宝日龄
            let dayAge = Calendar.current.dateComponents([.day], from: child.birthDate, to: date).day ?? 0
            
            // 安全转换字符串到 Double，如果为空或无效则为 nil
            let weight = weightKg.isEmpty ? nil : Double(weightKg)
            let height = heightCm.isEmpty ? nil : Double(heightCm)
            let headCirc = headCircCm.isEmpty ? nil : Double(headCircCm)
            
            // 至少需要一个有效数据
            guard weight != nil || height != nil || headCirc != nil else {
                dismiss()
                return
            }
            
            let record = GrowthRecord(
                date: date,
                dayAge: dayAge,
                weightKg: weight,
                heightCm: height,
                headCircCm: headCirc,
                child: child
            )
            modelContext.insert(record)
        case .medicine:
            let record = MedicineRecord(
                timestamp: time,
                medicineName: medicineName,
                dosage: dosage,
                unit: medicineUnit,
                reason: reason.isEmpty ? nil : reason,
                notes: notes.isEmpty ? nil : notes,
                child: child
            )
            modelContext.insert(record)
        }
        dismiss()
    }
}

// MARK: - Log Forms

struct FeedingLogForm: View {
    @Binding var type: FeedingType
    @Binding var duration: Double
    @Binding var amount: Double
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("喂养方式").nuraSectionHeader()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(FeedingType.allCases) { ft in
                        HStack(spacing: 6) {
                            Image(systemName: ft.iconName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(type == ft ? ft.color : .secondary)
                            Text(ft.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(type == ft ? ft.color.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                        .foregroundStyle(type == ft ? ft.color : .secondary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(type == ft ? ft.color.opacity(0.4) : Color.clear, lineWidth: 1.5)
                        )
                        .onTapGesture { withAnimation { type = ft } }
                    }
                }
            }
            .nuraCard()

            if type.isBreast {
                SliderFormCard(title: "时长", unit: "分钟", value: $duration,
                               range: 1...60, step: 1, color: .nuraPrimary)
            } else {
                SliderFormCard(title: "奶量", unit: "ml", value: $amount,
                               range: 10...300, step: 5, color: .nuraBlue)
            }
            TimePickerCard(time: $time)
        }
    }
}

struct DiaperLogForm: View {
    @Binding var type: DiaperType
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("类型").nuraSectionHeader()
                HStack(spacing: 10) {
                    ForEach(DiaperType.allCases) { dt in
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(type == dt ? dt.color.opacity(0.15) : Color(UIColor.tertiarySystemFill))
                                    .frame(width: 50, height: 50)
                                Image(systemName: dt.iconName)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(type == dt ? dt.color : .secondary)
                            }
                            Text(dt.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundStyle(type == dt ? dt.color : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(type == dt ? dt.color.opacity(0.08) : Color.clear)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(type == dt ? dt.color.opacity(0.5) : Color.clear, lineWidth: 2)
                        )
                        .onTapGesture { withAnimation { type = dt } }
                    }
                }
            }
            .nuraCard()
            TimePickerCard(time: $time)
        }
    }
}

struct SleepLogForm: View {
    @Binding var startTime: Date
    @Binding var endTime: Date
    @Binding var isOngoing: Bool

    var body: some View {
        VStack(spacing: 14) {
            VStack(spacing: 0) {
                DatePickerRow(label: "入睡时间", date: $startTime)
                Divider().padding(.leading, 16)
                Toggle(isOn: $isOngoing) {
                    Text("正在睡觉").font(.nuraBody())
                }
                .tint(.nuraPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                if !isOngoing {
                    Divider().padding(.leading, 16)
                    DatePickerRow(label: "醒来时间", date: $endTime)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(14)

            if !isOngoing {
                let dur = endTime.timeIntervalSince(startTime) / 3600
                HStack {
                    Image(systemName: "moon.fill").foregroundStyle(Color(hex: "818CF8"))
                    Text("睡眠时长：\(String(format: "%.1f", max(dur, 0))) 小时")
                        .font(.nuraBody())
                    Spacer()
                }
                .padding(12)
                .background(Color(hex: "818CF8").opacity(0.08))
                .cornerRadius(10)
            }
        }
    }
}

struct JaundiceLogForm: View {
    @Binding var level: Double
    @Binding var site: JaundiceRecord.MeasurementSite
    @Binding var time: Date
    
    var riskLevel: JaundiceRecord.RiskLevel {
        if level < 5 { return .low }
        if level < 12 { return .normal }
        if level < 15 { return .moderate }
        return .high
    }
    
    var body: some View {
        VStack(spacing: 14) {
            // 胆红素水平滑块
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("胆红素水平").nuraSectionHeader()
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", level))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(riskLevel.color)
                        Text("mg/dL")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Slider(value: $level, in: 0...25, step: 0.1)
                    .tint(riskLevel.color)
                
                // 风险等级指示
                HStack(spacing: 8) {
                    Image(systemName: riskLevel == .high || riskLevel == .moderate ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(riskLevel.color)
                    Text(riskLevel.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(riskLevel.color)
                    Spacer()
                    Text(riskDescription)
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(riskLevel.color.opacity(0.08))
                .cornerRadius(10)
            }
            .nuraCard()
            
            // 测量部位
            VStack(alignment: .leading, spacing: 8) {
                Text("测量部位").nuraSectionHeader()
                VStack(spacing: 8) {
                    ForEach(JaundiceRecord.MeasurementSite.allCases) { s in
                        HStack(spacing: 10) {
                            Image(systemName: s.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(site == s ? Color.nuraWarning : .secondary)
                                .frame(width: 30)
                            
                            Text(s.rawValue)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(site == s ? .primary : .secondary)
                            
                            Spacer()
                            
                            if site == s {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.nuraWarning)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(site == s ? Color.nuraWarning.opacity(0.08) : Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(site == s ? Color.nuraWarning.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture { withAnimation { site = s } }
                    }
                }
            }
            .nuraCard()
            
            TimePickerCard(time: $time)
            
            // 参考信息
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.blue)
                    Text("参考范围")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    referenceRow(label: "正常", range: "5-12 mg/dL", color: .nuraSuccess)
                    referenceRow(label: "偏高", range: "12-15 mg/dL", color: .nuraWarning)
                    referenceRow(label: "较高", range: ">15 mg/dL", color: .nuraDanger)
                }
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(10)
        }
    }
    
    var riskDescription: String {
        switch riskLevel {
        case .low: return "略低于正常值"
        case .normal: return "正常范围内"
        case .moderate: return "需要关注"
        case .high: return "建议就医"
        }
    }
    
    func referenceRow(label: String, range: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(range)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }
}

struct TemperatureLogForm: View {
    @Binding var temperature: Double
    @Binding var site: TemperatureSite
    @Binding var time: Date

    var status: TemperatureStatus {
        if temperature < 36.0 { return .low }
        if temperature <= 37.3 { return .normal }
        if temperature <= 38.0 { return .elevated }
        if temperature <= 39.0 { return .fever }
        return .highFever
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("体温").nuraSectionHeader()
                    Spacer()
                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text(String(format: "%.1f", temperature))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(status.color)
                        Text("°C")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                Slider(value: $temperature, in: 34...42, step: 0.1)
                    .tint(status.color)

                HStack(spacing: 8) {
                    Image(systemName: status == .normal ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(status.color)
                    Text(status.label)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(status.color)
                    Spacer()
                }
                .padding(10)
                .background(status.color.opacity(0.08))
                .cornerRadius(10)
            }
            .nuraCard()

            VStack(alignment: .leading, spacing: 8) {
                Text("测量部位").nuraSectionHeader()
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(TemperatureSite.allCases) { item in
                        HStack(spacing: 6) {
                            Image(systemName: item.icon)
                            Text(item.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(site == item ? Color(hex: "EF4444").opacity(0.12) : Color(UIColor.tertiarySystemFill))
                        .foregroundStyle(site == item ? Color(hex: "EF4444") : .secondary)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(site == item ? Color(hex: "EF4444").opacity(0.35) : Color.clear, lineWidth: 1)
                        )
                        .onTapGesture { withAnimation { site = item } }
                    }
                }
            }
            .nuraCard()

            TimePickerCard(time: $time)
        }
    }
}

struct BreathingLogForm: View {
    @Binding var rate: Double
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            SliderFormCard(
                title: "呼吸频率",
                unit: "次/分",
                value: $rate,
                range: 10...80,
                step: 1,
                color: Color(hex: "14B8A6")
            )

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "14B8A6"))
                Text("请在宝宝安静状态下记录 1 分钟呼吸次数")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            TimePickerCard(time: $time)
        }
    }
}

struct GrowthLogForm: View {
    @Binding var weightKg: String
    @Binding var heightCm: String
    @Binding var headCircCm: String
    @Binding var date: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("生长数据").nuraSectionHeader()
                
                VStack(spacing: 12) {
                    HStack {
                        Label("体重", systemImage: "scalemass")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        TextField("输入体重", text: $weightKg)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.nuraBody())
                        Text("kg")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    HStack {
                        Label("身高", systemImage: "ruler")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        TextField("输入身高", text: $heightCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.nuraBody())
                        Text("cm")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    HStack {
                        Label("头围", systemImage: "circle.dashed")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)
                        Spacer()
                        TextField("输入头围", text: $headCircCm)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.nuraBody())
                        Text("cm")
                            .font(.nuraBody())
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                }
            }
            .nuraCard()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("记录日期").nuraSectionHeader()
                DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .nuraCard()
            
            // 提示信息
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.blue)
                Text("至少填写一项数据")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
        }
    }
}

struct MedicineLogForm: View {
    @Binding var medicineName: String
    @Binding var dosage: String
    @Binding var unit: String
    @Binding var reason: String
    @Binding var notes: String
    @Binding var time: Date
    
    private let units = ["ml", "片", "粒", "滴", "mg", "g"]

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("药品信息").nuraSectionHeader()
                
                VStack(spacing: 0) {
                    HStack {
                        Text("药品名称").font(.nuraBody())
                        Spacer()
                        TextField("请输入", text: $medicineName)
                            .multilineTextAlignment(.trailing)
                            .font(.nuraBody())
                    }
                    .padding(16)
                    
                    Divider().padding(.leading, 16)
                    
                    HStack {
                        Text("剂量").font(.nuraBody())
                        Spacer()
                        TextField("请输入", text: $dosage)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.nuraBody())
                            .frame(width: 80)
                        
                        Menu {
                            ForEach(units, id: \.self) { u in
                                Button(u) { unit = u }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(unit)
                                    .font(.nuraBody())
                                    .foregroundStyle(.nuraPrimary)
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.nuraPrimary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                }
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
            .nuraCard()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("用药原因（可选）").nuraSectionHeader()
                TextField("如：发烧、咳嗽等", text: $reason)
                    .font(.nuraBody())
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .nuraCard()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("备注（可选）").nuraSectionHeader()
                TextField("其他说明", text: $notes, axis: .vertical)
                    .font(.nuraBody())
                    .lineLimit(3)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .nuraCard()
            
            HStack {
                Label("用药时间", systemImage: "clock")
                    .font(.nuraBody())
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $time, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                    .tint(.nuraPrimary)
            }
            .nuraCard()
        }
    }
}

// MARK: - Shared Form Components

struct SliderFormCard: View {
    var title: String
    var unit: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title).nuraSectionHeader()
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
            }
            Slider(value: $value, in: range, step: step).tint(color)
        }
        .nuraCard()
    }
}

struct TimePickerCard: View {
    @Binding var time: Date

    var body: some View {
        HStack {
            Label("时间", systemImage: "clock")
                .font(.nuraBody())
                .foregroundStyle(.secondary)
            Spacer()
            DatePicker("", selection: $time, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .tint(.nuraPrimary)
        }
        .nuraCard()
    }
}

struct DatePickerRow: View {
    var label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label).font(.nuraBody())
            Spacer()
            DatePicker("", selection: $date, displayedComponents: [.hourAndMinute])
                .labelsHidden()
                .tint(.nuraPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }
}

// MARK: - Press Gesture

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

// MARK: - AllFeedingRecordsView

struct AllFeedingRecordsView: View {
    var records: [FeedingRecord]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    FeedingRow(record: record, onDelete: {
                        deleteRecord(record)
                    })
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("今日喂奶记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.nuraPrimary)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
    
    private func deleteRecord(_ record: FeedingRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - AllJaundiceRecordsView

struct AllJaundiceRecordsView: View {
    var records: [JaundiceRecord]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    JaundiceRecordRow(record: record, onDelete: {
                        deleteRecord(record)
                    })
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("黄疸监测记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.nuraWarning)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
    
    private func deleteRecord(_ record: JaundiceRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

struct JaundiceRecordRow: View {
    var record: JaundiceRecord
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧风险等级指示器
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(record.riskLevel.color.opacity(0.15))
                    .frame(width: 50, height: 50)
                Image(systemName: record.riskLevel == .high || record.riskLevel == .moderate ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(record.riskLevel.color)
            }
            
            // 中间信息
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(record.levelDisplay)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(record.riskLevel.color)
                    Text("mg/dL")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 4) {
                    Text(record.dateDisplay)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("·")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                    Text(record.site.rawValue)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 右侧风险标签
            Text(record.riskLevel.label)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(record.riskLevel.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(record.riskLevel.color.opacity(0.15))
                .cornerRadius(12)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirmation = true
            } label: {
                Label("删除记录", systemImage: "trash")
            }
        }
        .confirmationDialog("删除黄疸记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除此黄疸记录吗？")
        }
    }
}

// MARK: - AllTemperatureRecordsView

struct AllTemperatureRecordsView: View {
    var records: [TemperatureRecord]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    HealthMetricRow(
                        icon: record.site.icon,
                        value: record.temperatureDisplay,
                        label: record.status.label,
                        detail: record.fullDateDisplay + " · " + record.site.rawValue,
                        color: record.status.color,
                        onDelete: { deleteRecord(record) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("体温记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color(hex: "EF4444"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private func deleteRecord(_ record: TemperatureRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - AllBreathingRecordsView

struct AllBreathingRecordsView: View {
    var records: [BreathingRecord]
    var child: Child?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            List {
                ForEach(records) { record in
                    let status = record.status(for: child)
                    HealthMetricRow(
                        icon: "lungs.fill",
                        value: record.rateDisplay,
                        label: status.label,
                        detail: record.fullDateDisplay,
                        color: status.color,
                        onDelete: { deleteRecord(record) }
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }
            }
            .listStyle(.plain)
            .navigationTitle("呼吸记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Color(hex: "14B8A6"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    private func deleteRecord(_ record: BreathingRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var selectedChildId: UUID? = nil
    TodayView(selectedChildId: $selectedChildId)
        .modelContainer(for: [
            Child.self, FeedingRecord.self, SleepRecord.self,
            DiaperRecord.self, GrowthRecord.self, Milestone.self,
            JaundiceRecord.self, MedicineRecord.self,
            TemperatureRecord.self, BreathingRecord.self
        ], inMemory: true)
}
