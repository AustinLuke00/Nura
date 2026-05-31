// NuraApp.swift
// NuraApp.swift
// Nura — App entry point with SwiftData container

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

@main
struct NuraApp: App {
    @State private var showLaunchScreen = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showLaunchScreen ? 0 : 1)
                
                if showLaunchScreen {
                    AnimatedLaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                // 启动屏幕显示 2 秒后淡出
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.6)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
        .modelContainer(for: [
            Child.self,
            FeedingRecord.self,
            SleepRecord.self,
            DiaperRecord.self,
            GrowthRecord.self,
            Milestone.self,
            JaundiceRecord.self,
            MedicineRecord.self,
            VaccineRecord.self,
            TemperatureRecord.self,
            BreathingRecord.self,
            ConceptionRecord.self,
            FetalMovementRecord.self,
            BloodPressureRecord.self,
            BloodSugarRecord.self,
            PregnancyWeightRecord.self
        ])
    }
}

struct ContentView: View {
    @Query private var children: [Child]
    @State private var selectedChildId: UUID?
    @State private var selectedTab: Tab = .today
    @State private var showWelcomeSheet = false
    @State private var showDeveloperSettings = false
    @State private var developerTapCount = 0

    enum Tab { case today, review }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedChildId: $selectedChildId)
                .tabItem {
                    Label("今日", systemImage: selectedTab == .today ? "sun.max.fill" : "sun.max")
                }
                .tag(Tab.today)

            ReviewView(selectedChildId: $selectedChildId)
                .tabItem {
                    Label("回顾", systemImage: selectedTab == .review
                          ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                }
                .tag(Tab.review)
        }
        .tint(.nuraPrimary)
        .onTapGesture(count: 5) {
            // 连续点击5次任意位置打开开发者设置
            showDeveloperSettings = true
        }
        .sheet(isPresented: $showDeveloperSettings) {
            DeveloperSettingsView()
        }
        .task {
            // Ensure selectedChildId is valid on appear
            validateSelectedChild()
        }
        .onChange(of: children) { oldValue, newValue in
            validateSelectedChild()
        }
        .onAppear {
            // 每次打开应用都检查是否有宝宝
            if children.isEmpty {
                // 延迟一小段时间以确保视图已完全加载
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showWelcomeSheet = true
                }
            } else {
                validateSelectedChild()
            }
        }
        .sheet(isPresented: $showWelcomeSheet) {
            WelcomeSheet()
                .interactiveDismissDisabled(children.isEmpty)
        }
    }
    
    // MARK: - Helper Methods
    
    private func validateSelectedChild() {
        if children.isEmpty {
            showWelcomeSheet = true
            selectedChildId = nil
        } else if selectedChildId == nil || !children.contains(where: { $0.id == selectedChildId }) {
            // 如果当前选中的宝宝不存在，选择第一个
            selectedChildId = children.first?.id
        }
    }
}

// MARK: - WelcomeSheet

struct WelcomeSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var children: [Child]
    
    @State private var currentStep: WelcomeStep = .welcome
    @State private var name = ""
    @State private var birthDate = Date()
    @State private var gender: Child.Gender = .female
    @State private var color: Child.ChildColor = .purple
    @State private var profileType: Child.ProfileType = .tryingToConceive
    @State private var emergencyContactName = ""
    @State private var emergencyContactPhone = ""
    @State private var showImporter = false
    @State private var importResultTitle = ""
    @State private var importResultMessage = ""
    @State private var showImportResult = false

    private var latestSelectableDate: Date {
        Calendar.current.date(byAdding: .month, value: 10, to: Date()) ?? Date()
    }

    private var saveDisabled: Bool {
        profileType == .baby && name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    enum WelcomeStep {
        case welcome
        case addChild
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if currentStep == .welcome {
                    welcomeView
                } else {
                    addChildFormView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if currentStep == .addChild {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("返回") {
                            withAnimation {
                                currentStep = .welcome
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
                importData(from: result)
            }
            .alert(importResultTitle, isPresented: $showImportResult) {
                Button("好") { }
            } message: {
                Text(importResultMessage)
            }
        }
    }
    
    // MARK: - Welcome View
    
    var welcomeView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo 区域
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nuraPrimary, Color.nuraPrimary.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .shadow(color: Color.nuraPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(spacing: 8) {
                    Text("NURA")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.nuraPrimary)
                    
                    Text("记录宝宝成长的每一刻")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // 功能介绍
            VStack(spacing: 20) {
                WelcomeFeatureRow(
                    icon: "sun.max.fill",
                    title: "日常记录",
                    description: "喂养、睡眠、换尿布一键记录",
                    color: .nuraWarning
                )
                
                WelcomeFeatureRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "成长追踪",
                    description: "生长曲线、里程碑智能分析",
                    color: .nuraPrimary
                )
                
                WelcomeFeatureRow(
                    icon: "heart.fill",
                    title: "温馨陪伴",
                    description: "见证宝宝每一个珍贵瞬间",
                    color: Color(hex: "F9A8D4")
                )
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // 首次使用选项
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentStep = .addChild
                    }
                } label: {
                    Label("自行填写", systemImage: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.nuraPrimary)
                        .cornerRadius(16)
                }

                Button {
                    showImporter = true
                } label: {
                    Label("导入数据", systemImage: "square.and.arrow.down")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.nuraPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.nuraPrimary.opacity(0.12))
                        .cornerRadius(16)
                }
                
                if !children.isEmpty {
                    Button {
                        dismiss()
                    } label: {
                        Text("稍后添加")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Add Child Form View
    
    var addChildFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.nuraPrimary)
                    
                    Text(profileType == .tryingToConceive ? "添加备孕信息" : (profileType == .pregnancy ? "添加孕妇信息" : "添加宝宝信息"))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    
                    Text(profileType == .tryingToConceive ? "先记录末次月经和同房信息，确认后可一键转入孕期" : (profileType == .pregnancy ? "填写末次月经，系统会自动推算预产期" : "让我们开始记录宝宝的成长故事"))
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                // 表单
                VStack(spacing: 16) {
                    Picker("信息类型", selection: $profileType) {
                        Label("备孕信息", systemImage: "calendar.badge.heart").tag(Child.ProfileType.tryingToConceive)
                        Label("宝宝信息", systemImage: "figure.child").tag(Child.ProfileType.baby)
                        Label("孕妇信息", systemImage: "heart.circle.fill").tag(Child.ProfileType.pregnancy)
                    }
                    .pickerStyle(.segmented)
                    .padding(4)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(12)

                    if profileType == .baby {
                        // 名字输入
                        VStack(alignment: .leading, spacing: 8) {
                            Label("宝宝名字", systemImage: "person.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            TextField("请输入宝宝的名字", text: $name)
                                .font(.system(size: 16, design: .rounded))
                                .padding()
                                .background(Color(UIColor.secondarySystemGroupedBackground))
                                .cornerRadius(12)
                        }
                    }

                    // 出生日期 / 末次月经
                    VStack(alignment: .leading, spacing: 8) {
                        Label(profileType == .baby ? "出生日期" : "末次月经", systemImage: "calendar")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        HStack {
                            DatePicker(
                                "",
                                selection: $birthDate,
                                in: Date.distantPast...Date(),
                                displayedComponents: .date
                            )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                            Spacer()
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                        .cornerRadius(12)

                        Text(profileType == .tryingToConceive ? "备孕档案会根据末次月经显示周期图、排卵窗口，并重点登记同房信息。" : (profileType == .pregnancy ? "预计预产期：\(estimatedDueDate(from: birthDate).nuraDateShortDisplay)。孕期档案默认女性，不需要选择性别。" : "宝宝档案会根据年龄自动切换婴儿或儿童界面。"))
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(.secondary)
                    }

                    if profileType == .pregnancy {
                        EmergencyContactFields(
                            name: $emergencyContactName,
                            phone: $emergencyContactPhone
                        )
                    } else if profileType == .baby {
                        // 性别选择
                        VStack(alignment: .leading, spacing: 8) {
                            Label("性别", systemImage: "person.2.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 12) {
                                GenderButton(
                                    title: "女宝宝",
                                    icon: "heart.circle.fill",
                                    isSelected: gender == .female
                                ) {
                                    withAnimation { gender = .female }
                                }

                                GenderButton(
                                    title: "男宝宝",
                                    icon: "star.circle.fill",
                                    isSelected: gender == .male
                                ) {
                                    withAnimation { gender = .male }
                                }
                            }
                        }

                        // 主题颜色
                        VStack(alignment: .leading, spacing: 8) {
                            Label("主题颜色", systemImage: "paintpalette.fill")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.secondary)

                            HStack(spacing: 16) {
                                ForEach(Child.ChildColor.allCases, id: \.self) { c in
                                    ColorButton(color: c, isSelected: color == c) {
                                        withAnimation(.spring(response: 0.3)) {
                                            color = c
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                // 保存按钮
                Button {
                    saveChild()
                } label: {
                    Text("保存并开始")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            saveDisabled
                                ? Color.gray
                                : Color.nuraPrimary
                        )
                        .cornerRadius(16)
                }
                .disabled(saveDisabled)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer(minLength: 40)
            }
        }
        .onChange(of: profileType) { _, newValue in
            if newValue == .baby && birthDate > Date() {
                birthDate = Date()
            }
        }
    }
    
    // MARK: - Actions

    func importData(from result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            let summary = try DataManager.importData(data, into: modelContext)

            if summary.insertedChildren > 0 || summary.mergedChildren > 0 {
                dismiss()
            } else {
                importResultTitle = "导入完成"
                importResultMessage = summary.message
                showImportResult = true
            }
        } catch {
            importResultTitle = "导入失败"
            importResultMessage = error.localizedDescription
            showImportResult = true
        }
    }
    
    func saveChild() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard profileType != .baby || !trimmed.isEmpty else { return }

        let child = Child(
            name: profileType == .tryingToConceive ? "备孕档案" : (profileType == .pregnancy ? "孕期档案" : trimmed),
            birthDate: profileType == .pregnancy ? estimatedDueDate(from: birthDate) : birthDate,
            gender: profileType == .baby ? gender : .female,
            color: profileType == .tryingToConceive ? .amber : (profileType == .pregnancy ? .pink : color),
            profileType: profileType,
            emergencyContactName: emergencyContactName.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            emergencyContactPhone: emergencyContactPhone.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            lastMenstrualPeriodDate: profileType == .baby ? nil : birthDate
        )
        modelContext.insert(child)
        
        // 添加成功后延迟关闭
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dismiss()
        }
    }

    private func estimatedDueDate(from lastMenstrualPeriod: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 280, to: lastMenstrualPeriod) ?? lastMenstrualPeriod
    }
}

// MARK: - WelcomeFeatureRow

struct WelcomeFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - GenderButton

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? .nuraPrimary : .secondary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .nuraPrimary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? Color.nuraPrimary.opacity(0.1)
                    : Color(UIColor.secondarySystemGroupedBackground)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.nuraPrimary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - ColorButton

struct ColorButton: View {
    let color: Child.ChildColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.swatch)
                    .frame(width: 44, height: 44)
                
                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 3)
                        .frame(width: 44, height: 44)
                    
                    Circle()
                        .strokeBorder(color.swatch, lineWidth: 2)
                        .frame(width: 52, height: 52)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("Welcome - No Children") {
    WelcomeSheet()
        .modelContainer(for: [Child.self], inMemory: true)
}

#Preview("ContentView") {
    ContentView()
        .modelContainer(for: [
            Child.self, FeedingRecord.self, SleepRecord.self,
            DiaperRecord.self, GrowthRecord.self, Milestone.self,
            JaundiceRecord.self
        ], inMemory: true)
}
