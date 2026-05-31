// TodayView.swift
// Nura — Today tab: daily overview, records, and quick-log

import SwiftUI
import SwiftData
import Combine

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
    @Query private var allConceptionRecords: [ConceptionRecord]
    @Query private var allFetalMovements: [FetalMovementRecord]
    @Query private var allBloodPressures: [BloodPressureRecord]
    @Query private var allBloodSugars: [BloodSugarRecord]
    @Query private var allPregnancyWeights: [PregnancyWeightRecord]
    @Query private var allVaccines: [VaccineRecord]

    @State private var logType: NuraLogType?
    @State private var showBirthBabySheet = false
    @State private var showPregnancyConfirmSheet = false

    var selectedChild: Child? {
        guard let id = selectedChildId else { return children.first }
        // Ensure the child still exists and hasn't been deleted
        return children.first(where: { $0.id == id }) ?? children.first
    }

    var selectedStage: CareStage {
        selectedChild?.careStage ?? .infant
    }

    private var sheetLogType: Binding<NuraLogType?> {
        Binding(
            get: {
                guard let logType, !logType.prefersFullScreenPresentation else { return nil }
                return logType
            },
            set: { logType = $0 }
        )
    }

    private var fullScreenLogType: Binding<NuraLogType?> {
        Binding(
            get: {
                guard let logType, logType.prefersFullScreenPresentation else { return nil }
                return logType
            },
            set: { logType = $0 }
        )
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

    var recentFetalMovements: [FetalMovementRecord] {
        guard let child = selectedChild else { return [] }
        return allFetalMovements.filter { $0.child?.id == child.id }.sorted { $0.timestamp > $1.timestamp }
    }

    var recentConceptionRecords: [ConceptionRecord] {
        guard let child = selectedChild else { return [] }
        return allConceptionRecords.filter { $0.child?.id == child.id }.sorted { $0.timestamp > $1.timestamp }
    }

    var recentBloodPressures: [BloodPressureRecord] {
        guard let child = selectedChild else { return [] }
        return allBloodPressures.filter { $0.child?.id == child.id }.sorted { $0.timestamp > $1.timestamp }
    }

    var recentBloodSugars: [BloodSugarRecord] {
        guard let child = selectedChild else { return [] }
        return allBloodSugars.filter { $0.child?.id == child.id }.sorted { $0.timestamp > $1.timestamp }
    }

    var recentPregnancyWeights: [PregnancyWeightRecord] {
        guard let child = selectedChild else { return [] }
        return allPregnancyWeights.filter { $0.child?.id == child.id }.sorted { $0.timestamp > $1.timestamp }
    }

    var childVaccines: [VaccineRecord] {
        guard let child = selectedChild else { return [] }
        return allVaccines.filter { $0.child?.id == child.id }
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
                    if let child = selectedChild {
                        StageHeaderCard(child: child)
                    }

                    switch selectedStage {
                    case .tryingToConceive:
                        if let child = selectedChild {
                            ConceptionTodayCard(
                                child: child,
                                records: recentConceptionRecords,
                                onConfirmPregnancy: { showPregnancyConfirmSheet = true }
                            )
                            ConceptionWindowCard(child: child, records: recentConceptionRecords)
                            ConceptionVitalsCard(records: recentConceptionRecords)
                        }
                        TemperatureCard(records: todayTemperatures, onAddTap: { logType = .temperature })
                    case .pregnancy:
                        if let child = selectedChild {
                            PregnancyTodayCard(child: child, onDelivered: { showBirthBabySheet = true })
                            if !child.hasDelivered {
                                PregnancySizeCard(child: child)
                                PregnancyVitalsCard(
                                    fetalMovement: recentFetalMovements.first,
                                    bloodPressure: recentBloodPressures.first,
                                    bloodSugar: recentBloodSugars.first,
                                    weight: recentPregnancyWeights.first
                                )
                                PrenatalCheckupCard(child: child)
                            }
                            EmergencySOSCard(child: child)
                        }
                        TemperatureCard(records: todayTemperatures, onAddTap: { logType = .temperature })
                    case .infant:
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
                        if let child = selectedChild {
                            VaccineReminderCard(child: child, records: childVaccines, onAddTap: { logType = .vaccine })
                        }
                        if let child = selectedChild, child.isNewborn {
                            JaundiceCard(records: recentJaundice, onAddTap: { logType = .jaundice })
                        }
                    case .child:
                        ChildTodayFocusCard(
                            child: selectedChild,
                            sleepDisplay: sleepDisplay,
                            latestTemperature: todayTemperatures.first,
                            latestBreathing: todayBreathing.first
                        )
                        SleepCard(records: todaySleeps, totalHours: totalSleepHours)
                        TemperatureCard(records: todayTemperatures, onAddTap: { logType = .temperature })
                        BreathingCard(records: todayBreathing, child: selectedChild, onAddTap: { logType = .breathing })
                        if let child = selectedChild {
                            VaccineReminderCard(child: child, records: childVaccines, onAddTap: { logType = .vaccine })
                        }
                    }

                    QuickLogGrid(stage: selectedStage) { type in logType = type }
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
                    Button { logType = selectedStage.primaryLogType } label: {
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
        .sheet(item: sheetLogType) { type in
            QuickLogSheet(logType: type, selectedChild: selectedChild)
        }
        .fullScreenCover(item: fullScreenLogType) { type in
            QuickLogSheet(logType: type, selectedChild: selectedChild)
        }
        .sheet(isPresented: $showBirthBabySheet) {
            if let pregnancy = selectedChild {
                DeliveryDateSheet(pregnancy: pregnancy)
            }
        }
        .sheet(isPresented: $showPregnancyConfirmSheet) {
            if let profile = selectedChild {
                ConfirmPregnancySheet(profile: profile)
            }
        }
    }

    var todayDateDisplay: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f.string(from: Date())
    }
}

// MARK: - Stage Cards

struct ConceptionTodayCard: View {
    var child: Child
    var records: [ConceptionRecord]
    var onConfirmPregnancy: () -> Void

    private var cycleInfo: ConceptionCycleInfo {
        ConceptionCycleInfo(child: child, records: records)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "calendar.badge.heart", title: "备孕概览", iconColor: child.careStage.color)
            HStack(spacing: 8) {
                StatBox(label: "当前周期", value: "\(cycleInfo.cycleDay)", unit: "天", color: child.careStage.color, icon: "calendar")
                StatBox(label: "易孕窗口", value: cycleInfo.fertileWindowText, unit: "", color: .nuraBlue, icon: "sparkles")
            }

            VStack(alignment: .leading, spacing: 6) {
                Label("未怀孕状态", systemImage: "heart.text.square")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(cycleInfo.todayHint)
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(child.careStage.color.opacity(0.07))
            .cornerRadius(12)

            Button(action: onConfirmPregnancy) {
                Label("确认怀孕，进入孕期", systemImage: "heart.circle.fill")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Color(hex: "EC4899"))
                    .cornerRadius(14)
            }
            .buttonStyle(.plain)
        }
        .nuraCard()
    }
}

struct ConceptionWindowCard: View {
    var child: Child
    var records: [ConceptionRecord]

    private var cycleInfo: ConceptionCycleInfo {
        ConceptionCycleInfo(child: child, records: records)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "chart.bar.fill", title: "周期图", iconColor: child.careStage.color)
            ConceptionCycleStrip(
                cycleDay: cycleInfo.cycleDay,
                ovulationDay: cycleInfo.ovulationDay,
                periodDays: cycleInfo.periodDays
            )
            HStack(spacing: 8) {
                NuraBadge(text: "月经 \(cycleInfo.lastPeriodStart.nuraDateShortDisplay)", color: Color(hex: "F43F5E"))
                NuraBadge(text: "排卵预计第\(cycleInfo.ovulationDay)天", color: child.careStage.color)
                NuraBadge(text: "窗口 \(cycleInfo.windowStart)-\(cycleInfo.windowEnd)天", color: .nuraBlue)
            }
            Text("红色表示实际登记的月经来潮日期，橙色区间表示更值得观察的备孕窗口，深色圆点是今天的位置。")
                .font(.nuraCaption())
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .nuraCard()
    }
}

struct ConceptionCycleStrip: View {
    var cycleDay: Int
    var ovulationDay: Int
    var periodDays: Set<Int>

    private var windowStart: Int { max(1, ovulationDay - 5) }
    private var windowEnd: Int { min(28, ovulationDay + 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                ForEach(1...28, id: \.self) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color(for: day))
                        .frame(height: day == min(cycleDay, 28) ? 34 : 24)
                        .overlay(alignment: .top) {
                            if day == min(cycleDay, 28) {
                                Circle()
                                    .fill(.primary)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 4)
                            }
                        }
                }
            }
            HStack {
                Text("月经")
                Spacer()
                Text("排卵")
                Spacer()
                Text("等待")
            }
            .font(.system(size: 10, design: .rounded))
            .foregroundStyle(.secondary)
        }
    }

    private func color(for day: Int) -> Color {
        if periodDays.contains(day) { return Color(hex: "F43F5E").opacity(0.75) }
        if periodDays.isEmpty && day <= 5 { return Color(hex: "F43F5E").opacity(0.28) }
        if day >= windowStart && day <= windowEnd { return Color(hex: "F97316").opacity(day == ovulationDay ? 0.9 : 0.45) }
        return Color(UIColor.tertiarySystemFill)
    }
}

struct ConceptionVitalsCard: View {
    var records: [ConceptionRecord]

    private var latest: ConceptionRecord? { records.first }
    private var latestPeriod: ConceptionRecord? { records.first(where: { $0.periodFlow.isPeriod }) }
    private var peakCount: Int { records.filter { $0.ovulationTest == .positive || $0.ovulationTest == .peak }.count }
    private var intercourseCount: Int { records.filter(\.hadIntercourse).count }
    private var latestIntercourse: ConceptionRecord? { records.first(where: \.hadIntercourse) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "waveform.path.ecg", title: "备孕记录", iconColor: Color(hex: "F97316"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                OverviewTextBox(label: "月经来潮", value: latestPeriod?.timestamp.nuraDateShortDisplay ?? "暂无记录", color: Color(hex: "F43F5E"), icon: "drop.fill")
                OverviewTextBox(label: "检测结果", value: latest?.ovulationTest.rawValue ?? "暂无记录", color: Color(hex: "F97316"), icon: "checklist.checked")
                OverviewTextBox(label: "同房记录", value: latestIntercourse?.intercourseTime?.nuraDateShortDisplay ?? "\(intercourseCount)次", color: Color(hex: "EC4899"), icon: "heart.fill")
                OverviewTextBox(label: "阳性/强阳", value: "\(peakCount)次", color: .nuraBlue, icon: "chart.line.uptrend.xyaxis")
            }
        }
        .nuraCard()
    }
}

struct ConfirmPregnancySheet: View {
    @Bindable var profile: Child
    @Environment(\.dismiss) private var dismiss

    @State private var lastMenstrualPeriod = Date()
    @State private var confirmedDate = Date()

    private var dueDate: Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lastMenstrualPeriod) ?? lastMenstrualPeriod
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("保存后，当前备孕档案会转为孕期档案；备孕记录不会删除，会作为归档数据留在回顾里。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("孕期信息") {
                    DatePicker("确认怀孕日期", selection: $confirmedDate, in: Date.distantPast...Date(), displayedComponents: .date)
                    DatePicker("末次月经", selection: $lastMenstrualPeriod, in: Date.distantPast...Date(), displayedComponents: .date)
                    HStack {
                        Text("预计预产期")
                        Spacer()
                        Text(dueDate.nuraDateShortDisplay)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("进入孕期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { savePregnancy() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .tint(.nuraPrimary)
        .onAppear {
            lastMenstrualPeriod = profile.lastMenstrualPeriodDate ?? profile.birthDate
        }
    }

    private func savePregnancy() {
        profile.profileType = .pregnancy
        profile.name = "孕期档案"
        profile.birthDate = dueDate
        profile.color = .pink
        profile.conceptionArchivedAt = Date()
        profile.pregnancyConfirmedDate = confirmedDate
        profile.lastMenstrualPeriodDate = lastMenstrualPeriod
        dismiss()
    }
}

struct ConceptionCycleInfo {
    var child: Child
    var records: [ConceptionRecord]

    var lastPeriodStart: Date {
        records
            .filter { $0.periodFlow.isPeriod }
            .sorted { $0.timestamp > $1.timestamp }
            .first?
            .timestamp ?? child.lastMenstrualPeriodDate ?? child.birthDate
    }

    var periodDays: Set<Int> {
        let start = Calendar.current.startOfDay(for: lastPeriodStart)
        return Set(records.filter { $0.periodFlow.isPeriod }.compactMap { record in
            let day = (Calendar.current.dateComponents([.day], from: start, to: record.timestamp).day ?? 0) + 1
            return (1...28).contains(day) ? day : nil
        })
    }

    var cycleDay: Int {
        max((Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: lastPeriodStart), to: Date()).day ?? 0) + 1, 1)
    }

    var ovulationDay: Int { 14 }
    var windowStart: Int { max(1, ovulationDay - 5) }
    var windowEnd: Int { min(28, ovulationDay + 1) }

    var fertileWindowText: String {
        if cycleDay >= windowStart && cycleDay <= windowEnd { return "进行中" }
        if cycleDay < windowStart { return "\(windowStart - cycleDay)天后" }
        return "已过"
    }

    var todayHint: String {
        if cycleDay >= windowStart && cycleDay <= windowEnd {
            return "今天在预计易孕窗口内，适合记录排卵试纸、基础体温和身体变化。"
        }
        return "当前仍按未怀孕备孕期展示。若已经验孕确认，可以点击下方按钮进入孕期并归档备孕数据。"
    }
}

struct PregnancyTodayCard: View {
    var child: Child
    var onDelivered: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(icon: "calendar.badge.clock", title: "孕期概览", iconColor: child.careStage.color)

            if let deliveryDate = child.deliveryDate {
                HStack(spacing: 8) {
                    StatBox(
                        label: "生产日期",
                        value: deliveryDate.nuraDateShortDisplay,
                        unit: "",
                        color: child.careStage.color,
                        icon: "sparkles"
                    )
                    StatBox(
                        label: "珍贵日子",
                        value: "\(daysSince(deliveryDate))",
                        unit: "天前",
                        color: .nuraBlue,
                        icon: "heart.fill"
                    )
                }
            } else {
                HStack(spacing: 8) {
                    StatBox(
                        label: "当前孕周",
                        value: child.pregnancyWeekDisplay,
                        unit: "",
                        color: child.careStage.color,
                        icon: "heart.circle.fill"
                    )
                    StatBox(
                        label: "距预产期",
                        value: "\(child.daysUntilDueDate)",
                        unit: "天",
                        color: .nuraBlue,
                        icon: "calendar"
                    )
                }
            }
            VStack(alignment: .leading, spacing: 6) {
                Label(child.hasDelivered ? "恭喜你" : "今日重点", systemImage: child.hasDelivered ? "heart.fill" : "checklist")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                Text(child.hasDelivered ? "辛苦啦，新的旅程开始了。愿你和宝宝都被温柔照顾，也别忘了好好休息。" : "记录体温、用药和产检相关变化；生产后可以在这里保存生产日期。")
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(child.careStage.color.opacity(0.07))
            .cornerRadius(12)

            if !child.hasDelivered {
                Button(action: onDelivered) {
                    Label("生了宝宝", systemImage: "sparkles")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(child.careStage.color)
                        .cornerRadius(14)
                }
                .buttonStyle(.plain)
            }
        }
        .nuraCard()
    }

    private func daysSince(_ date: Date) -> Int {
        max(Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0, 0)
    }
}

struct DeliveryDateSheet: View {
    var pregnancy: Child

    @Environment(\.dismiss) private var dismiss

    @State private var birthDate = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("这里仅保存生产日期，不会自动创建宝宝档案。之后如需记录宝宝信息，可以在档案列表中手动添加宝宝。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("生产信息") {
                    DatePicker("生产日期", selection: $birthDate, in: Date.distantPast...Date(), displayedComponents: .date)
                }
            }
            .navigationTitle("记录生产日期")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }.foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { saveDeliveryDate() }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                }
            }
        }
        .tint(.nuraPrimary)
        .onAppear {
            birthDate = pregnancy.deliveryDate ?? Date()
        }
    }

    private func saveDeliveryDate() {
        pregnancy.deliveryDate = birthDate
        dismiss()
    }
}

struct PregnancySizeCard: View {
    var child: Child

    var body: some View {
        let info = child.pregnancySizeInfo

        VStack(alignment: .leading, spacing: 14) {
            SectionLabel(icon: "chart.bar.fill", title: "宝宝大小", iconColor: info.color)

            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(info.color.opacity(0.12))
                        .frame(width: 112, height: 112)
                    Circle()
                        .stroke(info.color.opacity(0.22), lineWidth: 10)
                        .frame(width: 88, height: 88)
                    Image(systemName: info.icon)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(info.color)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("像\(info.sizeName)一样大")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    HStack(spacing: 8) {
                        NuraBadge(text: info.lengthText, color: info.color)
                        NuraBadge(text: info.weightText, color: .nuraBlue)
                    }
                    Text(info.situation)
                        .font(.nuraCaption())
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            PregnancyProgressBar(week: child.gestationalWeek, color: info.color)
        }
        .nuraCard()
    }
}

struct PregnancyProgressBar: View {
    var week: Int
    var color: Color

    var progress: CGFloat {
        min(max(CGFloat(week) / 40.0, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(UIColor.tertiarySystemFill))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 10)

            HStack {
                Text("1周")
                Spacer()
                Text("当前 \(week)周")
                    .fontWeight(.semibold)
                    .foregroundStyle(color)
                Spacer()
                Text("40周")
            }
            .font(.system(size: 10, design: .rounded))
            .foregroundStyle(.secondary)
        }
    }
}

struct EmergencySOSCard: View {
    var child: Child

    private var phoneNumber: String? {
        child.emergencyContactPhone?.filter { $0.isNumber || $0 == "+" }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "phone.fill", title: "紧急联系人", iconColor: .nuraDanger)
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.emergencyContactName ?? "未填写联系人")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text(child.emergencyContactPhone ?? "可在新增孕妇信息时填写")
                        .font(.nuraCaption())
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let phoneNumber, !phoneNumber.isEmpty, let url = URL(string: "tel://\(phoneNumber)") {
                    Link(destination: url) {
                        Label("SOS", systemImage: "phone.fill")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 42)
                            .background(Color.nuraDanger)
                            .cornerRadius(12)
                    }
                } else {
                    Label("SOS", systemImage: "phone.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 18)
                        .frame(height: 42)
                        .background(Color(UIColor.tertiarySystemFill))
                        .cornerRadius(12)
                }
            }
        }
        .nuraCard()
    }
}

struct PregnancyVitalsCard: View {
    var fetalMovement: FetalMovementRecord?
    var bloodPressure: BloodPressureRecord?
    var bloodSugar: BloodSugarRecord?
    var weight: PregnancyWeightRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "waveform.path.ecg", title: "孕期记录", iconColor: Color(hex: "EC4899"))
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                OverviewTextBox(label: "胎动", value: fetalMovement.map { "\($0.count)次 · \($0.durationDisplay)" } ?? "暂无记录", color: Color(hex: "EC4899"), icon: "hand.tap.fill")
                OverviewTextBox(label: "血压", value: bloodPressure.map { "\($0.valueDisplay) · \($0.status)" } ?? "暂无记录", color: Color(hex: "DC2626"), icon: "heart.text.square.fill")
                OverviewTextBox(label: "血糖", value: bloodSugar.map { "\($0.valueDisplay) · \($0.timing.rawValue)" } ?? "暂无记录", color: Color(hex: "06B6D4"), icon: "drop.degreesign.fill")
                OverviewTextBox(label: "体重", value: weight?.valueDisplay ?? "暂无记录", color: Color(hex: "8B5CF6"), icon: "scalemass.fill")
            }
        }
        .nuraCard()
    }
}

struct PrenatalCheckupCard: View {
    var child: Child
    @State private var showHistory = false

    private var currentAndNext: [PrenatalCheckupItem] {
        PrenatalCheckupItem.upcoming(for: child.gestationalWeek, within: 1)
    }

    private var history: [PrenatalCheckupItem] {
        Array(PrenatalCheckupItem.history(before: child.gestationalWeek).prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(icon: "stethoscope", title: "产检提醒", iconColor: .nuraBlue)
                Spacer()
                if !history.isEmpty {
                    Button(showHistory ? "收起" : "回顾") {
                        withAnimation(.spring(response: 0.25)) { showHistory.toggle() }
                    }
                    .font(.nuraCaption())
                    .foregroundStyle(.nuraBlue)
                }
            }

            if currentAndNext.isEmpty {
                EmptyStateRow(text: "本周和下周暂无固定产检项目")
            } else {
                ForEach(currentAndNext) { item in
                    PrenatalCheckupRow(item: item, isHistory: false)
                }
            }

            if showHistory {
                Divider()
                ForEach(history) { item in
                    PrenatalCheckupRow(item: item, isHistory: true)
                }
            }
        }
        .nuraCard()
    }
}

struct PrenatalCheckupRow: View {
    var item: PrenatalCheckupItem
    var isHistory: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill((isHistory ? Color.nuraSuccess : Color.nuraBlue).opacity(0.12))
                    .frame(width: 38, height: 38)
                Text("\(item.week)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(isHistory ? .nuraSuccess : .nuraBlue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text(item.details.joined(separator: " · "))
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct ChildTodayFocusCard: View {
    var child: Child?
    var sleepDisplay: String
    var latestTemperature: TemperatureRecord?
    var latestBreathing: BreathingRecord?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(icon: "figure.and.child.holdinghands", title: "儿童今日重点", iconColor: child?.careStage.color ?? .nuraBlue)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                StatBox(label: "睡眠", value: sleepDisplay, unit: "", color: Color(hex: "818CF8"), icon: "moon.fill")
                OverviewTextBox(label: "最近体温", value: latestTemperature?.temperatureDisplay ?? "今日无体温数据", color: Color(hex: "EF4444"), icon: "thermometer.medium")
                OverviewTextBox(label: "呼吸记录", value: latestBreathing?.rateDisplay ?? "今日无呼吸记录", color: Color(hex: "14B8A6"), icon: "lungs.fill")
                OverviewTextBox(label: "成长记录", value: "身高、体重、头围", color: .nuraSuccess, icon: "chart.line.uptrend.xyaxis")
            }
        }
        .nuraCard()
    }
}

struct VaccineReminderCard: View {
    var child: Child
    var records: [VaccineRecord]
    var onAddTap: () -> Void

    private var reminders: [VaccineReminderItem] {
        vaccineReminders(for: child, records: records)
    }

    private var visibleReminders: [VaccineReminderItem] {
        let pending = reminders.filter { !$0.isCompleted }
        return Array((pending.isEmpty ? reminders : pending).prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(icon: "syringe.fill", title: "疫苗提醒", iconColor: Color(hex: "10B981"))
                Spacer()
                Button(action: onAddTap) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                }
                .buttonStyle(.plain)
            }

            if visibleReminders.isEmpty {
                EmptyStateRow(text: "暂无疫苗计划")
            } else {
                VStack(spacing: 8) {
                    ForEach(visibleReminders) { reminder in
                        VaccineReminderRow(reminder: reminder)
                    }
                }
            }
        }
        .nuraCard()
    }
}

struct VaccineReminderRow: View {
    var reminder: VaccineReminderItem

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(reminder.status.color.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: reminder.status.iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(reminder.status.color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(reminder.schedule.name) \(reminder.schedule.dose)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                Text("\(reminder.schedule.dueAgeDisplay) · \(reminder.dueText) · \(reminder.schedule.note)")
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

func vaccineReminders(for child: Child, records: [VaccineRecord]) -> [VaccineReminderItem] {
    let recordsByKey = Dictionary(grouping: records, by: \.scheduleKey)
    return VaccineScheduleItem.standard.map { schedule in
        let record = recordsByKey[schedule.key]?.sorted {
            ($0.completedDate ?? $0.scheduledDate) > ($1.completedDate ?? $1.scheduledDate)
        }.first
        return VaccineReminderItem(
            schedule: schedule,
            record: record,
            dueDate: record?.scheduledDate ?? schedule.dueDate(for: child)
        )
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
        HStack(spacing: 6) {
            Image(systemName: record.type.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(record.type.color)
            Text(record.timeDisplay)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(record.type.color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(record.type.color.opacity(0.12))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(record.type.color.opacity(0.3), lineWidth: 1)
        )
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
                    detail: "\(latest.countDisplay) · \(latest.fullDateDisplay)",
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
    var stage: CareStage
    var onTap: (NuraLogType) -> Void

    private var items: [NuraLogType] { stage.logTypes }

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
                ForEach(items) { item in
                    QuickLogButton(icon: item.icon, title: item.shortTitle, color: item.color) {
                        onTap(item)
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

extension NuraLogType {
    var prefersFullScreenPresentation: Bool {
        self == .breathing || self == .fetalMovement
    }
}

struct QuickLogSheet: View {
    var logType: NuraLogType
    var selectedChild: Child?

    @Query private var allVaccineRecords: [VaccineRecord]

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
    @State private var breathingCount = 0
    @State private var breathingTargetSeconds = 60
    @State private var breathingElapsedSeconds = 0
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
    @State private var fetalMovementCount = 0
    @State private var fetalMovementTargetMinutes = 60
    @State private var fetalMovementElapsedSeconds = 0
    @State private var bloodPressureSystolic: Double = 120
    @State private var bloodPressureDiastolic: Double = 80
    @State private var bloodSugar: Double = 5.1
    @State private var bloodSugarTiming: BloodSugarTiming = .fasting
    @State private var pregnancyWeight: Double = 60
    @State private var selectedVaccineKey: String = VaccineScheduleItem.standard.first?.key ?? ""
    @State private var vaccineCompletedDate = Date()
    @State private var vaccineNotes = ""
    @State private var conceptionTemperature: Double = 36.5
    @State private var conceptionHasTemperature = true
    @State private var ovulationTest: OvulationTestResult = .notTested
    @State private var hadIntercourse = false
    @State private var intercourseTime = Date()
    @State private var periodFlow: PeriodFlow = .medium
    @State private var conceptionNotes = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Group {
                        switch logType {
                        case .conception:
                            ConceptionLogForm(
                                temperature: $conceptionTemperature,
                                hasTemperature: $conceptionHasTemperature,
                                ovulationTest: $ovulationTest,
                                hadIntercourse: $hadIntercourse,
                                intercourseTime: $intercourseTime,
                                periodFlow: $periodFlow,
                                notes: $conceptionNotes,
                                time: $time
                            )
                        case .conceptionPeriod:
                            ConceptionPeriodLogForm(
                                periodFlow: $periodFlow,
                                notes: $conceptionNotes,
                                time: $time
                            )
                        case .conceptionIntercourse:
                            ConceptionIntercourseLogForm(
                                intercourseTime: $intercourseTime,
                                notes: $conceptionNotes
                            )
                        case .conceptionTest:
                            ConceptionTestLogForm(
                                temperature: $conceptionTemperature,
                                hasTemperature: $conceptionHasTemperature,
                                ovulationTest: $ovulationTest,
                                notes: $conceptionNotes,
                                time: $time
                            )
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
                                count: $breathingCount,
                                targetSeconds: $breathingTargetSeconds,
                                elapsedSeconds: $breathingElapsedSeconds,
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
                        case .vaccine:
                            VaccineLogForm(
                                child: selectedChild,
                                records: selectedChild.map { child in
                                    allVaccineRecords.filter { $0.child?.id == child.id }
                                } ?? [],
                                selectedKey: $selectedVaccineKey,
                                completedDate: $vaccineCompletedDate,
                                notes: $vaccineNotes
                            )
                        case .fetalMovement:
                            FetalMovementLogForm(
                                count: $fetalMovementCount,
                                targetMinutes: $fetalMovementTargetMinutes,
                                elapsedSeconds: $fetalMovementElapsedSeconds
                            )
                        case .bloodPressure:
                            BloodPressureLogForm(
                                systolic: $bloodPressureSystolic,
                                diastolic: $bloodPressureDiastolic,
                                time: $time
                            )
                        case .bloodSugar:
                            BloodSugarLogForm(
                                glucose: $bloodSugar,
                                timing: $bloodSugarTiming,
                                time: $time
                            )
                        case .pregnancyWeight:
                            PregnancyWeightLogForm(weight: $pregnancyWeight, time: $time)
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
        case .conception:
            modelContext.insert(ConceptionRecord(
                timestamp: time,
                basalTemperature: conceptionHasTemperature ? conceptionTemperature : nil,
                ovulationTest: ovulationTest,
                hadIntercourse: hadIntercourse,
                intercourseTime: hadIntercourse ? intercourseTime : nil,
                periodFlow: periodFlow,
                notes: conceptionNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                child: child
            ))
        case .conceptionPeriod:
            modelContext.insert(ConceptionRecord(
                timestamp: Calendar.current.startOfDay(for: time),
                ovulationTest: .notTested,
                periodFlow: periodFlow,
                notes: conceptionNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                child: child
            ))
        case .conceptionIntercourse:
            let intercourseDate = Calendar.current.startOfDay(for: intercourseTime)
            modelContext.insert(ConceptionRecord(
                timestamp: intercourseDate,
                ovulationTest: .notTested,
                hadIntercourse: true,
                intercourseTime: intercourseDate,
                periodFlow: .none,
                notes: conceptionNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                child: child
            ))
        case .conceptionTest:
            modelContext.insert(ConceptionRecord(
                timestamp: Calendar.current.startOfDay(for: time),
                basalTemperature: conceptionHasTemperature ? conceptionTemperature : nil,
                ovulationTest: ovulationTest,
                periodFlow: .none,
                notes: conceptionNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                child: child
            ))
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
            let measuredSeconds = max(breathingElapsedSeconds, min(breathingTargetSeconds, 60))
            let rate = Int((Double(breathingCount) * 60.0 / Double(max(measuredSeconds, 1))).rounded())
            modelContext.insert(BreathingRecord(
                timestamp: time,
                breathsPerMinute: rate,
                breathCount: breathingCount,
                durationSeconds: measuredSeconds,
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
        case .vaccine:
            guard let schedule = VaccineScheduleItem.standard.first(where: { $0.key == selectedVaccineKey }) else {
                dismiss()
                return
            }
            let existingRecord = allVaccineRecords.first {
                $0.child?.id == child.id && $0.scheduleKey == schedule.key
            }
            if let existingRecord {
                existingRecord.completedDate = vaccineCompletedDate
                existingRecord.notes = vaccineNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            } else {
                modelContext.insert(VaccineRecord(
                    scheduleKey: schedule.key,
                    vaccineName: schedule.name,
                    dose: schedule.dose,
                    scheduledDate: schedule.dueDate(for: child),
                    completedDate: vaccineCompletedDate,
                    notes: vaccineNotes.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    child: child
                ))
            }
        case .fetalMovement:
            modelContext.insert(FetalMovementRecord(
                timestamp: Date(),
                count: fetalMovementCount,
                durationMinutes: fetalMovementTargetMinutes,
                actualSeconds: max(fetalMovementElapsedSeconds, 60),
                child: child
            ))
        case .bloodPressure:
            modelContext.insert(BloodPressureRecord(
                timestamp: time,
                systolic: Int(bloodPressureSystolic),
                diastolic: Int(bloodPressureDiastolic),
                child: child
            ))
        case .bloodSugar:
            modelContext.insert(BloodSugarRecord(
                timestamp: time,
                glucose: bloodSugar,
                timing: bloodSugarTiming,
                child: child
            ))
        case .pregnancyWeight:
            modelContext.insert(PregnancyWeightRecord(
                timestamp: time,
                weightKg: pregnancyWeight,
                child: child
            ))
        }
        dismiss()
    }
}

// MARK: - Log Forms

struct ConceptionLogForm: View {
    @Binding var temperature: Double
    @Binding var hasTemperature: Bool
    @Binding var ovulationTest: OvulationTestResult
    @Binding var hadIntercourse: Bool
    @Binding var intercourseTime: Date
    @Binding var periodFlow: PeriodFlow
    @Binding var notes: String
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("周期状态").nuraSectionHeader()
                Picker("月经量", selection: $periodFlow) {
                    ForEach(PeriodFlow.allCases) { flow in
                        Text(flow.rawValue).tag(flow)
                    }
                }
                .pickerStyle(.segmented)

                Picker("排卵试纸", selection: $ovulationTest) {
                    ForEach(OvulationTestResult.allCases) { result in
                        Text(result.rawValue).tag(result)
                    }
                }
                .pickerStyle(.menu)
            }
            .nuraCard()

            VStack(alignment: .leading, spacing: 10) {
                Toggle("记录基础体温", isOn: $hasTemperature)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tint(Color(hex: "F97316"))
                if hasTemperature {
                    SliderFormCard(title: "基础体温", unit: "°C", value: $temperature, range: 35.5...38.5, step: 0.01, color: Color(hex: "EF4444"))
                }
            }
            .nuraCard()

            VStack(alignment: .leading, spacing: 10) {
                Toggle("登记同房信息", isOn: $hadIntercourse)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tint(Color(hex: "EC4899"))
                if hadIntercourse {
                    DatePicker("同房日期", selection: $intercourseTime, in: Date.distantPast...Date(), displayedComponents: .date)
                        .font(.nuraBody())
                }
                TextField("备注，例如症状、试纸颜色、医生建议", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .font(.nuraBody())
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .nuraCard()

            DateOnlyPickerCard(label: "记录日期", date: $time)
        }
    }
}

struct ConceptionPeriodLogForm: View {
    @Binding var periodFlow: PeriodFlow
    @Binding var notes: String
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("月经来潮").nuraSectionHeader()
                Picker("月经量", selection: $periodFlow) {
                    ForEach(PeriodFlow.allCases.filter(\.isPeriod)) { flow in
                        Text(flow.rawValue).tag(flow)
                    }
                }
                .pickerStyle(.segmented)
                Text("这里会作为周期图的真实起点显示。")
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            .nuraCard()

            DateOnlyPickerCard(label: "记录日期", date: $time)

            NotesCard(title: "备注", text: $notes, placeholder: "例如颜色、腹痛、用药等")
        }
    }
}

struct ConceptionIntercourseLogForm: View {
    @Binding var intercourseTime: Date
    @Binding var notes: String

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("同房信息").nuraSectionHeader()
                DatePicker("同房日期", selection: $intercourseTime, in: Date.distantPast...Date(), displayedComponents: .date)
                    .font(.nuraBody())
                Text("保存后会单独计入同房记录，并在备孕概览里显示最近一次日期。")
                    .font(.nuraCaption())
                    .foregroundStyle(.secondary)
            }
            .nuraCard()

            NotesCard(title: "备注", text: $notes, placeholder: "例如排卵窗口、身体状态等")
        }
    }
}

struct ConceptionTestLogForm: View {
    @Binding var temperature: Double
    @Binding var hasTemperature: Bool
    @Binding var ovulationTest: OvulationTestResult
    @Binding var notes: String
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("检测记录").nuraSectionHeader()
                Picker("排卵试纸", selection: $ovulationTest) {
                    ForEach(OvulationTestResult.allCases) { result in
                        Text(result.rawValue).tag(result)
                    }
                }
                .pickerStyle(.segmented)
            }
            .nuraCard()

            VStack(alignment: .leading, spacing: 10) {
                Toggle("记录基础体温", isOn: $hasTemperature)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .tint(Color(hex: "F97316"))
                if hasTemperature {
                    SliderFormCard(title: "基础体温", unit: "°C", value: $temperature, range: 35.5...38.5, step: 0.01, color: Color(hex: "EF4444"))
                }
            }
            .nuraCard()

            DateOnlyPickerCard(label: "检测日期", date: $time)
            NotesCard(title: "备注", text: $notes, placeholder: "例如试纸颜色、验孕结果、症状等")
        }
    }
}

struct DateOnlyPickerCard: View {
    var label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Label(label, systemImage: "calendar")
                .font(.nuraBody())
                .foregroundStyle(.secondary)
            Spacer()
            DatePicker("", selection: $date, in: Date.distantPast...Date(), displayedComponents: .date)
                .labelsHidden()
                .tint(.nuraPrimary)
        }
        .nuraCard()
    }
}

struct NotesCard: View {
    var title: String
    @Binding var text: String
    var placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).nuraSectionHeader()
            TextField(placeholder, text: $text, axis: .vertical)
                .lineLimit(2...4)
                .font(.nuraBody())
                .padding()
                .background(Color(UIColor.secondarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .nuraCard()
    }
}

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
    @Binding var count: Int
    @Binding var targetSeconds: Int
    @Binding var elapsedSeconds: Int
    @Binding var time: Date
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var remainingSeconds: Int { max(targetSeconds - elapsedSeconds, 0) }
    private var progress: CGFloat { min(CGFloat(elapsedSeconds) / CGFloat(max(targetSeconds, 1)), 1) }
    private var estimatedRate: Int {
        let measuredSeconds = max(elapsedSeconds, min(targetSeconds, 60))
        return Int((Double(count) * 60.0 / Double(max(measuredSeconds, 1))).rounded())
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("计时时长").nuraSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("计时时长", selection: $targetSeconds) {
                    Text("30秒").tag(30)
                    Text("60秒").tag(60)
                    Text("120秒").tag(120)
                }
                .pickerStyle(.segmented)
                .disabled(isRunning)
            }
            .nuraCard()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(hex: "14B8A6"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 8) {
                        Text(timeText(remainingSeconds))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("已记录 \(count) 次")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "14B8A6"))
                        Text("约 \(estimatedRate) 次/分")
                            .font(.nuraCaption())
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 210, height: 210)

                Button {
                    if !isRunning && elapsedSeconds == 0 { isRunning = true }
                    count += 1
                } label: {
                    Label("呼吸 +1", systemImage: "lungs.fill")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color(hex: "14B8A6"))
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(isRunning ? "暂停" : "开始") {
                        isRunning.toggle()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(12)

                    Button("重置") {
                        isRunning = false
                        elapsedSeconds = 0
                        count = 0
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(12)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            }
            .nuraCard()

            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "14B8A6"))
                Text("让宝宝保持安静，每看到胸腹起伏一次点击一次。系统会自动换算为每分钟呼吸频率。")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal)

            TimePickerCard(time: $time)
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if elapsedSeconds < targetSeconds {
                elapsedSeconds += 1
            } else {
                isRunning = false
            }
        }
    }

    private func timeText(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct FetalMovementLogForm: View {
    @Binding var count: Int
    @Binding var targetMinutes: Int
    @Binding var elapsedSeconds: Int
    @State private var isRunning = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private var targetSeconds: Int { targetMinutes * 60 }
    private var remainingSeconds: Int { max(targetSeconds - elapsedSeconds, 0) }
    private var progress: CGFloat { min(CGFloat(elapsedSeconds) / CGFloat(max(targetSeconds, 1)), 1) }

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                Text("计时时长").nuraSectionHeader()
                    .frame(maxWidth: .infinity, alignment: .leading)
                Stepper("\(targetMinutes) 分钟", value: $targetMinutes, in: 10...120, step: 5)
                    .font(.nuraBody())
                    .disabled(isRunning)
            }
            .nuraCard()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .stroke(Color(UIColor.tertiarySystemFill), lineWidth: 16)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color(hex: "EC4899"), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 8) {
                        Text(timeText(remainingSeconds))
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .monospacedDigit()
                        Text("已记录 \(count) 次")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "EC4899"))
                    }
                }
                .frame(width: 210, height: 210)

                Button {
                    if !isRunning && elapsedSeconds == 0 { isRunning = true }
                    count += 1
                } label: {
                    Label("胎动 +1", systemImage: "hand.tap.fill")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .background(Color(hex: "EC4899"))
                        .cornerRadius(18)
                }
                .buttonStyle(.plain)

                HStack(spacing: 10) {
                    Button(isRunning ? "暂停" : "开始") {
                        isRunning.toggle()
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(12)

                    Button("重置") {
                        isRunning = false
                        elapsedSeconds = 0
                        count = 0
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(UIColor.tertiarySystemFill))
                    .cornerRadius(12)
                }
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            }
            .nuraCard()
        }
        .onReceive(timer) { _ in
            guard isRunning else { return }
            if elapsedSeconds < targetSeconds {
                elapsedSeconds += 1
            } else {
                isRunning = false
            }
        }
    }

    private func timeText(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct BloodPressureLogForm: View {
    @Binding var systolic: Double
    @Binding var diastolic: Double
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            SliderFormCard(title: "收缩压", unit: "mmHg", value: $systolic, range: 80...180, step: 1, color: Color(hex: "DC2626"))
            SliderFormCard(title: "舒张压", unit: "mmHg", value: $diastolic, range: 40...120, step: 1, color: Color(hex: "F97316"))
            TimePickerCard(time: $time)
        }
    }
}

struct BloodSugarLogForm: View {
    @Binding var glucose: Double
    @Binding var timing: BloodSugarTiming
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("测量时机").nuraSectionHeader()
                Picker("测量时机", selection: $timing) {
                    ForEach(BloodSugarTiming.allCases) { timing in
                        Text(timing.rawValue).tag(timing)
                    }
                }
                .pickerStyle(.segmented)
            }
            .nuraCard()
            SliderFormCard(title: "血糖", unit: "mmol/L", value: $glucose, range: 3...15, step: 0.1, color: Color(hex: "06B6D4"))
            TimePickerCard(time: $time)
        }
    }
}

struct PregnancyWeightLogForm: View {
    @Binding var weight: Double
    @Binding var time: Date

    var body: some View {
        VStack(spacing: 14) {
            SliderFormCard(title: "孕期体重", unit: "kg", value: $weight, range: 35...120, step: 0.1, color: Color(hex: "8B5CF6"))
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

struct VaccineLogForm: View {
    var child: Child?
    var records: [VaccineRecord]
    @Binding var selectedKey: String
    @Binding var completedDate: Date
    @Binding var notes: String

    private var reminders: [VaccineReminderItem] {
        guard let child else { return [] }
        return vaccineReminders(for: child, records: records)
    }

    private var selectedReminder: VaccineReminderItem? {
        reminders.first { $0.schedule.key == selectedKey }
    }

    var body: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("选择疫苗").nuraSectionHeader()
                VStack(spacing: 8) {
                    ForEach(reminders) { reminder in
                        Button {
                            selectedKey = reminder.schedule.key
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: selectedKey == reminder.schedule.key ? "checkmark.circle.fill" : reminder.status.iconName)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(selectedKey == reminder.schedule.key ? Color(hex: "10B981") : reminder.status.color)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(reminder.schedule.name) \(reminder.schedule.dose)")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundStyle(.primary)
                                    Text("\(reminder.schedule.dueAgeDisplay) · \(reminder.dueText)")
                                        .font(.nuraCaption())
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(
                                selectedKey == reminder.schedule.key
                                    ? Color(hex: "10B981").opacity(0.1)
                                    : Color(UIColor.tertiarySystemFill)
                            )
                            .cornerRadius(12)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .nuraCard()

            HStack {
                Label("接种日期", systemImage: "calendar")
                    .font(.nuraBody())
                    .foregroundStyle(.secondary)
                Spacer()
                DatePicker("", selection: $completedDate, in: Date.distantPast...Date(), displayedComponents: .date)
                    .labelsHidden()
                    .tint(.nuraPrimary)
            }
            .nuraCard()

            VStack(alignment: .leading, spacing: 8) {
                Text("备注（可选）").nuraSectionHeader()
                TextField("如：接种地点、批号、反应", text: $notes, axis: .vertical)
                    .font(.nuraBody())
                    .lineLimit(3)
                    .padding()
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)
            }
            .nuraCard()

            if let selectedReminder {
                HStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color(hex: "10B981"))
                    Text("保存后会根据接种完成情况，继续提醒下一针。")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .accessibilityLabel(selectedReminder.schedule.note)
            }
        }
        .onAppear {
            if selectedKey.isEmpty {
                selectedKey = reminders.first(where: { !$0.isCompleted })?.schedule.key ?? reminders.first?.schedule.key ?? ""
            }
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
                        detail: "\(record.countDisplay) · \(record.fullDateDisplay)",
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
