// GrowthReportView.swift
// Nura — 生成孩子的成长报告

import SwiftUI
import SwiftData

// MARK: - GrowthReportData

struct GrowthReportData {
    let dateRange: String
    let recordDays: Int
    let totalFeedings: Int
    let totalSleepHours: Double
    let totalDiapers: Int
    let averageDailyFeedings: Double
    let averageDailySleepHours: Double
    let averageDailyDiapers: Double
    let breastfeedingCount: Int
    let formulaCount: Int
    let solidFoodCount: Int
    let totalSleepSessions: Int
    let longestSleepHours: Double
    let wetDiaperCount: Int
    let dirtyDiaperCount: Int
    let mixedDiaperCount: Int
    let latestGrowth: GrowthRecord?
    let recentMilestones: [Milestone]
}

// MARK: - GrowthReportView

struct GrowthReportView: View {
    let child: Child
    let reportData: GrowthReportData
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var reportImage: UIImage?
    @State private var isGeneratingShareImage = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 报告内容区域
                    ReportContentView(child: child, reportData: reportData)
                        .background(Color.white)
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        generateAndShare()
                    } label: {
                        HStack(spacing: 4) {
                            if isGeneratingShareImage {
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text("分享")
                            }
                        }
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                    }
                    .disabled(isGeneratingShareImage)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = reportImage {
                    ShareSheet(items: [image])
                }
            }
        }
    }
    
    // MARK: - Generate and Share
    
    @MainActor
    private func generateAndShare() {
        guard !isGeneratingShareImage else { return }
        if reportImage != nil {
            showShareSheet = true
            return
        }

        isGeneratingShareImage = true
        let report = ReportContentView(child: child, reportData: reportData)
            .frame(width: 390)
            .background(Color.white)

        Task { @MainActor in
            await Task.yield()
            let renderer = ImageRenderer(content: report)
            renderer.proposedSize = ProposedViewSize(width: 390, height: nil)
            renderer.scale = 2
            
            if let image = renderer.uiImage {
                reportImage = image
                showShareSheet = true
            }
            isGeneratingShareImage = false
        }
    }
}

// MARK: - ReportContentView

struct ReportContentView: View {
    let child: Child
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题区域
            ReportHeaderSection(child: child, reportData: reportData)
            
            // 统计数据区域
            ReportStatsSection(reportData: reportData)
            
            // 成长数据区域
            if let latestGrowth = reportData.latestGrowth {
                ReportGrowthSection(growth: latestGrowth, child: child)
            }
            
            // 喂养分析区域
            ReportFeedingSection(reportData: reportData)
            
            // 睡眠分析区域
            ReportSleepSection(reportData: reportData)
            
            // 尿布统计区域
            ReportDiaperSection(reportData: reportData)
            
            // 里程碑区域
            if !reportData.recentMilestones.isEmpty {
                ReportMilestoneSection(milestones: reportData.recentMilestones)
            }
            
            // 底部水印
            ReportFooter()
        }
    }
}

// MARK: - ReportHeaderSection

struct ReportHeaderSection: View {
    let child: Child
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 20) {
            // 顶部装饰
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundStyle(child.color.swatch)
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(child.color.swatch)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            
            // 宝宝信息
            VStack(spacing: 12) {
                // 宝宝头像
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [child.color.swatch, child.color.swatch.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Text(child.initial)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .shadow(color: child.color.swatch.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 6) {
                    Text(child.name)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        Image(systemName: child.gender == .female ? "heart.circle.fill" : "star.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(child.color.swatch)
                        
                        Text(child.ageDisplay)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // 报告日期
            VStack(spacing: 8) {
                Text("成长报告")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(reportData.dateRange)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(child.color.swatch.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 24)
        .background(Color.white)
    }
}

// MARK: - ReportStatsSection

struct ReportStatsSection: View {
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 16) {
            Text("本期数据总览")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    icon: "fork.knife",
                    title: "喂养次数",
                    value: "\(reportData.totalFeedings)",
                    subtitle: "次",
                    color: .nuraFeeding
                )
                
                StatCard(
                    icon: "moon.stars.fill",
                    title: "睡眠时长",
                    value: String(format: "%.1f", reportData.totalSleepHours),
                    subtitle: "小时",
                    color: .nuraSleep
                )
                
                StatCard(
                    icon: "circle.hexagonpath.fill",
                    title: "换尿布",
                    value: "\(reportData.totalDiapers)",
                    subtitle: "次",
                    color: .nuraDiaper
                )
                
                StatCard(
                    icon: "heart.fill",
                    title: "记录天数",
                    value: "\(reportData.recordDays)",
                    subtitle: "天",
                    color: .nuraPrimary
                )
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - StatCard

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - ReportGrowthSection

struct ReportGrowthSection: View {
    let growth: GrowthRecord
    let child: Child
    
    var body: some View {
        VStack(spacing: 16) {
            Text("最新体征")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                if let weight = growth.weightKg {
                    GrowthDataRow(
                        icon: "scalemass.fill",
                        label: "体重",
                        value: String(format: "%.2f", weight),
                        unit: "kg",
                        color: child.color.swatch
                    )
                }
                
                if let height = growth.heightCm {
                    GrowthDataRow(
                        icon: "ruler.fill",
                        label: "身高",
                        value: String(format: "%.1f", height),
                        unit: "cm",
                        color: child.color.swatch
                    )
                }
                
                if let head = growth.headCircCm {
                    GrowthDataRow(
                        icon: "circle.fill",
                        label: "头围",
                        value: String(format: "%.1f", head),
                        unit: "cm",
                        color: child.color.swatch
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - GrowthDataRow

struct GrowthDataRow: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(color)
            }
            
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(unit)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - ReportFeedingSection

struct ReportFeedingSection: View {
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16))
                        .foregroundStyle(.nuraFeeding)
                    
                    Text("喂养分析")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    label: "平均每日喂养",
                    value: String(format: "%.1f", reportData.averageDailyFeedings),
                    unit: "次",
                    icon: "chart.bar.fill"
                )
                
                if reportData.breastfeedingCount > 0 {
                    AnalysisRow(
                        label: "母乳喂养",
                        value: "\(reportData.breastfeedingCount)",
                        unit: "次",
                        icon: "heart.fill"
                    )
                }
                
                if reportData.formulaCount > 0 {
                    AnalysisRow(
                        label: "配方奶喂养",
                        value: "\(reportData.formulaCount)",
                        unit: "次",
                        icon: "circle.fill"
                    )
                }
                
                if reportData.solidFoodCount > 0 {
                    AnalysisRow(
                        label: "辅食喂养",
                        value: "\(reportData.solidFoodCount)",
                        unit: "次",
                        icon: "leaf.fill"
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color.white)
    }
}

// MARK: - ReportSleepSection

struct ReportSleepSection: View {
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.nuraSleep)
                    
                    Text("睡眠分析")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    label: "平均每日睡眠",
                    value: String(format: "%.1f", reportData.averageDailySleepHours),
                    unit: "小时",
                    icon: "moon.fill"
                )
                
                AnalysisRow(
                    label: "总睡眠次数",
                    value: "\(reportData.totalSleepSessions)",
                    unit: "次",
                    icon: "zzz"
                )
                
                if reportData.longestSleepHours > 0 {
                    AnalysisRow(
                        label: "最长睡眠",
                        value: String(format: "%.1f", reportData.longestSleepHours),
                        unit: "小时",
                        icon: "star.fill"
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - ReportDiaperSection

struct ReportDiaperSection: View {
    let reportData: GrowthReportData
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "circle.hexagonpath.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.nuraDiaper)
                    
                    Text("尿布统计")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 12) {
                AnalysisRow(
                    label: "平均每日更换",
                    value: String(format: "%.1f", reportData.averageDailyDiapers),
                    unit: "次",
                    icon: "chart.bar.fill"
                )
                
                if reportData.wetDiaperCount > 0 {
                    AnalysisRow(
                        label: "尿湿",
                        value: "\(reportData.wetDiaperCount)",
                        unit: "次",
                        icon: "drop.fill"
                    )
                }
                
                if reportData.dirtyDiaperCount > 0 {
                    AnalysisRow(
                        label: "便便",
                        value: "\(reportData.dirtyDiaperCount)",
                        unit: "次",
                        icon: "circle.fill"
                    )
                }
                
                if reportData.mixedDiaperCount > 0 {
                    AnalysisRow(
                        label: "混合",
                        value: "\(reportData.mixedDiaperCount)",
                        unit: "次",
                        icon: "circle.grid.2x2.fill"
                    )
                }
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color.white)
    }
}

// MARK: - AnalysisRow

struct AnalysisRow: View {
    let label: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 20)
            
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(unit)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - ReportMilestoneSection

struct ReportMilestoneSection: View {
    let milestones: [Milestone]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.nuraWarning)
                    
                    Text("成长里程碑")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack(spacing: 10) {
                ForEach(Array(milestones.prefix(5))) { milestone in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.nuraWarning.opacity(0.15))
                                .frame(width: 32, height: 32)
                            
                            Text(milestone.emoji)
                                .font(.system(size: 14))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(.primary)
                            
                            Text(milestone.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 24)
        .background(Color(UIColor.systemGray6))
    }
}

// MARK: - ReportFooter

struct ReportFooter: View {
    var body: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 24)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.nuraPrimary)
                    
                    Text("NURA")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .tracking(2)
                        .foregroundStyle(.nuraPrimary)
                }
                
                Text("记录宝宝成长的每一刻")
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
                
                Text(Date().formatted(date: .long, time: .omitted))
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 20)
        }
        .background(Color.white)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Child.self, configurations: config)
    
    let child = Child(
        name: "小明",
        birthDate: Calendar.current.date(byAdding: .day, value: -90, to: Date())!,
        gender: .male,
        color: .blue
    )
    
    let reportData = GrowthReportData(
        dateRange: "2026年4月26日 - 2026年5月26日",
        recordDays: 30,
        totalFeedings: 180,
        totalSleepHours: 420,
        totalDiapers: 210,
        averageDailyFeedings: 6.0,
        averageDailySleepHours: 14.0,
        averageDailyDiapers: 7.0,
        breastfeedingCount: 120,
        formulaCount: 60,
        solidFoodCount: 0,
        totalSleepSessions: 90,
        longestSleepHours: 8.5,
        wetDiaperCount: 150,
        dirtyDiaperCount: 50,
        mixedDiaperCount: 10,
        latestGrowth: nil,
        recentMilestones: []
    )
    
    return GrowthReportView(child: child, reportData: reportData)
        .modelContainer(container)
}
