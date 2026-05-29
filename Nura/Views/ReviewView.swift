// ReviewView.swift
// Nura — Review tab: growth charts, feeding trends, vaccine timeline

import SwiftUI
import SwiftData
import Charts

// MARK: - ReviewView

struct ReviewView: View {
    @Binding var selectedChildId: UUID?

    @Query private var children: [Child]
    @Query private var allGrowthRecords: [GrowthRecord]
    @Query private var allFeedings: [FeedingRecord]
    @Query private var allSleeps: [SleepRecord]
    @Query private var allDiapers: [DiaperRecord]
    @Query private var allMedicines: [MedicineRecord]
    @Query private var allTemperatures: [TemperatureRecord]
    @Query private var allBreathing: [BreathingRecord]

    @State private var timeFilter: TimeFilter = .week

    enum TimeFilter: String, CaseIterable {
        case week = "7天"
        case month = "月"
        case all = "全部"
    }

    var selectedChild: Child? {
        guard let id = selectedChildId else { return children.first }
        // Ensure the child still exists and hasn't been deleted
        return children.first(where: { $0.id == id }) ?? children.first
    }

    var cutoffDate: Date {
        let cal = Calendar.current
        switch timeFilter {
        case .week:  return cal.date(byAdding: .day, value: -7, to: Date())!
        case .month: return cal.date(byAdding: .month, value: -1, to: Date())!
        case .all:   return .distantPast
        }
    }

    var childGrowthRecords: [GrowthRecord] {
        guard let child = selectedChild else { return [] }
        return allGrowthRecords.filter { $0.child?.id == child.id }.sorted { $0.date < $1.date }
    }

    var childFeedings: [FeedingRecord] {
        guard let child = selectedChild else { return [] }
        return allFeedings.filter { $0.child?.id == child.id && $0.timestamp >= cutoffDate }
    }

    var childSleeps: [SleepRecord] {
        guard let child = selectedChild else { return [] }
        return allSleeps.filter { $0.child?.id == child.id && $0.startTime >= cutoffDate }
    }
    
    var childDiapers: [DiaperRecord] {
        guard let child = selectedChild else { return [] }
        return allDiapers.filter { $0.child?.id == child.id && $0.timestamp >= cutoffDate }
    }

    var childDiaperHistory: [DiaperRecord] {
        guard let child = selectedChild else { return [] }
        return allDiapers.filter { $0.child?.id == child.id }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var childMedicines: [MedicineRecord] {
        guard let child = selectedChild else { return [] }
        return allMedicines.filter { $0.child?.id == child.id && $0.timestamp >= cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var childTemperatures: [TemperatureRecord] {
        guard let child = selectedChild else { return [] }
        return allTemperatures.filter { $0.child?.id == child.id }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var filteredTemperatures: [TemperatureRecord] {
        childTemperatures.filter { $0.timestamp >= cutoffDate }
    }

    var childBreathing: [BreathingRecord] {
        guard let child = selectedChild else { return [] }
        return allBreathing.filter { $0.child?.id == child.id }
            .sorted { $0.timestamp < $1.timestamp }
    }

    var filteredBreathing: [BreathingRecord] {
        childBreathing.filter { $0.timestamp >= cutoffDate }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    TimeFilterPicker(selection: $timeFilter)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    GrowthCard(
                        growthRecords: childGrowthRecords,
                        childName: selectedChild?.name ?? ""
                    )

                    FeedingTrendCard(feedings: childFeedings)

                    DiaperTrendCard(diapers: childDiapers, historyRecords: childDiaperHistory)

                    SleepTrendCard(sleeps: childSleeps)

                    TemperatureTrendCard(records: filteredTemperatures, historyRecords: childTemperatures)

                    BreathingTrendCard(records: filteredBreathing, historyRecords: childBreathing, child: selectedChild)
                    
                    MedicineCard(medicines: childMedicines)

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
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
                        Text("成长回顾")
                            .font(.system(size: 11, weight: .regular, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    ChildSwitcherView(selectedChildId: $selectedChildId)
                }
            }
        }
    }
}

// MARK: - TimeFilterPicker

struct TimeFilterPicker: View {
    @Binding var selection: ReviewView.TimeFilter

    var body: some View {
        HStack(spacing: 6) {
            ForEach(ReviewView.TimeFilter.allCases, id: \.self) { filter in
                Button(filter.rawValue) {
                    withAnimation(.spring(response: 0.25)) { selection = filter }
                }
                .font(.system(size: 13,
                              weight: selection == filter ? .semibold : .regular,
                              design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(selection == filter ? Color.nuraPrimary : Color(UIColor.tertiarySystemFill))
                .foregroundStyle(selection == filter ? .white : .secondary)
                .cornerRadius(20)
            }
            Spacer()
        }
    }
}

// MARK: - GrowthCard

struct GrowthCard: View {
    var growthRecords: [GrowthRecord]
    var childName: String
    @Environment(\.modelContext) private var modelContext

    var latestRecord: GrowthRecord? { growthRecords.last }

    var weightPoints: [GrowthPoint] {
        growthRecords.compactMap { r in
            guard let w = r.weightKg else { return nil }
            return GrowthPoint(dayAge: r.dayAge, weight: w)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "chart.line.uptrend.xyaxis", title: "生长曲线")
                Spacer()
                if !growthRecords.isEmpty {
                    Menu {
                        ForEach(growthRecords.reversed()) { record in
                            Button(role: .destructive) {
                                deleteGrowthRecord(record)
                            } label: {
                                Label {
                                    Text(record.dateDisplay)
                                } icon: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if weightPoints.isEmpty {
                EmptyStateRow(text: "暂无生长记录，添加第一条记录吧")
            } else {
                Chart {
                    ForEach(weightPoints) { point in
                        LineMark(
                            x: .value("天", point.dayAge),
                            y: .value("体重", point.weight)
                        )
                        .foregroundStyle(Color.nuraPrimary)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("天", point.dayAge),
                            y: .value("体重", point.weight)
                        )
                        .foregroundStyle(Color.nuraPrimary)
                        .symbolSize(28)
                    }
                    if let last = weightPoints.last {
                        PointMark(
                            x: .value("天", last.dayAge),
                            y: .value("体重", last.weight)
                        )
                        .annotation(position: .top, spacing: 4) {
                            Text(String(format: "%.1f kg", last.weight))
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.nuraPrimary)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { val in
                        AxisValueLabel {
                            if let day = val.as(Int.self) {
                                Text("第\(day)天").font(.system(size: 9, design: .rounded))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(UIColor.separator).opacity(0.4))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { val in
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(String(format: "%.1f", v))
                                    .font(.system(size: 9, design: .rounded))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(UIColor.separator).opacity(0.4))
                    }
                }
                .frame(height: 150)

                if !childName.isEmpty {
                    HStack(spacing: 16) {
                        LegendDot(color: .nuraPrimary, label: childName)
                    }
                }
            }

            Divider()

            HStack(spacing: 8) {
                GrowthStatCell(
                    icon: "scalemass", label: "体重",
                    value: latestRecord?.weightKg.map { String(format: "%.1f kg", $0) } ?? "--",
                    color: .nuraPrimary
                )
                GrowthStatCell(
                    icon: "ruler", label: "身高",
                    value: latestRecord?.heightCm.map { String(format: "%.0f cm", $0) } ?? "--",
                    color: .nuraBlue
                )
                GrowthStatCell(
                    icon: "circle.dashed", label: "头围",
                    value: latestRecord?.headCircCm.map { String(format: "%.0f cm", $0) } ?? "--",
                    color: .nuraSuccess
                )
            }
        }
        .nuraCard()
    }

    private func deleteGrowthRecord(_ record: GrowthRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

struct GrowthStatCell: View {
    var icon: String
    var label: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 10)).foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(value).font(.system(size: 15, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07))
        .cornerRadius(10)
    }
}

struct LegendDot: View {
    var color: Color
    var label: String
    var dashed = false

    var body: some View {
        HStack(spacing: 5) {
            if dashed {
                HStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule().fill(color).frame(width: 5, height: 2)
                    }
                }
            } else {
                Circle().fill(color).frame(width: 6, height: 6)
            }
            Text(label)
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - FeedingTrendCard

struct FeedingTrendCard: View {
    var feedings: [FeedingRecord]
    @State private var selectedDay: String?
    @State private var showDayDetails = false

    var weeklyData: [WeeklyFeedPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { offset -> WeeklyFeedPoint in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayFeedings = feedings.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let count = dayFeedings.count
            let totalMl = dayFeedings.compactMap(\.amountMl).reduce(0, +)
            let weekday = calendar.component(.weekday, from: date)
            let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            return WeeklyFeedPoint(day: names[weekday - 1], count: Double(count), totalMl: totalMl, date: date)
        }
    }

    var averageCount: Double {
        let nonZero = weeklyData.filter { $0.count > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.map(\.count).reduce(0, +) / Double(nonZero.count)
    }
    
    var averageMl: Double {
        let nonZero = weeklyData.filter { $0.totalMl > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.map(\.totalMl).reduce(0, +) / Double(nonZero.count)
    }

    var hasData: Bool { weeklyData.contains { $0.count > 0 } }
    
    var selectedDayData: WeeklyFeedPoint? {
        guard let day = selectedDay else { return nil }
        return weeklyData.first(where: { $0.day == day })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "drop.fill", title: "喂养趋势", iconColor: .nuraPrimary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    if averageCount > 0 {
                        Text("日均 \(String(format: "%.1f", averageCount)) 次")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.nuraPrimary)
                    }
                    if averageMl > 0 {
                        Text("日均 \(Int(averageMl)) ml")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.nuraBlue)
                    }
                }
            }

            if !hasData {
                EmptyStateRow(text: "暂无喂养数据")
            } else {
                // 交互式图表区域
                VStack(spacing: 8) {
                    Chart(weeklyData) { point in
                        BarMark(
                            x: .value("日期", point.day),
                            y: .value("次数", point.count)
                        )
                        .foregroundStyle(
                            selectedDay == point.day
                                ? Color.nuraPrimary
                                : Color.nuraPrimary.opacity(0.6)
                        )
                        .cornerRadius(5)
                        .annotation(position: .top, spacing: 2) {
                            if point.count > 0 {
                                VStack(spacing: 1) {
                                    // 喂养次数
                                    Text("\(Int(point.count))")
                                        .font(.system(size: 8, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color.nuraPrimary)
                                    // 奶量（如果有）
                                    if point.totalMl > 0 {
                                        Text("\(Int(point.totalMl))ml")
                                            .font(.system(size: 7, weight: .medium, design: .rounded))
                                            .foregroundStyle(Color.nuraBlue)
                                    }
                                }
                            }
                        }

                        if averageCount > 0 {
                            RuleMark(y: .value("平均", averageCount))
                                .foregroundStyle(Color.nuraPrimary.opacity(0.4))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { val in
                            AxisValueLabel {
                                if let d = val.as(String.self) {
                                    Text(d).font(.system(size: 9, design: .rounded))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 4)) { val in
                            AxisValueLabel {
                                if let v = val.as(Double.self) {
                                    Text("\(Int(v))").font(.system(size: 9, design: .rounded))
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color(UIColor.separator).opacity(0.3))
                        }
                    }
                    .frame(height: 140)
                    .chartXSelection(value: $selectedDay)
                }
                
                // 显示选中日期的详细信息
                if let dayData = selectedDayData {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.nuraPrimary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(dayData.day) · \(dayData.dateDisplay)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            HStack(spacing: 12) {
                                Text("喂养 \(Int(dayData.count)) 次")
                                    .font(.system(size: 10, design: .rounded))
                                    .foregroundStyle(.secondary)
                                if dayData.totalMl > 0 {
                                    Text("共 \(Int(dayData.totalMl)) ml")
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .padding(10)
                    .background(Color.nuraPrimary.opacity(0.05))
                    .cornerRadius(10)
                }
                
                if averageMl > 0 {
                    HStack(spacing: 16) {
                        LegendDot(color: .nuraPrimary, label: "喂养次数")
                        LegendDot(color: .nuraBlue, label: "奶量 (ml)")
                    }
                    .padding(.top, 4)
                }
            }
        }
        .nuraCard()
        .sheet(isPresented: $showDayDetails) {
            if let dayData = selectedDayData {
                DayFeedingDetailsView(feedings: feedings, date: dayData.date)
            }
        }
    }
}

// MARK: - SleepTrendCard

struct SleepTrendCard: View {
    var sleeps: [SleepRecord]

    var weeklyData: [(day: String, hours: Double)] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { offset -> (String, Double) in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let hours = sleeps
                .filter { $0.startTime >= dayStart && $0.startTime < dayEnd }
                .compactMap(\.durationHours)
                .reduce(0, +)
            let weekday = calendar.component(.weekday, from: date)
            let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            return (names[weekday - 1], hours)
        }
    }

    var averageHours: Double {
        let nonZero = weeklyData.filter { $0.hours > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.map(\.hours).reduce(0, +) / Double(nonZero.count)
    }

    var hasData: Bool { weeklyData.contains { $0.hours > 0 } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "moon.fill", title: "睡眠趋势",
                             iconColor: Color(hex: "818CF8"))
                Spacer()
                if averageHours > 0 {
                    Text(String(format: "日均 %.1f h", averageHours))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "818CF8"))
                }
            }

            if !hasData {
                EmptyStateRow(text: "暂无睡眠数据")
            } else {
                Chart(weeklyData, id: \.day) { point in
                    LineMark(
                        x: .value("日期", point.day),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(Color(hex: "818CF8"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("日期", point.day),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "818CF8").opacity(0.25),
                                     Color(hex: "818CF8").opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("日期", point.day),
                        y: .value("小时", point.hours)
                    )
                    .foregroundStyle(Color(hex: "818CF8"))
                    .symbolSize(20)
                }
                .chartXAxis {
                    AxisMarks { val in
                        AxisValueLabel {
                            if let d = val.as(String.self) {
                                Text(d).font(.system(size: 9, design: .rounded))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) { val in
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text("\(Int(v))h").font(.system(size: 9, design: .rounded))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(UIColor.separator).opacity(0.3))
                    }
                }
                .frame(height: 110)
            }
        }
        .nuraCard()
    }
}

// MARK: - TemperatureTrendCard

struct TemperatureTrendCard: View {
    var records: [TemperatureRecord]
    var historyRecords: [TemperatureRecord]
    @State private var showHistory = false

    var latestRecord: TemperatureRecord? { historyRecords.last }

    var averageTemperature: Double {
        guard !records.isEmpty else { return 0 }
        return records.map(\.temperatureCelsius).reduce(0, +) / Double(records.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "thermometer.medium", title: "体温趋势", iconColor: Color(hex: "EF4444"))
                Spacer()
                Button {
                    showHistory = true
                } label: {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "EF4444"))
                }
            }

            if records.isEmpty {
                EmptyStateRow(text: "暂无体温数据")
            } else {
                Chart(records) { record in
                    LineMark(
                        x: .value("时间", record.timestamp),
                        y: .value("体温", record.temperatureCelsius)
                    )
                    .foregroundStyle(Color(hex: "EF4444"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("时间", record.timestamp),
                        y: .value("体温", record.temperatureCelsius)
                    )
                    .foregroundStyle(record.status.color)
                    .symbolSize(26)

                    RuleMark(y: .value("发热线", 37.3))
                        .foregroundStyle(Color.nuraWarning.opacity(0.45))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.system(size: 9, design: .rounded))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let temp = value.as(Double.self) {
                                Text(String(format: "%.1f", temp))
                                    .font(.system(size: 9, design: .rounded))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(UIColor.separator).opacity(0.3))
                    }
                }
                .frame(height: 130)

                HStack(spacing: 8) {
                    if let latest = latestRecord {
                        HealthSummaryCell(label: "最近", value: latest.temperatureDisplay, color: latest.status.color)
                    }
                    HealthSummaryCell(label: "平均", value: String(format: "%.1f°C", averageTemperature), color: Color(hex: "EF4444"))
                    HealthSummaryCell(label: "记录", value: "\(records.count) 次", color: .secondary)
                }
            }
        }
        .nuraCard()
        .sheet(isPresented: $showHistory) {
            TemperatureHistoryView(records: historyRecords)
        }
    }
}

// MARK: - BreathingTrendCard

struct BreathingTrendCard: View {
    var records: [BreathingRecord]
    var historyRecords: [BreathingRecord]
    var child: Child?
    @State private var showHistory = false

    var latestRecord: BreathingRecord? { historyRecords.last }

    var averageRate: Double {
        guard !records.isEmpty else { return 0 }
        return Double(records.map(\.breathsPerMinute).reduce(0, +)) / Double(records.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(icon: "lungs.fill", title: "呼吸趋势", iconColor: Color(hex: "14B8A6"))
                Spacer()
                Button {
                    showHistory = true
                } label: {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(hex: "14B8A6"))
                }
            }

            if records.isEmpty {
                EmptyStateRow(text: "暂无呼吸数据")
            } else {
                Chart(records) { record in
                    LineMark(
                        x: .value("时间", record.timestamp),
                        y: .value("呼吸", record.breathsPerMinute)
                    )
                    .foregroundStyle(Color(hex: "14B8A6"))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    PointMark(
                        x: .value("时间", record.timestamp),
                        y: .value("呼吸", record.breathsPerMinute)
                    )
                    .foregroundStyle(record.status(for: child).color)
                    .symbolSize(26)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel(format: .dateTime.month().day())
                            .font(.system(size: 9, design: .rounded))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisValueLabel {
                            if let rate = value.as(Int.self) {
                                Text("\(rate)")
                                    .font(.system(size: 9, design: .rounded))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color(UIColor.separator).opacity(0.3))
                    }
                }
                .frame(height: 130)

                HStack(spacing: 8) {
                    if let latest = latestRecord {
                        HealthSummaryCell(label: "最近", value: latest.rateDisplay, color: latest.status(for: child).color)
                    }
                    HealthSummaryCell(label: "平均", value: "\(Int(averageRate.rounded())) 次/分", color: Color(hex: "14B8A6"))
                    HealthSummaryCell(label: "记录", value: "\(records.count) 次", color: .secondary)
                }
            }
        }
        .nuraCard()
        .sheet(isPresented: $showHistory) {
            BreathingHistoryView(records: historyRecords, child: child)
        }
    }
}

struct HealthSummaryCell: View {
    var label: String
    var value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.07))
        .cornerRadius(10)
    }
}

// MARK: - MedicineCard

struct MedicineCard: View {
    var medicines: [MedicineRecord]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(icon: "pills.fill", title: "用药记录", iconColor: Color(hex: "F59E0B"))
                Spacer()
                if !medicines.isEmpty {
                    Text("共 \(medicines.count) 次")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            if medicines.isEmpty {
                EmptyStateRow(text: "暂无用药记录")
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(medicines.prefix(5).enumerated()), id: \.element.id) { i, medicine in
                        MedicineRow(medicine: medicine, onDelete: {
                            deleteRecord(medicine)
                        })
                        if i < min(medicines.count, 5) - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                if medicines.count > 5 {
                    Button("查看全部 \(medicines.count) 条") {}
                        .font(.nuraCaption())
                        .foregroundStyle(Color(hex: "F59E0B"))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 6)
                }
            }
        }
        .nuraCard()
    }
    
    private func deleteRecord(_ record: MedicineRecord) {
        withAnimation {
            modelContext.delete(record)
        }
    }
}

struct MedicineRow: View {
    var medicine: MedicineRecord
    var onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "F59E0B").opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: "pills.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "F59E0B"))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(medicine.medicineName)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                HStack(spacing: 4) {
                    Text(medicine.dosageDisplay)
                        .font(.nuraCaption())
                        .foregroundStyle(.secondary)
                    if let reason = medicine.reason {
                        Text("·")
                            .font(.nuraCaption())
                            .foregroundStyle(.secondary)
                        Text(reason)
                            .font(.nuraCaption())
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(medicine.dateDisplay)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "F59E0B"))
                Text(medicine.timeDisplay)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
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
        .confirmationDialog("删除用药记录", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                onDelete()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除「\(medicine.medicineName)」的用药记录吗？")
        }
    }
}

// MARK: - DiaperTrendCard

struct DiaperTrendCard: View {
    var diapers: [DiaperRecord]
    var historyRecords: [DiaperRecord]
    @State private var showHistory = false

    var weeklyData: [WeeklyDiaperPoint] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<7).map { offset -> WeeklyDiaperPoint in
            let date = calendar.date(byAdding: .day, value: -(6 - offset), to: today)!
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            let dayDiapers = diapers.filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            let wetCount = dayDiapers.filter { $0.type == .wet }.count
            let dirtyCount = dayDiapers.filter { $0.type == .dirty }.count
            let bothCount = dayDiapers.filter { $0.type == .both }.count
            let weekday = calendar.component(.weekday, from: date)
            let names = ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
            return WeeklyDiaperPoint(
                day: names[weekday - 1],
                wetCount: Double(wetCount),
                dirtyCount: Double(dirtyCount),
                bothCount: Double(bothCount),
                date: date
            )
        }
    }

    var totalCount: Int {
        diapers.count
    }
    
    var averageCount: Double {
        let nonZero = weeklyData.filter { $0.totalCount > 0 }
        guard !nonZero.isEmpty else { return 0 }
        let total = nonZero.reduce(0.0) { $0 + $1.totalCount }
        return total / Double(nonZero.count)
    }

    var hasData: Bool { weeklyData.contains { $0.totalCount > 0 } }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("尿布趋势")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
                Spacer()
                if averageCount > 0 {
                    Text("日均 \(String(format: "%.1f", averageCount)) 次")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraBlue)
                }
                if !historyRecords.isEmpty {
                    Button {
                        showHistory = true
                    } label: {
                        Text("历史")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.nuraBlue)
                    }
                }
            }

            if !hasData {
                EmptyStateRow(text: "暂无尿布数据")
            } else {
                VStack(spacing: 10) {
                    DiaperDailyTable(points: weeklyData)
                }
            }
        }
        .nuraCard()
        .sheet(isPresented: $showHistory) {
            DiaperHistoryView(records: historyRecords)
        }
    }
}

struct DiaperDailyTable: View {
    var points: [WeeklyDiaperPoint]

    var body: some View {
        VStack(spacing: 0) {
            DiaperDailyTableRow(
                day: "日期",
                wet: "小便",
                dirty: "大便",
                both: "混合",
                total: "总计",
                isHeader: true
            )

            ForEach(points) { point in
                Divider().padding(.leading, 8)
                DiaperDailyTableRow(
                    day: point.day,
                    wet: "\(Int(point.wetCount))",
                    dirty: "\(Int(point.dirtyCount))",
                    both: "\(Int(point.bothCount))",
                    total: "\(Int(point.totalCount))",
                    isHeader: false
                )
            }
        }
        .background(Color(UIColor.tertiarySystemFill).opacity(0.55))
        .cornerRadius(10)
    }
}

struct DiaperDailyTableRow: View {
    var day: String
    var wet: String
    var dirty: String
    var both: String
    var total: String
    var isHeader: Bool

    var body: some View {
        HStack(spacing: 0) {
            Text(day)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(wet)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isHeader ? Color.secondary : Color.nuraBlue)
            Text(dirty)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isHeader ? Color.secondary : Color.nuraWarning)
            Text(both)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isHeader ? Color.secondary : Color(hex: "8B5CF6"))
            Text(total)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .foregroundStyle(isHeader ? Color.secondary : Color.primary)
        }
        .font(.system(size: isHeader ? 10 : 11, weight: isHeader ? .medium : .semibold, design: .rounded))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .foregroundStyle(isHeader ? Color.secondary : Color.primary)
    }
}

struct DiaperHistoryView: View {
    var records: [DiaperRecord]
    @Environment(\.dismiss) var dismiss

    var dailySummaries: [DailyDiaperSummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: records) { record in
            calendar.startOfDay(for: record.timestamp)
        }

        return grouped.map { date, dayRecords in
            DailyDiaperSummary(
                date: date,
                wetCount: dayRecords.filter { $0.type == .wet }.count,
                dirtyCount: dayRecords.filter { $0.type == .dirty }.count,
                bothCount: dayRecords.filter { $0.type == .both }.count
            )
        }
        .sorted { $0.date > $1.date }
    }

    var wetCount: Int {
        records.filter { $0.type == .wet }.count
    }

    var dirtyCount: Int {
        records.filter { $0.type == .dirty }.count
    }

    var bothCount: Int {
        records.filter { $0.type == .both }.count
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        DiaperHistorySummaryCell(label: "总记录", value: records.count, color: .nuraBlue)
                        DiaperHistorySummaryCell(label: "小便", value: wetCount, color: .nuraBlue)
                    }
                    HStack(spacing: 8) {
                        DiaperHistorySummaryCell(label: "大便", value: dirtyCount, color: .nuraWarning)
                        DiaperHistorySummaryCell(label: "混合", value: bothCount, color: Color(hex: "8B5CF6"))
                    }
                }

                if dailySummaries.isEmpty {
                    Section {
                        EmptyStateRow(text: "暂无尿布历史记录")
                    }
                } else {
                    ForEach(dailySummaries) { summary in
                        Section {
                            DiaperHistoryDailyRow(summary: summary)
                        } header: {
                            Text(summary.dateDisplay)
                        }
                    }
                }
            }
            .navigationTitle("尿布历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.nuraBlue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
}

struct DiaperHistorySummaryCell: View {
    var label: String
    var value: Int
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text("\(value) 次")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.06))
        .cornerRadius(10)
    }
}

struct DailyDiaperSummary: Identifiable {
    let date: Date
    let wetCount: Int
    let dirtyCount: Int
    let bothCount: Int

    var id: Date { date }

    var totalCount: Int {
        wetCount + dirtyCount + bothCount
    }

    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: date)
    }
}

struct DiaperHistoryDailyRow: View {
    var summary: DailyDiaperSummary

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                DiaperHistoryCountCell(label: "小便", value: summary.wetCount, color: .nuraBlue)
                DiaperHistoryCountCell(label: "大便", value: summary.dirtyCount, color: .nuraWarning)
                DiaperHistoryCountCell(label: "混合", value: summary.bothCount, color: Color(hex: "8B5CF6"))
            }

            HStack {
                Text("当日总计")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(summary.totalCount) 次")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DiaperHistoryCountCell: View {
    var label: String
    var value: Int
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
            Text("\(value)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.06))
        .cornerRadius(10)
    }
}

// MARK: - DayFeedingDetailsView

struct DayFeedingDetailsView: View {
    var feedings: [FeedingRecord]
    var date: Date
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var dayFeedings: [FeedingRecord] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return feedings
            .filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: date)
    }
    
    var totalMl: Double {
        dayFeedings.compactMap(\.amountMl).reduce(0, +)
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !dayFeedings.isEmpty {
                    Section {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("喂养次数")
                                    .font(.system(size: 12, weight: .regular, design: .rounded))
                                    .foregroundStyle(.secondary)
                                Text("\(dayFeedings.count) 次")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(.nuraPrimary)
                            }
                            
                            Spacer()
                            
                            if totalMl > 0 {
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("总奶量")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text("\(Int(totalMl)) ml")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                        .foregroundStyle(.nuraBlue)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    ForEach(dayFeedings) { record in
                        FeedingDetailRow(record: record)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .navigationTitle(dateDisplay)
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
    
    private func deleteRecords(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(dayFeedings[index])
            }
        }
    }
}

struct FeedingDetailRow: View {
    var record: FeedingRecord
    
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
        .padding(.vertical, 4)
    }
}

// MARK: - DayDiaperDetailsView

struct DayDiaperDetailsView: View {
    var diapers: [DiaperRecord]
    var date: Date
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var dayDiapers: [DiaperRecord] {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
        return diapers
            .filter { $0.timestamp >= dayStart && $0.timestamp < dayEnd }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var dateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: date)
    }
    
    var wetCount: Int {
        dayDiapers.filter { $0.type == .wet }.count
    }
    
    var dirtyCount: Int {
        dayDiapers.filter { $0.type == .dirty }.count
    }
    
    var bothCount: Int {
        dayDiapers.filter { $0.type == .both }.count
    }
    
    var body: some View {
        NavigationStack {
            List {
                if !dayDiapers.isEmpty {
                    Section {
                        HStack(spacing: 16) {
                            if wetCount > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("💧 小便")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text("\(wetCount) 次")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.nuraBlue)
                                }
                            }
                            
                            if dirtyCount > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("💩 大便")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text("\(dirtyCount) 次")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(.nuraWarning)
                                }
                            }
                            
                            if bothCount > 0 {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("🌊 混合")
                                        .font(.system(size: 12, weight: .regular, design: .rounded))
                                        .foregroundStyle(.secondary)
                                    Text("\(bothCount) 次")
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: "8B5CF6"))
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                Section {
                    ForEach(dayDiapers) { record in
                        DiaperDetailRow(record: record)
                    }
                    .onDelete(perform: deleteRecords)
                }
            }
            .navigationTitle(dateDisplay)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(.nuraBlue)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
            }
        }
    }
    
    private func deleteRecords(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(dayDiapers[index])
            }
        }
    }
}

struct DiaperDetailRow: View {
    var record: DiaperRecord
    
    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.type.rawValue)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                Text(record.timeDisplay)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Health History Views

private enum HealthHistoryFilter: String, CaseIterable {
    case all = "全部"
    case week = "7天"
    case month = "30天"

    var cutoffDate: Date {
        let calendar = Calendar.current
        switch self {
        case .all:
            return .distantPast
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: Date()) ?? .distantPast
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: Date()) ?? .distantPast
        }
    }
}

struct TemperatureHistoryView: View {
    var records: [TemperatureRecord]
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var filter: HealthHistoryFilter = .all

    var filteredRecords: [TemperatureRecord] {
        records
            .filter { $0.timestamp >= filter.cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("范围", selection: $filter) {
                        ForEach(HealthHistoryFilter.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if filteredRecords.isEmpty {
                        EmptyStateRow(text: "没有符合条件的体温记录")
                    } else {
                        ForEach(filteredRecords) { record in
                            HealthMetricRow(
                                icon: record.site.icon,
                                value: record.temperatureDisplay,
                                label: record.status.label,
                                detail: record.fullDateDisplay + " · " + record.site.rawValue,
                                color: record.status.color,
                                onDelete: { deleteRecord(record) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("体温历史")
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

struct BreathingHistoryView: View {
    var records: [BreathingRecord]
    var child: Child?
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var filter: HealthHistoryFilter = .all

    var filteredRecords: [BreathingRecord] {
        records
            .filter { $0.timestamp >= filter.cutoffDate }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("范围", selection: $filter) {
                        ForEach(HealthHistoryFilter.allCases, id: \.self) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    if filteredRecords.isEmpty {
                        EmptyStateRow(text: "没有符合条件的呼吸记录")
                    } else {
                        ForEach(filteredRecords) { record in
                            let status = record.status(for: child)
                            HealthMetricRow(
                                icon: "lungs.fill",
                                value: record.rateDisplay,
                                label: status.label,
                                detail: record.fullDateDisplay,
                                color: status.color,
                                onDelete: { deleteRecord(record) }
                            )
                        }
                    }
                }
            }
            .navigationTitle("呼吸历史")
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
    ReviewView(selectedChildId: $selectedChildId)
        .modelContainer(for: [
            Child.self, FeedingRecord.self, SleepRecord.self,
            DiaperRecord.self, GrowthRecord.self,
            JaundiceRecord.self, MedicineRecord.self, Milestone.self,
            TemperatureRecord.self, BreathingRecord.self
        ], inMemory: true)
}
